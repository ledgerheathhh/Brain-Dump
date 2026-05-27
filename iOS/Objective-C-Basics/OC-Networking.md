# NSURLSession

`NSURLSession`在 `iOS7`中推出，`NSURLSession`的推出旨在替换之前的 `NSURLConnection`，`NSURLSession`的使用相对于之前的 `NSURLConnection`更简单，而且不用处理 `Runloop`相关的东西。

在苹果官方提供的解决方案中，最早出现的是NSURLConnection。作为Core Foundation/CFNetwork 框架的APIs之上的一个抽象，NSURLConnection伴随着2003年Safari浏览器的原始发行版本，诞生于十几年前。NSURLConnection这个名字，实际上指的是一组构成Foundation框架中URL加载系统的相互关联的组件：NSURLRequest，NSURLResponse，NSURLProtocol，NSURLCache，NSHTTPCookieStorage，NSURLCredentialStorage，以及和它同名的NSURLConnection。

在2013年的WWDC上，苹果官方提供了NSURLConnection的继任者--NSURLSession。与NSURLConnection相比，NSURLSession最直接的改善就是提供了配置每个会话的缓存，协议，Cookie和证书政策（Credential Policies），甚至跨应用程序共享它们的能力。这使得框架的网络基础架构和部分应用程序独立工作，而不会互相干扰。每一个NSURLSession对象都是根据一个NSURLSessionConfiguration初始化的，该NSURLSessionConfiguration指定了上面提到的政策，以及一系列为了提高移动设备性能而专门添加的新选项。NSURLSession的另一重要组成部分是会话任务NSURLSessionTask，它负责处理数据的加载，以及客户端与服务器之间的文件和数据的上传下载服务。

`NSURLSession`由三部分构成：

* **`NSURLSession`**

  * 负责请求/响应的关键对象，可以用系统提供的单例对象，也可以自己使用 `NSURLSessionConfiguration` 配置对象进行创建
  * 在请求/响应的执行过程中调用 `NSURLSessionTaskDelegate` 所定义的各种代理方法。
* **`NSURLSessionConfiguration`**

  * 用于对 `NSURLSession` 对象进行初始化，一般都采用 `default`，可以配置  **可用网络** 、 **Cookie** 、 **安全性** 、 **缓存策略** 、 **自定义协议** 、**启动事件** 等选项，以及用于移动设备优化的相关选项。
  * 几乎可以配置任何选项。
* **`NSURLSessionTask`**

  * 负责执行具体请求的 `task`，由 `session`创建
  * 一个抽象类，其子类可以创建不同类型的任务（Task），如：下载、上传、获取数据（如：JSON 或 XML）
  * 在特定 URL Session 中执行

---

我们可以将 `NSURLSession` 中的类分为以下 6 种：

* URL 加载 （URL Loading）
* 配置管理 （Configuration Management）
* 缓存管理 （Cache Policy）
* Cookie 存储 （Cookie Storage）
* 认证和证书 （Authentication and Credentials）
* 协议支持 （Protocol Support）

在一个请求被发送到服务器之前，系统会先查询共享的缓存信息，然后根据 **缓存策略（Cache Policy）** 以及 **可用性（availability）** 的不同，一个已经被缓存的响应可能会被立即返回。如果没有缓存的响应可用，则这个请求将根据我们指定的策略来缓存它的响应，以便将来的请求可以使用。

在一个请求被发送到服务器过程中，服务器可能会发出  **鉴权查询（Authorization Challenge）** ，这可以由共享的 Cookie 或 **证书存储（Credential Storage）** 来自动响应，或者由被委托对象来响应。此外，发送中的请求也可以被注册的 `NSURLProtocol` 对象所拦截，以便在必要时改变其加载行为。

## NSURLSessionTask

`NSURLSessionTask` 是一个抽象类，其包含如下 3 个实体子类。这 3 个子类封装了 3 个最基本的网络任务： **获取数据** （如：JSON 或 XML）、 **上传文件** 、 **下载文件** 。

* `NSURLSessionDataTask`
* `NSURLSessionUploadTask`
* `NSURLSessionDownloadTask`

对于 `NSURLSessionDataTask`，服务器会有响应数据；而对于上传请求，服务器也会有响应数据， `NSURLSessionUploadTask` 继承自 `NSURLSessionDataTask`。`NSURLSessionDownloadTask` 完成时，会带回已下载文件的一个临时的文件路径。

---

关于 `NSURLSessionTask` 的数据返回方式，主要有两种方式：

* **`completionHandler` 回调**
* **`NSURLSessionDelegate` 代理**

通过 `completionHandler` 回调将会创建一个隐式的代理（delegate），从而替代该 Task 原来的代理 —— Session。

对于需要 override 原有 Session Task 的代理的默认行为的情况，我们需要使用不带 `completionHandler` 版本。

需要注意的是，`NSURLSessionTask` 及其子类都有着各自的代理协议，它们之间也存在着继承关系。

* `NSURLSessionDelegate`：定义了网络请求最基础的代理方法。作为所有代理的基类。
* `NSURLSessionTaskDelegate`：定义了网络请求任务相关的代理方法。
* `NSURLSessionDownloadDelegate`：定义了下载任务相关的代理方法，如：下载进度等
* `NSURLSessionDataDelegate`：定义了普通数据任务和上传任务相关的代理方法。

---

### NSURLSessionDataTask

`NSURLSessionDataTask` 主要用于  **读取服务端的简单数据** ，如：JSON、XML 数据。

 **创建方法** （基于 `NSURLSession` 对象）

```objectivec
// 使用 NSURLRequest 对象创建
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request;

// 使用 NSURL 对象创建
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url;
```

**CompletionHandler**

```objectivec
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;  

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
```

### NSURLSessionUploadTask

`NSURLSessionUploadTask` 主要用于  **向服务器发送文件类型的数据** 。

 **创建方法** （基于 `NSURLSession` 对象）

```objectivec
// 使用 NSURLRequest 对象创建，上传时指定文件源
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL;  

// 使用 NSURLRequest 对象创建，上传时指定数据源   
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData;  

- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request;
```

**CompletionHandler**

```objectivec
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;  

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
```

### NSURLSessionDownloadTask

`NSURLSessionDownloadTask` 主要用于  **文件下载** ，它针对大文件的网络请求做了更多的处理，如：下载进度、断点续传等。

 **创建方法** （基于 `NSURLSession` 对象）

```objectivec
// 使用 NSURLRequest 对象创建
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request;  

// 使用 NSURL 对象创建
- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url;  

// 使用之前已经下载的数据来创建
- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData;
```

**CompletionHandler**

```objectivec
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;  

- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;  

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;
```

## NSURLSession

`NSURLSession` 是负责请求/响应的关键对象，使用 `NSURLSessionConfiguration` 配置对象进行创建。

`NSURLSession` 本身并不会进行请求，而是通过创建 Task 的形式来进行网络请求。同一个 `NSURLSession` 可以创建多个 Task，并且这些 Task 之间的 Cache 和 Cookie 是共享的。

`NSURLSession` 在管理请求/响应的过程中会调用相关的代理方法。这些代理方法主要分两类：

* **Session 的委托对象实现的代理方法（`NSURLSessionDelegate` 定义的方法）**
  * 主要用于处理连接层问题，如：服务器信任、客户端证书认证、NTLM 和 Kerberos 协议等问题
* **Task 的委托对象实现的代理方法（`NSURLSessionTaskDelegate` 及其子协议定义的方法）**
  * 主要用于处理以网络请求为基础的问题，如：Basic，Digest，**代理身份验证（Proxy Authentication）** 等。

`NSURLSession`有三种方式创建：

```objectivec
sharedSession
```

系统维护的一个单例对象，可以和其他使用这个 `session`的 `task`共享连接和请求信息。

```objectivec
sessionWithConfiguration:
```

在NSURLSession初始化时传入一个NSURLSessionConfiguration，这样可以自定义请求头、cookie等信息。

```objectivec
sessionWithConfiguration:delegate:delegateQueue:
```

如果想更好的控制请求过程以及回调线程，需要上面的方法进行初始化操作，并传入 `delegate`来设置回调对象和回调的线程。

## NSURLSessionConfiguration

`NSURLSessionConfiguration` 对象用于对 `NSURLSession` 进行初始化。

`NSURLSessionConfiguration` 对以前 `NSMutableURLRequest` 所提供的网络请求层的设置选项进行了扩充，提供给开发者相当大的灵活性和控制权。从指定可用网络，到 cookie，安全性，缓存策略，再到使用自定义协议，启动事件的设置，以及用于移动设备优化的几个新属性，可以发现使用 `NSURLSessionConfiguration` 可以找到几乎任何想要进行配置的选项。

`NSURLSession` 在初始化时会把配置它的 `NSURLSessionConfiguration` 对象进行一次深拷贝，并保存到自己的 `configuration` 属性中，而且这个属性是只读的。也就是说，`configuration` 只在初始化时被读取一次，之后都是不会变化的。

# AFNetworking

> AFNetworking是目前使用人数最多的网络加载第三方开源框架，从最初的NSURLConnection到现在的NSURLSession，它都一直保持着与苹果的步调一致，而由它也衍生出大量的相关第三方网络功能框架。在绝大多数情况下，当我们需要发送网络请求，或者是下载文件，使用AFNetworking都是最便捷的选择。

AFNetworking是一个完全开源的第三方框架，因此我们可以清晰的获取其中每个类的实现方式。根据AFNetworking框架中的内容，主要分为如下四个功能模块：

* 网络通信模块(URLSession)
* 网络状态监听模块(Reachability)
* 网络通信安全策略模块(Security)
* 网络通信信息序列化/反序列化模块(Serialization)

AFNetworking的其核心是网络通信模块，其余的模块均是为了配合网络通信模块工作。

AFNetworking的核心类是AFURLSessionManager类，AFHTTPSessionManager继承自AFURLSessionManager，而AFURLRequestSerialization和AFURLResponseSerialization， AFSecurityPolicy, AFNetworkReachabilityManager则被AFURLSessionManager所使用。

AFNetworking 主要包含了 6 个类：

* **`AFURLSessionManager`** ：AFNetworking 的核心类。
* **`AFHTTPSessionManager`** ：`AFURLSessionManager` 的子类，主要用于 HTTP 请求。
* **`AFURLRequestSerialization`** ：请求序列化器，用于将参数编码为查询字符串、HTTP 正文，并根据需要设置合适的 HTTP 头部字段。
* **`AFURLResponseSerialization`** ：响应序列化器，用于将数据解码为对象，还可以对传入的响应和数据进行验证。
* **`AFSecurityPolicy`** ：通过安全连接评估服务器对固定的 X.509 证书和公钥的信任。
* **`AFNetworkReachabilityManager`** ：监视网络可达性。

## AFNetworking常用方法

AFNetworking对复杂的网络请求进行了封装，大大降低了有关网络开发的难度，一般来说，只要掌握如下两个核心方法即可。

* 发送POST请求并对返回结果进行处理。我们可以在**success**这个block中获取服务器返回的数据responseObject，并对服务器返回的数据进行后续处理，需要注意的是该block是异步调用的，即当成功获取网络请求后才被调用。

```objectivec
- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable id)parameters
                       success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                       failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;
```

* 发送GET请求并对返回结果进行处理。服务器返回的数据同样封装在success这个block中的responseObject参数中。

```objectivec
- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(nullable id)parameters
                      success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                      failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;
```

# YTKNetwork

YTKNetwork 是猿题库技术团队开源的一个网络请求框架，内部封装了 AFNetworking。YTKNetwork 实现了一套高层级的 API，提供更高层次的网络访问抽象。

## YTKNetwork 提供了哪些功能

相比 AFNetworking，YTKNetwork 提供了以下更高级的功能：

* 支持按时间缓存网络请求内容
* 支持按版本号缓存网络请求内容
* 支持统一设置服务器和 CDN 的地址
* 支持检查返回 JSON 内容的合法性
* 支持文件的断点续传
* 支持 `block` 和 `delegate` 两种模式的回调方式
* 支持批量的网络请求发送，并统一设置它们的回调（实现在 `YTKBatchRequest` 类中）
* 支持方便地设置有相互依赖的网络请求的发送，例如：发送请求 A，根据请求 A 的结果，选择性的发送请求 B 和 C，再根据 B 和 C 的结果，选择性的发送请求 D。（实现在 `YTKChainRequest` 类中）
* 支持网络请求 URL 的 filter，可以统一为网络请求加上一些参数，或者修改一些路径。
* 定义了一套插件机制，可以很方便地为 YTKNetwork 增加功能。猿题库官方现在提供了一个插件，可以在某些网络请求发起时，在界面上显示“正在加载”的 HUD。

## 哪些项目适合使用 YTKNetwork

YTKNetwork 适合稍微复杂一些的项目，不适合个人的小项目。

如果你的项目中需要缓存网络请求、管理多个网络请求之间的依赖、希望检查服务器返回的 JSON 是否合法，那么 YTKNetwork 能给你带来很大的帮助。如果你缓存的网络请求内容需要依赖特定版本号过期，那么 YTKNetwork 就能发挥出它最大的优势。

## YTKNetwork 的基本思想

YTKNetwork 的基本的思想是把每一个网络请求封装成对象。所以使用 YTKNetwork，你的每一个请求都需要继承 `YTKRequest` 类，通过覆盖父类的一些方法来构造指定的网络请求。

把每一个网络请求封装成对象其实是使用了设计模式中的 Command 模式，它有以下好处：

* 将网络请求与具体的第三方库依赖隔离，方便以后更换底层的网络库。
* 方便在基类中处理公共逻辑，例如猿题库的数据版本号信息就统一在基类中处理。
* 方便在基类中处理缓存逻辑，以及其它一些公共逻辑。
* 方便做对象的持久化。

如果你的工程非常简单，这么写会显得没有直接用 AFNetworking 将请求逻辑写在 Controller 中方便，所以 YTKNetwork 并不适合特别简单的项目。

## 安装

你可以在 Podfile 中加入下面一行代码来使用 YTKNetwork

`pod 'YTKNetwork'`

## YTKNetwork 基本组成

YTKNetwork 包括以下几个基本的类：

* YTKNetworkConfig 类：用于统一设置网络请求的服务器和 CDN 的地址。
* YTKRequest 类：所有的网络请求类需要继承于 `YTKRequest` 类，每一个 `YTKRequest` 类的子类代表一种专门的网络请求。

### YTKNetworkConfig 类

YTKNetworkConfig 类有两个作用：

1. 统一设置网络请求的服务器和 CDN 的地址
2. 管理网络请求的 YTKUrlFilterProtocol 实例

我们为什么需要统一设置服务器地址呢？因为：

1. 按照设计模式里的 `Do Not Repeat Yourself` 原则，我们应该把服务器地址统一写在一个地方。
2. 在实际业务中，测试人员需要切换不同的服务器地址来测试。统一设置服务器地址到 YTKNetworkConfig 类中，也便于我们统一切换服务器地址。

具体的用法是，在程序刚启动的回调中，设置好 YTKNetworkConfig 的信息，如下所示：

```objc
- (BOOL)application:(UIApplication *)application 
   didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   YTKNetworkConfig *config = [YTKNetworkConfig sharedConfig];
   config.baseUrl = @"http://yuantiku.com";
   config.cdnUrl = @"http://fen.bi";
}
```

设置好之后，所有的网络请求都会默认使用 YTKNetworkConfig 中 `baseUrl` 参数指定的地址。

大部分企业应用都需要对一些静态资源（例如图片、js、css）使用 CDN。YTKNetworkConfig 的 `cdnUrl` 参数用于统一设置这一部分网络请求的地址。

当我们需要切换服务器地址时，只需要修改 YTKNetworkConfig 中的 `baseUrl` 和 `cdnUrl` 参数即可。

### YTKRequest 类

YTKNetwork 的基本的思想是把每一个网络请求封装成对象。所以使用 YTKNetwork，你的每一种请求都需要继承 YTKRequest 类，通过覆盖父类的一些方法来构造指定的网络请求。把每一个网络请求封装成对象其实是使用了设计模式中的 Command 模式。

每一种网络请求继承 YTKRequest 类后，需要用方法覆盖（overwrite）的方式，来指定网络请求的具体信息。如下是一个示例：

假如我们要向网址 `http://www.yuantiku.com/iphone/register` 发送一个 `POST` 请求，请求参数是 username 和 password。那么，这个类应该如下所示：

```objc
// RegisterApi.h
#import "YTKRequest.h"

@interface RegisterApi : YTKRequest

- (id)initWithUsername:(NSString *)username password:(NSString *)password;

@end


// RegisterApi.m

#import "RegisterApi.h"

@implementation RegisterApi {
    NSString *_username;
    NSString *_password;
}

- (id)initWithUsername:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self) {
        _username = username;
        _password = password;
    }
    return self;
}

- (NSString *)requestUrl {
    // “ http://www.yuantiku.com ” 在 YTKNetworkConfig 中设置，这里只填除去域名剩余的网址信息
    return @"/iphone/register";
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodPOST;
}

- (id)requestArgument {
    return @{
        @"username": _username,
        @"password": _password
    };
}

@end
```

在上面这个示例中，我们可以看到：

* 我们通过覆盖 YTKRequest 类的 `requestUrl` 方法，实现了指定网址信息。并且我们只需要指定除去域名剩余的网址信息，因为域名信息在 YTKNetworkConfig 中已经设置过了。
* 我们通过覆盖 YTKRequest 类的 `requestMethod` 方法，实现了指定 POST 方法来传递参数。
* 我们通过覆盖 YTKRequest 类的 `requestArgument` 方法，提供了 POST 的信息。这里面的参数 `username` 和 `password` 如果有一些特殊字符（如中文或空格），也会被自动编码。

## 调用 RegisterApi

在构造完成 RegisterApi 之后，具体如何使用呢？我们可以在登录的 ViewController 中，调用 RegisterApi，并用 block 的方式来取得网络请求结果：

```objc
- (void)loginButtonPressed:(id)sender {
    NSString *username = self.UserNameTextField.text;
    NSString *password = self.PasswordTextField.text;
    if (username.length > 0 && password.length > 0) {
        RegisterApi *api = [[RegisterApi alloc] initWithUsername:username password:password];
        [api startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
            // 你可以直接在这里使用 self
            NSLog(@"succeed");
        } failure:^(YTKBaseRequest *request) {
            // 你可以直接在这里使用 self
            NSLog(@"failed");
        }];
    }
}
```

注意：你可以直接在 block 回调中使用 `self`，不用担心循环引用。因为 YTKRequest 会在执行完 block 回调之后，将相应的 block 设置成 nil。从而打破循环引用。

除了 block 的回调方式外，YTKRequest 也支持 delegate 方式的回调：

```objc
- (void)loginButtonPressed:(id)sender {
    NSString *username = self.UserNameTextField.text;
    NSString *password = self.PasswordTextField.text;
    if (username.length > 0 && password.length > 0) {
        RegisterApi *api = [[RegisterApi alloc] initWithUsername:username password:password];
        api.delegate = self;
        [api start];
    }
}

- (void)requestFinished:(YTKBaseRequest *)request {
    NSLog(@"succeed");
}

- (void)requestFailed:(YTKBaseRequest *)request {
    NSLog(@"failed");
}
```

## 验证服务器返回内容

有些时候，由于服务器的 Bug，会造成服务器返回一些不合法的数据，如果盲目地信任这些数据，可能会造成客户端 Crash。如果加入大量的验证代码，又使得编程体力活增加，费时费力。

使用 YTKRequest 的验证服务器返回值功能，可以很大程度上节省验证代码的编写时间。

例如，我们要向网址 `http://www.yuantiku.com/iphone/users` 发送一个 `GET` 请求，请求参数是 `userId` 。我们想获得某一个用户的信息，包括他的昵称和等级，我们需要服务器必须返回昵称（字符串类型）和等级信息（数值类型），则可以覆盖 `jsonValidator` 方法，实现简单的验证。

```objc
- (id)jsonValidator {
    return @{
        @"nick": [NSString class],
        @"level": [NSNumber class]
    };
}
```

完整的代码如下：

```objc
// GetUserInfoApi.h
#import "YTKRequest.h"

@interface GetUserInfoApi : YTKRequest

- (id)initWithUserId:(NSString *)userId;

@end


// GetUserInfoApi.m
#import "GetUserInfoApi.h"

@implementation GetUserInfoApi {
    NSString *_userId;
}

- (id)initWithUserId:(NSString *)userId {
    self = [super init];
    if (self) {
        _userId = userId;
    }
    return self;
}

- (NSString *)requestUrl {
    return @"/iphone/users";
}

- (id)requestArgument {
    return @{ @"id": _userId };
}

- (id)jsonValidator {
    return @{
        @"nick": [NSString class],
        @"level": [NSNumber class]
    };
}

@end
```

以下是更多的 jsonValidator 的示例：

* 要求返回 String 数组：

```objc
- (id)jsonValidator {
    return @[ [NSString class] ];
}
```

* 来自猿题库线上环境的一个复杂的例子：

```objc
- (id)jsonValidator {
    return @[@{
        @"id": [NSNumber class],
        @"imageId": [NSString class],
        @"time": [NSNumber class],
        @"status": [NSNumber class],
        @"question": @{
            @"id": [NSNumber class],
            @"content": [NSString class],
            @"contentType": [NSNumber class]
        }
    }];
} 
```

## 使用 CDN 地址

[](https://github.com/kanyun-inc/YTKNetwork/blob/master/Docs/BasicGuide_cn.md#%E4%BD%BF%E7%94%A8-cdn-%E5%9C%B0%E5%9D%80)

如果要使用 CDN 地址，只需要覆盖 YTKRequest 类的 `- (BOOL)useCDN;` 方法。

例如我们有一个取图片的接口，地址是 `http://fen.bi/image/imageId` ，则我们可以这么写代码 :

```objc
// GetImageApi.h
#import "YTKRequest.h"

@interface GetImageApi : YTKRequest
- (id)initWithImageId:(NSString *)imageId;
@end

// GetImageApi.m
#import "GetImageApi.h"

@implementation GetImageApi {
    NSString *_imageId;
}

- (id)initWithImageId:(NSString *)imageId {
    self = [super init];
    if (self) {
        _imageId = imageId;
    }
    return self;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"/iphone/images/%@", _imageId];
}

- (BOOL)useCDN {
    return YES;
}
@end
```

## 断点续传

[](https://github.com/kanyun-inc/YTKNetwork/blob/master/Docs/BasicGuide_cn.md#%E6%96%AD%E7%82%B9%E7%BB%AD%E4%BC%A0)

要启动断点续传功能，只需要覆盖 `resumableDownloadPath` 方法，指定断点续传时文件的存储路径即可，文件会被自动保存到此路径。如下代码将刚刚的取图片的接口改造成了支持断点续传：

```objc
@implementation GetImageApi {
    NSString *_imageId;
}

- (id)initWithImageId:(NSString *)imageId {
    self = [super init];
    if (self) {
        _imageId = imageId;
    }
    return self;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"/iphone/images/%@", _imageId];
}

- (BOOL)useCDN {
    return YES;
}

- (NSString *)resumableDownloadPath {
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *cachePath = [libPath stringByAppendingPathComponent:@"Caches"];
    NSString *filePath = [cachePath stringByAppendingPathComponent:_imageId];
    return filePath;
}

@end
```

## 按时间缓存内容

[](https://github.com/kanyun-inc/YTKNetwork/blob/master/Docs/BasicGuide_cn.md#%E6%8C%89%E6%97%B6%E9%97%B4%E7%BC%93%E5%AD%98%E5%86%85%E5%AE%B9)

刚刚我们写了一个 GetUserInfoApi ，这个网络请求是获得用户的一些资料。

我们想像这样一个场景，假设你在完成一个类似微博的客户端，GetUserInfoApi 用于获得你的某一个好友的资料，因为好友并不会那么频繁地更改昵称，那么短时间内频繁地调用这个接口很可能每次都返回同样的内容，所以我们可以给这个接口加一个缓存。

在如下示例中，我们通过覆盖 `cacheTimeInSeconds` 方法，给 GetUserInfoApi 增加了一个 3 分钟的缓存，3 分钟内调用调 Api 的 start 方法，实际上并不会发送真正的请求。

```objc
@implementation GetUserInfoApi {
    NSString *_userId;
}

- (id)initWithUserId:(NSString *)userId {
    self = [super init];
    if (self) {
        _userId = userId;
    }
    return self;
}

- (NSString *)requestUrl {
    return @"/iphone/users";
}

- (id)requestArgument {
    return @{ @"id": _userId };
}

- (id)jsonValidator {
    return @{
        @"nick": [NSString class],
        @"level": [NSNumber class]
    };
}

- (NSInteger)cacheTimeInSeconds {
    // 3 分钟 = 180 秒
    return 60 * 3;
}

@end
```

该缓存逻辑对上层是透明的，所以上层可以不用考虑缓存逻辑，每次调用 GetUserInfoApi 的 start 方法即可。GetUserInfoApi 只有在缓存过期时，才会真正地发送网络请求。
