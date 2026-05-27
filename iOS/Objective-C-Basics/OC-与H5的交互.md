## WKWebView

现代 iOS 项目应优先使用 `WKWebView`。`UIWebView` 已废弃，Apple 建议在 iOS 8 及以上使用 `WKWebView`，因此 `UIWebView` 相关内容只适合作为历史方案了解。

##### **WKWebView 原生交互原理**

通过 `WKUserContentController` 把需要观察的 JS 消息名称注册起来。

```objectivec
WKUserContentController *userContentController = [[WKUserContentController alloc] init];
[userContentController addScriptMessageHandler:self name:@"jsFunc"];

WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
configuration.userContentController = userContentController;

WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
```

在 JS 中调用这个函数并传递参数数据：

```javascript
window.webkit.messageHandlers.jsFunc.postMessage({name: "李四", age: 22});
```

OC 中遵守 `WKScriptMessageHandler` 协议：

```objectivec
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"jsFunc"]) {
        NSDictionary *body = message.body;
        NSLog(@"%@", body);
    }
}
```

> `WKScriptMessage` 的 `name` 可以用来判断是哪个 JS message handler 被调用，`body` 是 JS 传给原生的参数。实际项目中要注意移除 message handler，避免 `WKUserContentController` 强引用 handler 带来的内存泄漏。

#### Native 调用 JS

```objectivec
[webView evaluateJavaScript:@"window.renderFromNative && window.renderFromNative({name: 'ledger'})"
          completionHandler:^(id result, NSError *error) {
    if (error) {
        NSLog(@"evaluate JavaScript failed: %@", error);
    }
}];
```

## UIWebView（历史方案）

#### H5调用原生

##### 1、通过拦截加载的URL。

在UIWebView中就存在UIWebViewDelegate，拦截URL就是通过代理中的一个方法实现的。

```objectivec
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
```

这个方法当WebView在加载url之前会执行

在 HTML 页面中，定义一个 JavaScript 函数，通过更改 `window.location` 来触发 URL 拦截，从而向 Objective-C 发送消息。

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UIWebView 与 H5 交互</title>
    <script>
        function sendMessageToOC() {
            // 通过更改 window.location 来触发 URL 拦截
            window.location.href = "jsbridge://buttonClicked";
        }
    </script>
</head>
<body>
    <h1>Hello, Objective-C!</h1>
    <button onclick="sendMessageToOC()">点击我</button>
</body>
</html>

```

在 Objective-C 代码中，拦截 `UIWebView` 的 URL 请求并处理自定义的 URL scheme。

```objectivec
#import "ViewController.h"

@interface ViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    // 初始化并添加 UIWebView
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
  
    // 加载网页
    NSURL *url = [NSURL URLWithString:@"https://yourwebsite.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if ([url.scheme isEqualToString:@"jsbridge"]) {
        if ([url.host isEqualToString:@"buttonClicked"]) {
            // 处理按钮点击事件
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Message from H5"
                                                                           message:@"按钮被点击了！"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        // 阻止 WebView 加载此 URL
        return NO;
    }
    return YES;
}

@end

```

## **WebViewJavaScriptBridge**

最开始的UIWebView时，原生跟JS之间的交互一般是两种方式：

* **Native -> JS** :这种方式很简单，只是是原生调用 `stringByEvaluatingJavaScriptFromString：`方法，传入要执行的JS代码就可以实现；
* **JS -> Native** ：这种方式是在网页上面加载一串Custom URL Scheme的URL，然后通过原生去 `UIWebView`的代理方法 `webView:shouldStartLoadWithRequest:navigationType:`中拦截相应的URL做处理。

**组成：**

* **WebViewJavaScriptBridgeBase** ：bridge的核心类，用来初始化以及消息的处理；
* **WebViewJavaScriptBridge** ：判断WebView的类型，并通过不同的类型进行分发。针对UIWebView和WebView做的一层封装，主要从来执行JS代码，以及实现UIWebView和WebView的代理方法，并通过拦截URL来通知WebViewJavaScriptBridgeBase做的相应操作；
* **WKWebViewJavaScriptBridge** ：主要是针对WKWebView做的一些封装，主要也是执行JS代码和实现WKWebView的代理方法的。同上面这个类类似；
* **WebViewJavaScriptBridge_JS**：里面主要写了一些JS的方法，JS端与Native交互的JS端的方法基本上都在这个里面；

WebViewJavaScriptBridge的设计很巧妙，他在JS端和Native端，都各自初始化了一个WebViewJavaScriptBridge对象，就像是两边各自安排了一个”通讯兵“，让这两个对象去完成消息的收发工作。同时两边还各自维护一个管理相应事件的messageHandlers容器、一个管理回调的callbackId容器。所以这里的初始化，我们得分为两个部分的初始化，一个部分是Native端的初始化，一个是JS端的初始化.

 首先初始化 `WebViewJavaScriptBridge`并且设置好代理

```objectivec
#import "ViewController.h"
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>

@interface ViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    // 初始化并添加 UIWebView
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
  
    // 初始化 WebViewJavascriptBridge
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView];
    [self.bridge setWebViewDelegate:self];
  
    // 注册一个从 H5 接收消息的方法
    [self.bridge registerHandler:@"sendMessageToOC" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"接收到 H5 消息: %@", data);
        responseCallback(@"收到消息");
    }];
    //sendMessageToOC是 OC block 的一个别名。
    //block 本身，是 JS 通过某种方式调用到 sendMessageToOC 的时候，执行的代码块。
    //data ，由于 OC 这端由 JS 调用，所以 data 是 JS 端传递过来的数据。
    //responseCallback OC 端的 block 执行完毕之后，往 JS 端传递的数据。
  
    // 加载网页
    NSURL *url = [NSURL URLWithString:@"https://yourwebsite.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

@end

```

在 HTML 页面中，使用 `WebViewJavascriptBridge` 发送消息到 Objective-C。

当我们通过 `loadRequest`加载URL之后，网页一加载就会执行网页JS中的bridge的初始化方法 `setupWebViewJavascriptBridge`函数

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UIWebView 与 H5 交互</title>
    <script src="https://raw.githubusercontent.com/marcuswestin/WebViewJavascriptBridge/master/WebViewJavascriptBridge.js"></script>
    <script>
        // 初始化 WebViewJavascriptBridge
        function setupWebViewJavascriptBridge(callback) {
            if (window.WebViewJavascriptBridge) { return callback(WebViewJavascriptBridge); }
            if (window.WVJBCallbacks) { return window.WVJBCallbacks.push(callback); }
            window.WVJBCallbacks = [callback];
            var WVJBIframe = document.createElement('iframe');
            WVJBIframe.style.display = 'none';
            WVJBIframe.src = 'wvjbscheme://__BRIDGE_LOADED__';
            document.documentElement.appendChild(WVJBIframe);
            setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0);
        }

        setupWebViewJavascriptBridge(function(bridge) {
            // 注册一个从 Objective-C 接收消息的方法
            bridge.registerHandler('showMessage', function(data, responseCallback) {
                alert('收到来自 OC 的消息: ' + data.message);
                responseCallback('收到消息');
            });

            // 发送消息到 Objective-C
            document.getElementById('sendMessageButton').onclick = function() {
                bridge.callHandler('sendMessageToOC', {'message': 'Hello from H5!'}, function responseCallback(responseData) {
                    alert('收到来自 OC 的响应: ' + responseData);
                });
            };
        });
    </script>
</head>
<body>
    <h1>Hello, Objective-C!</h1>
    <button id="sendMessageButton">点击我发送消息</button>
</body>
</html>

```

* showMessage是注入到桥梁中 JS 函数的别名。以供 OC 端调用。
* 回调函数的 data  既然 JS 函数由 OC 调用，所以 data 是 OC 端传递过来的数据。
* responseCallback  JS 调用在被 OC 调用完毕之后，向 OC 端传递的数据。
