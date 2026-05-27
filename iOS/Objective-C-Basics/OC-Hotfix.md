# 热修复

> 说明：本文记录的是 JSPatch 这类 Objective-C 动态化热修复的历史方案和语法要点。它依赖下发并执行脚本来改变 App 行为，在线上 App Store 应用中存在审核和安全风险。现代项目应优先通过正常发版、服务端开关、配置化降级、灰度发布等方式处理线上问题；如需动态化能力，必须先确认公司合规策略和 Apple 审核规则。

### 本地js热修复

```objectivec
    [JPEngine startEngine];
  
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"hot_fix" ofType:@"js"];
    NSString *script = [NSString stringWithContentsOfFile:sourcePath encoding:NSUTF8StringEncoding error:nil];
  
    [JPEngine evaluateScript:script];
```

### 在使用Objective-C类之前需要调用 `require('className’)` :

```js
require('UIView')
var view = UIView.alloc().init()
```

### 可以用逗号 `,` 分隔，一次性导入多个类:

```js
require('UIView, UIColor')
var view = UIView.alloc().init()
var red = UIColor.redColor()
```

### 或者直接在使用时才调用 `require()` :

```js
require('UIView').alloc().init()
```

### 覆盖方法：

```javascript
defineClass("JPTableViewController", {
  //实例方法
}, {
  //类方法
})
```

### block 传递

当要把 JS 函数作为 block 参数给 OC时，需要先使用 `block(paramTypes, function)` 接口包装:

```objc
// Obj-C
@implementation JPObject
+ (void)request:(void(^)(NSString *content, BOOL success))callback
{
  callback(@"I'm content", YES);
}
@end
```

```js
// JS
require('JPObject').request(block("NSString *, BOOL", function(ctn, succ) {
  if (succ) log(ctn)  //output: I'm content
}))
```

### stringWithFormat

JSPatch 支持调用 stringWithFormat，不过所有参数类型都需改为 `%@`:

```objc
//OC
[NSString stringWithFormat:@"name:%@, age:%d", @"alex", 12];
```

```js
//JS
NSString.stringWithFormat("name:%@, age:%@", "alex", 12);
```

### 字符串 / 数组 / 字典 操作问题

刚使用 JSPatch 经常会对 NSString / NSArray / NSDictionary / NSDate 这四个类的使用感到迷惑，因为 JS 语言本身有对应的这四个类型，会跟 OC 的这四个类混淆。要避免混淆，要弄清楚两点：

1.需要认清这四个类有 JS 跟 OC **两种类型**

```objc
//OC
@implementation JPTestObject
+ (NSString *)name {
  return @"I'm NSString";
}
+ (NSMutableDictionary *)info {
  return @{@"k": @"v"};
}
+ (NSArray *)users {
  return @[@"alex", @"bang", @"cat"];
}
@end
```

```js
var ocStr = JPTestObject.name();
var ocInfo = JPTestObject.info();
var ocUsers = JPTestObject.users();

//以上三个是从 OC 返回的 OC 对象，可以调用 OC 方法：
ocStr.rangeOfString("I'm");   //OK
ocInfo.addObject_forKey("a", "b");   //OK
ocUsers.firstObject();    //OK
ocInfo["a"];  //错误，不能使用[]语法操作OC对象
ocUsers[0];  //错误，不能使用[]语法操作OC对象

///////////////////////////////////////

var str = "I'm JS String";
var info = @{"k": "v"};
var users = ["alex", "bang", "cat"];

//以上三个是 JS 对象，不能调用 OC 方法：
str.rangeOfString("I'm");   //错误
info.addObject_forKey("a", "b");   //错误
users.firstObject();    //错误

info["k"]; //正确，可以用[]语法操作JS对象
user[0]; //正确，可以用[]语法操作JS数组
```

2.若要**用JS语法操作**这些类型，要确保它是 JS 对象。

```js
//错误：ocStr 不是 JS 对象，不能用 JS 语法拼接字符串
var newStr = ocStr + "js string";   

//正确：已用 .toJS() 接口转为 JS 对象，可以用 JS语法操作
var transStr = ocStr.toJS();
var newStr = transStr + "js string";  


//错误：ocUsers 不是 JS 对象，不能用[]语法，也不能用 JS 语法遍历
var firstUser = ocUser[0];
for (var i = 0; i < ocUsers.length; i ++) {
  var user = ocUsers[i];
}

//正确：已用 .toJS() 接口转为 JS 对象，可以用 JS语法操作
var transArr = ocUsers.toJS();
var firstUser = transArr[0];
for (var i = 0; i < transArr.length; i ++) {
  var user = transArr[i];
}


//错误: ocInfo 不是 JS 对象，不能用[]语法
var v = ocInfo['k'];

//正确：已用 .toJS() 接口转为 JS 对象，可以用 JS语法操作
var transDict = ocInfo.toJS();
var v = transDict['k'];
```

### JS断点调试

#### 启动调试工具

首先需要开启 Safari 调试菜单：Safari -> 偏好设置 -> 高级 -> 勾选[在菜单栏中显示“开发”菜单]

接着启动APP -> Safari -> 开发 -> 选择你的机器 -> JSContext

即可开始调试。

连接真机调试时，需要打开真机的web检查器：设置 -> Safari -> 高级 -> Web检查器

#### 资源列表

资源列表列出了 JSPatch 所有执行中的脚本文件，点开文件后可以对其进行断点调试。

通过 `[JPEngine evaluateScript:script]` 接口执行的脚本，在资源列表里都表示为 `main.js`。

通过 `[JPEngine evaluateScriptWithPath:filePath]` 接口执行的脚本，在资源列表里会以原文件名表示。
