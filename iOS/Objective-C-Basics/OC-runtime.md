# Objective-C Runtime

Objective-C 是一门动态语言，很多行为不是在编译期完全确定，而是在运行时通过 Runtime 完成。Runtime 是一组 C API 和数据结构，负责对象模型、类结构、消息发送、方法查找、动态绑定、关联对象等能力。

## 对象、类与元类

Objective-C 对象本质上是一个结构体，最核心的是 `isa` 指针。`isa` 指向对象所属的类，类对象中保存实例方法列表、属性列表、协议列表、成员变量布局等信息。

```objc
struct objc_object {
    Class isa;
};
```

常见关系：

* 实例对象的 `isa` 指向类对象。
* 类对象的 `isa` 指向元类对象。
* 元类对象保存类方法。
* 类对象的 `superclass` 指向父类，元类对象的 `superclass` 指向父类的元类。
* 根元类的 `isa` 通常指向自己。

因此，实例方法从类对象的方法列表中查找，类方法从元类对象的方法列表中查找。

## 消息发送

Objective-C 的方法调用本质是消息发送：

```objc
[person sayHello];
```

编译后可以理解为：

```objc
objc_msgSend(person, @selector(sayHello));
```

消息发送的大致流程：

1. 判断 receiver 是否为 `nil`。给 `nil` 发送消息不会崩溃，通常直接返回 0 或 nil。
2. 根据 receiver 的 `isa` 找到类对象。
3. 先查方法缓存 cache。
4. 缓存未命中时查当前类的方法列表。
5. 当前类未找到时，沿 `superclass` 向父类查找。
6. 仍未找到时，进入动态方法解析、消息转发流程。

方法缓存可以避免每次都线性查找方法列表，这是 Objective-C 动态派发性能可接受的重要原因。

## SEL、IMP 和 Method

Runtime 中几个常见概念：

* `SEL`：方法名的唯一标识，可以理解为 selector。
* `IMP`：方法实现的函数指针。
* `Method`：方法结构，包含 `SEL`、`IMP`、类型编码等信息。

```objc
SEL selector = @selector(viewDidLoad);
Method method = class_getInstanceMethod([UIViewController class], selector);
IMP imp = method_getImplementation(method);
```

同一个方法名在不同类中对应同一个 `SEL`，但可以对应不同的 `IMP`。

## 动态方法解析

如果对象收到一个找不到的方法，Runtime 会先给类一次“补方法”的机会：

```objc
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(dynamicMethod)) {
        class_addMethod(self, sel, (IMP)dynamicMethodIMP, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
```

如果是类方法，则对应：

```objc
+ (BOOL)resolveClassMethod:(SEL)sel;
```

这一步适合在运行时按需添加方法实现。

## 消息转发

如果动态方法解析没有处理，Runtime 会进入消息转发。

### 快速转发

```objc
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(doWork)) {
        return self.worker;
    }
    return [super forwardingTargetForSelector:aSelector];
}
```

快速转发用于把消息交给另一个对象处理。

### 完整转发

如果快速转发也没有处理，会走完整转发：

```objc
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSMethodSignature signatureWithObjCTypes:"v@:"];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.worker];
}
```

完整转发可以拿到 `NSInvocation`，适合做代理、多播、埋点、远程调用等更复杂的场景。

## Method Swizzling

Method Swizzling 是在运行时交换两个方法的实现：

```objc
Method originalMethod = class_getInstanceMethod(self, @selector(viewWillAppear:));
Method swizzledMethod = class_getInstanceMethod(self, @selector(xxx_viewWillAppear:));
method_exchangeImplementations(originalMethod, swizzledMethod);
```

常见用途：

* 统一埋点
* 调试或兼容系统行为
* 修复局部逻辑

使用注意：

* 应在 `+load` 或明确的一次性初始化路径中执行，并用 `dispatch_once` 保证只交换一次。
* 交换前要确认方法存在，必要时先 `class_addMethod`。
* 避免对系统私有 API 或不稳定行为做 swizzling。
* swizzling 会影响全局行为，应该保持范围小、可测试、可回滚。

## 关联对象

Category 不能直接添加实例变量，但可以通过关联对象为已有类“挂载”额外数据：

```objc
static const void *kNameKey = &kNameKey;

- (void)setExtraName:(NSString *)extraName {
    objc_setAssociatedObject(self, kNameKey, extraName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)extraName {
    return objc_getAssociatedObject(self, kNameKey);
}
```

常见关联策略：

* `OBJC_ASSOCIATION_ASSIGN`
* `OBJC_ASSOCIATION_RETAIN_NONATOMIC`
* `OBJC_ASSOCIATION_COPY_NONATOMIC`
* `OBJC_ASSOCIATION_RETAIN`
* `OBJC_ASSOCIATION_COPY`

关联对象常用于 Category 扩展状态，但不要滥用。需要大量状态时，优先考虑子类、组合对象或显式数据结构。

## Category 与 Extension

Category：

* 可以给已有类添加方法。
* 不能直接添加实例变量。
* 可以通过关联对象间接保存数据。
* 同名方法会覆盖原有实现，多个 Category 的同名方法加载顺序不可依赖。

Extension：

* 通常写在 `.m` 文件中。
* 可以声明私有属性、私有方法。
* 编译期参与类定义，更适合隐藏类的内部细节。

## KVC 与 KVO

KVC（Key-Value Coding）允许通过字符串 key 访问属性：

```objc
[person setValue:@"ledger" forKey:@"name"];
NSString *name = [person valueForKey:@"name"];
```

KVC 查找大致会按 accessor、实例变量等规则逐步尝试。key 写错或类型不匹配时可能触发异常。

KVO（Key-Value Observing）用于观察对象属性变化。传统 KVO 的核心实现依赖 Runtime 动态创建子类，重写 setter，在 setter 中插入通知逻辑，并把被观察对象的 `isa` 指向这个动态子类。

使用 KVO 要注意：

* 观察者和被观察者生命周期必须匹配。
* 传统手动 KVO 需要成对添加和移除。
* 现代代码可以优先考虑 block token、Combine、Reactive 框架或 Swift 的观察机制来降低崩溃风险。

## 常用 Runtime API

```objc
Class cls = object_getClass(obj);
Class superCls = class_getSuperclass(cls);

BOOL isMeta = class_isMetaClass(cls);

Ivar ivar = class_getInstanceVariable(cls, "_name");
Method method = class_getInstanceMethod(cls, @selector(description));
objc_property_t property = class_getProperty(cls, "name");

class_addMethod(cls, @selector(foo), (IMP)fooIMP, "v@:");
method_exchangeImplementations(method1, method2);
```

Runtime API 很强，但也会绕开编译期检查。日常业务开发应优先使用清晰的语言特性和框架能力；Runtime 更适合框架、基础设施、调试工具和少量确有必要的动态能力。
