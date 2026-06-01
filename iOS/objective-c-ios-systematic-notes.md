# Objective-C / iOS 底层系统化学习笔记

来源：`01-OC语法.pptx` 到 `08-总结.pptx`，共 8 份课件、209 页。处理方式：抽取 PPTX 可编辑文本，解析备注与图片关系，并对 143 张嵌入图片做本机 OCR，其中 142 张识别到文字。本文按知识体系重组，不逐页照抄。

结论：课件主线基本正确，适合作为 Objective-C 底层、Runtime、RunLoop、多线程、内存管理、性能优化的面试型学习资料。需要注意的是，部分表述是教学简化，另有一些内容在 2026 年视角下偏旧或过于绝对，已在「错误、过时点与修正」中标出。

## 目录

1. 学习路径
2. Objective-C 对象模型
3. KVO 与 KVC
4. Category、Class Extension 与关联对象
5. Block
6. Runtime
7. RunLoop
8. 多线程与同步
9. 内存管理
10. 性能优化
11. 架构与设计模式
12. 高频面试速答
13. 错误、过时点与修正
14. PPT 建议补充内容
15. 来源覆盖与参考资料

## 1. 学习路径

推荐按下面顺序学习，而不是按 PPT 文件名死记：

| 阶段 | 目标 | 需要能讲清楚的问题 |
|---|---|---|
| OC 对象模型 | 理解对象、类、元类和内存布局 | `isa` 指向哪里，方法和成员变量存在哪里，`superclass` 怎么找方法 |
| Runtime 基础 | 理解动态派发和运行时数据结构 | `objc_msgSend` 三阶段，方法缓存，动态解析，消息转发 |
| KVC/KVO/Category | 理解常见动态特性 | KVO 如何动态子类化，KVC 查找顺序，Category 为何不能直接加 ivar |
| Block | 理解闭包对象化、捕获和循环引用 | block 类型、copy、`__block`、对象捕获、weak-strong dance |
| RunLoop | 理解主线程事件循环 | mode、source、timer、observer、休眠唤醒、timer 滚动失效 |
| 多线程 | 理解队列、线程同步和锁 | sync/async、串行/并发、死锁、信号量、读写锁、barrier |
| 内存管理 | 理解 ARC 背后的引用计数 | Tagged Pointer、SideTable、weak、autorelease pool、copy |
| 性能优化 | 能定位 CPU/GPU/启动/包体问题 | 卡顿来源、离屏渲染、耗电、启动优化、LinkMap |
| 架构 | 能做项目级权衡 | MVC/MVP/MVVM、分层、模块边界、设计模式 |

## 2. Objective-C 对象模型

### 2.1 Objective-C 的本质

Objective-C 的对象模型建立在 C/C++ 数据结构之上。日常写的消息调用、属性访问、类方法等，最终会落到 Runtime 数据结构和 C 函数调用。

常用观察手段：

```bash
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o main.cpp
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m
```

LLDB 常用指令：

```lldb
p obj
po obj
x/3xw 0x10010
memory read/4gx 0x10010
memory write 0x10010 10
```

### 2.2 三类对象

Objective-C 中常说的对象可分为三类：

| 类型 | 来源 | 主要保存内容 |
|---|---|---|
| instance 对象 | `alloc/init` 创建 | `isa` 指针，成员变量的具体值 |
| class 对象 | 每个类一个 | `isa`，`superclass`，对象方法，属性，协议，成员变量描述 |
| meta-class 对象 | 每个类一个 | `isa`，`superclass`，类方法 |

重点：

- 成员变量的值存储在 instance 对象中。
- 对象方法、属性、成员变量描述和协议信息存储在 class 对象中。
- 类方法存储在 meta-class 对象中。
- class 和 meta-class 的底层结构都属于 `struct objc_class`。

### 2.3 `isa` 和 `superclass`

调用对象方法：

```text
instance -> isa -> class -> method list/cache
                         -> superclass -> parent class
```

调用类方法：

```text
class -> isa -> meta-class -> class method list/cache
                         -> superclass -> parent meta-class
```

关键规则：

- instance 的 `isa` 指向 class。
- class 的 `isa` 指向 meta-class。
- class 的 `superclass` 指向父类 class。
- meta-class 的 `superclass` 指向父类 meta-class。
- 根类的 meta-class 的 `superclass` 指向根类的 class。
- 根 meta-class 的 `isa` 指向自己。课件中「meta-class 的 isa 指向基类的 meta-class」作为简化记忆可以接受，但面试时要补上根 meta-class 自指这一点。

arm64 以后，`isa` 通常不是直接裸指针，而是 non-pointer isa，需要通过 mask 取出真实 Class 地址。相关位域常见含义：

| 字段 | 含义 |
|---|---|
| `nonpointer` | 是否为优化后的 isa |
| `has_assoc` | 是否设置过关联对象 |
| `has_cxx_dtor` | 是否存在 C++ 析构或 `.cxx_destruct` |
| `shiftcls` | Class 或 Meta-Class 地址信息 |
| `weakly_referenced` | 是否曾被弱引用 |
| `deallocating` | 是否正在释放 |
| `extra_rc` | 内联引用计数，通常存储引用计数减 1 |
| `has_sidetable_rc` | 引用计数是否溢出到 SideTable |

### 2.4 对象占用内存

区分两个概念：

```objc
class_getInstanceSize([NSObject class]);       // 对象内部实际需要的成员变量大小
malloc_size((__bridge const void *)obj);       // malloc 实际分配的块大小
```

在 64 位环境中，一个 `NSObject` 实例内部只需要一个 `isa` 指针，通常为 8 字节；实际分配常见为 16 字节，这是内存分配器的对齐和最小分配粒度导致的。

## 3. KVO 与 KVC

### 3.1 KVO 本质

KVO 是 Key-Value Observing，用于观察对象属性变化。典型实现思路：

1. Runtime 动态创建一个派生子类，例如 `NSKVONotifying_Person`。
2. 将被观察对象的 `isa` 指向这个动态子类。
3. 动态子类重写 setter。
4. setter 内部触发 `willChangeValueForKey:`，调用原 setter，再触发 `didChangeValueForKey:`。
5. `didChangeValueForKey:` 内部通知 observer 的 `observeValueForKeyPath:ofObject:change:context:`。

注意：

- 直接修改成员变量通常不会触发 KVO。
- 通过符合 KVC/KVO 的 setter 或 `setValue:forKey:` 修改属性，通常会触发自动 KVO。
- 手动触发需要成对调用 `willChangeValueForKey:` 和 `didChangeValueForKey:`。
- KVO 内部类名和私有函数只是理解工具，不应在业务代码依赖。

### 3.2 KVC 赋值流程

`setValue:forKey:` 的典型查找顺序：

1. 查找 `setKey:`。
2. 查找 `_setKey:`。
3. 若找到 setter，调用 setter。
4. 若未找到，检查 `+accessInstanceVariablesDirectly`。
5. 若返回 `YES`，按 `_key`、`_isKey`、`key`、`isKey` 顺序查找 ivar。
6. 若仍未找到，调用 `setValue:forUndefinedKey:` 并抛出 `NSUnknownKeyException`。

### 3.3 KVC 取值流程

`valueForKey:` 的典型查找顺序：

1. 查找 `getKey`。
2. 查找 `key`。
3. 查找 `isKey`。
4. 查找 `_key`。
5. 若未找到，检查 `+accessInstanceVariablesDirectly`。
6. 若返回 `YES`，按 `_key`、`_isKey`、`key`、`isKey` 顺序查找 ivar。
7. 若仍未找到，调用 `valueForUndefinedKey:` 并抛出异常。

面试表达：KVC 是一套按命名约定查找 accessor 和 ivar 的动态访问机制，不是简单的字典取值。

## 4. Category、Class Extension 与关联对象

### 4.1 Category 底层结构

Category 编译后的核心结构是 `category_t`，包含：

- 分类名。
- 宿主类名。
- 对象方法列表。
- 类方法列表。
- 协议列表。
- 属性列表。

加载过程：

1. Runtime 读取类和 Category 数据。
2. 找到某个类的所有 Category。
3. 合并 Category 的方法、属性、协议。
4. 将合并后的列表插入到类原有列表前面。
5. 后编译的 Category 数据通常排在更前面，因此同名方法可能覆盖原方法查找结果。

### 4.2 Category 与 Class Extension

| 对比项 | Category | Class Extension |
|---|---|---|
| 合并时机 | 运行时合并 | 编译期纳入类信息 |
| 能否直接加 ivar | 不能给已存在类直接增加实例变量 | 可在类自身实现上下文中声明私有成员 |
| 常见用途 | 拆分方法、给系统类补方法、协议适配 | 私有属性、私有方法、类内部实现细节 |

### 4.3 `+load` 与 `+initialize`

`+load`：

- Runtime 加载类和分类时调用。
- 每个类、分类通常调用一次。
- 类先于分类，父类先于子类。
- 直接按函数地址调用，不走 `objc_msgSend`。
- 适合极少量、必须在加载时完成的工作，不适合重逻辑。

`+initialize`：

- 类第一次收到消息前调用。
- 父类先于子类。
- 通过 `objc_msgSend` 调用。
- 如果子类未实现，可能调用继承自父类的实现，因此父类实现可能被触发多次。
- 不建议放复杂初始化或可能互相等待的锁逻辑。

### 4.4 关联对象

Category 不能直接添加 ivar，但可以用关联对象模拟属性存储：

```objc
static void *NameKey = &NameKey;

objc_setAssociatedObject(obj, NameKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
id value = objc_getAssociatedObject(obj, NameKey);
objc_setAssociatedObject(obj, NameKey, nil, OBJC_ASSOCIATION_ASSIGN); // 移除该 key
```

常见 key 写法：

- `static void *Key = &Key;`
- `static char Key;` 后使用 `&Key`
- `@selector(propertyName)`，常用于属性 getter

关联策略：

| Policy | 类似属性修饰 |
|---|---|
| `OBJC_ASSOCIATION_ASSIGN` | `assign` |
| `OBJC_ASSOCIATION_RETAIN_NONATOMIC` | `strong, nonatomic` |
| `OBJC_ASSOCIATION_COPY_NONATOMIC` | `copy, nonatomic` |
| `OBJC_ASSOCIATION_RETAIN` | `strong, atomic` |
| `OBJC_ASSOCIATION_COPY` | `copy, atomic` |

关联对象不存储在被关联对象的实例内存里，而是由 Runtime 的全局关联表管理。设置为 `nil` 等价于移除该 key 的关联值。

## 5. Block

### 5.1 Block 本质

Block 是 Objective-C 对象，内部有 `isa`，本质是对「函数调用」和「调用环境」的封装。

三类 block：

| 类型 | 常见场景 | copy 结果 |
|---|---|---|
| `__NSGlobalBlock__` | 不捕获 auto 变量 | 仍在全局区 |
| `__NSStackBlock__` | 捕获 auto 变量，尚未 copy | copy 到堆 |
| `__NSMallocBlock__` | 栈 block copy 后 | 引用计数增加 |

### 5.2 变量捕获

| 变量类型 | 是否捕获 | 访问方式 |
|---|---|---|
| 局部 auto 变量 | 捕获 | 值传递 |
| 局部 static 变量 | 捕获指针或直接访问静态存储 | 可修改原值 |
| 全局变量 | 不捕获 | 直接访问 |

普通 auto 变量在 block 内默认只读，因为捕获的是值。要修改外部局部变量，需要 `__block`。

### 5.3 `__block`

`__block` 会把变量包装成 byref 结构体，典型结构包含：

```c
struct __Block_byref_age_0 {
    void *__isa;
    __Block_byref_age_0 *__forwarding;
    int __flags;
    int __size;
    int age;
};
```

`__forwarding` 用于在栈上 byref 变量被复制到堆后，让栈结构和堆结构都能访问到同一份有效数据。

### 5.4 Block 的 copy 和对象捕获

在 ARC 下，编译器会在一些场景自动把栈 block copy 到堆，例如：

- block 作为函数返回值。
- block 赋给强引用变量或属性。
- block 作为 GCD API 参数。
- block 作为 Cocoa 中名称包含 `usingBlock` 的 API 参数。

建议 block 属性仍写 `copy`，即使 ARC 下 `strong` 多数情况下也能工作，`copy` 的语义更准确，也兼容 MRC 习惯。

对象类型 auto 变量：

- block 在栈上时，不会强引用捕获对象。
- block copy 到堆时，会调用内部 copy helper。
- copy helper 调用 `_Block_object_assign`，根据 `__strong`、`__weak`、`__unsafe_unretained` 等修饰决定引用行为。
- block 释放时，会调用 dispose helper 和 `_Block_object_dispose`。

### 5.5 循环引用

典型循环：

```objc
self.block = ^{
    [self doSomething];
};
```

ARC 推荐写法：

```objc
__weak typeof(self) weakSelf = self;
self.block = ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    [self doSomething];
};
```

注意：

- `__unsafe_unretained` 不安全，对象释放后会产生野指针。
- 用 `__block` 破循环要求 block 被执行并主动置空引用，否则仍可能泄漏。
- `NSMutableArray` 在 block 内调用 `addObject:` 不需要 `__block`，因为没有修改变量本身，只是给对象发消息；如果要给变量重新赋值才需要。

## 6. Runtime

### 6.1 Runtime 是什么

Objective-C 的动态性由 Runtime 支撑。Runtime 是一组 C API 和底层数据结构，支撑类、对象、消息发送、方法解析、消息转发、关联对象、动态创建类、方法交换等能力。

项目常见用途：

- 给 Category 添加关联属性。
- 遍历成员变量或属性，例如字典转模型、归档解档。
- 方法交换，例如埋点、容错、调试。
- 动态添加方法。
- 消息转发兜底。

### 6.2 `method_t`

`method_t` 是方法描述，核心字段：

| 字段 | 含义 |
|---|---|
| `SEL name` | 方法选择器，类似方法名 |
| `const char *types` | 返回值和参数的 type encoding |
| `IMP imp` | 函数实现地址 |

不同类中同名方法对应的 selector 相同，但 IMP 可以不同。

### 6.3 方法缓存

Class 内部有 `cache_t`，用于缓存曾经调用过的方法。方法缓存本质是散列表，用空间换时间，减少反复遍历方法列表的成本。

### 6.4 `objc_msgSend` 三阶段

阶段一：消息发送

1. receiver 为 `nil`，直接返回。
2. 通过 `isa` 找到 receiverClass。
3. 查找当前类 cache。
4. 查找当前类方法列表。
5. 沿 `superclass` 查找父类 cache 和方法列表。
6. 找到 IMP 后调用并缓存。
7. 找不到进入动态方法解析。

阶段二：动态方法解析

```objc
+ (BOOL)resolveInstanceMethod:(SEL)sel;
+ (BOOL)resolveClassMethod:(SEL)sel;
```

开发者可在这里用 `class_addMethod` 添加实现。动态解析后会重新走消息发送流程。

阶段三：消息转发

1. `forwardingTargetForSelector:`，快速转发给另一个对象。
2. `methodSignatureForSelector:`，生成方法签名。
3. `forwardInvocation:`，完整转发并自定义逻辑。
4. 仍无法处理则 `doesNotRecognizeSelector:`。

### 6.5 `super` 的本质

`super` 不是另一个对象。`[super method]` 的 receiver 仍是当前对象，只是从父类开始查找方法实现。底层会转成类似 `objc_msgSendSuper2` 的调用，携带 receiver 和 current class 信息。

### 6.6 常用 Runtime API

类相关：

```objc
Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);
void objc_registerClassPair(Class cls);
void objc_disposeClassPair(Class cls);
Class object_getClass(id obj);
Class object_setClass(id obj, Class cls);
BOOL object_isClass(id obj);
BOOL class_isMetaClass(Class cls);
Class class_getSuperclass(Class cls);
```

成员变量：

```objc
Ivar class_getInstanceVariable(Class cls, const char *name);
Ivar *class_copyIvarList(Class cls, unsigned int *outCount);
void object_setIvar(id obj, Ivar ivar, id value);
id object_getIvar(id obj, Ivar ivar);
BOOL class_addIvar(Class cls, const char *name, size_t size, uint8_t alignment, const char *types);
const char *ivar_getName(Ivar v);
const char *ivar_getTypeEncoding(Ivar v);
```

属性：

```objc
objc_property_t class_getProperty(Class cls, const char *name);
objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount);
BOOL class_addProperty(Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int count);
void class_replaceProperty(Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int count);
const char *property_getName(objc_property_t property);
const char *property_getAttributes(objc_property_t property);
```

方法：

```objc
Method class_getInstanceMethod(Class cls, SEL name);
Method class_getClassMethod(Class cls, SEL name);
IMP class_getMethodImplementation(Class cls, SEL name);
IMP method_setImplementation(Method m, IMP imp);
void method_exchangeImplementations(Method m1, Method m2);
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
SEL method_getName(Method m);
IMP method_getImplementation(Method m);
const char *method_getTypeEncoding(Method m);
unsigned int method_getNumberOfArguments(Method m);
char *method_copyReturnType(Method m);
char *method_copyArgumentType(Method m, unsigned int index);
```

## 7. RunLoop

### 7.1 RunLoop 解决什么问题

RunLoop 是线程的事件循环机制。它让线程在没有事件时休眠，在有事件时被唤醒处理任务。

典型应用：

- Timer。
- `performSelector:afterDelay:`。
- 主队列任务。
- 事件响应和手势识别。
- 界面刷新。
- Autorelease pool。
- 线程保活。
- 卡顿监控。

### 7.2 RunLoop 与线程

- 每条线程最多对应一个 RunLoop。
- RunLoop 以线程为 key 存在全局映射中。
- 线程刚创建时不一定已经有 RunLoop，第一次获取时创建。
- 主线程 RunLoop 已自动创建并运行。
- 子线程默认不会自动运行 RunLoop，需要手动启动。

获取方式：

```objc
[NSRunLoop currentRunLoop];
[NSRunLoop mainRunLoop];
CFRunLoopGetCurrent();
CFRunLoopGetMain();
```

### 7.3 RunLoop 相关对象

Core Foundation 中的核心类型：

- `CFRunLoopRef`
- `CFRunLoopModeRef`
- `CFRunLoopSourceRef`
- `CFRunLoopTimerRef`
- `CFRunLoopObserverRef`

一个 RunLoop 包含多个 mode；一个 mode 包含 sources、timers、observers。RunLoop 每次只能运行在一个 mode 中。

### 7.4 Mode

常见 mode：

- `kCFRunLoopDefaultMode` / `NSDefaultRunLoopMode`：默认模式。
- `UITrackingRunLoopMode`：滚动、触摸追踪模式。
- `NSRunLoopCommonModes` / `kCFRunLoopCommonModes`：不是一个实际 mode，而是一组常用 mode 的集合标签。

Timer 滚动时不触发的原因：Timer 默认只加到 default mode，UIScrollView 滚动时 RunLoop 切换到 tracking mode。解决方式通常是把 Timer 加到 common modes：

```objc
[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
```

如果对精度要求高，可以考虑 GCD timer 或 `CADisplayLink`，但仍要注意生命周期和强引用。

### 7.5 RunLoop 运行逻辑

典型流程：

1. 通知 observer：进入 loop。
2. 通知 observer：即将处理 timers。
3. 通知 observer：即将处理 sources。
4. 处理 blocks。
5. 处理 Source0。
6. 如果存在 Source1，跳到唤醒后处理。
7. 通知 observer：即将休眠。
8. 调用 `mach_msg()` 进入内核等待消息。
9. 被 Timer、GCD main queue、Source1 等唤醒。
10. 通知 observer：结束休眠。
11. 处理唤醒源。
12. 处理 blocks。
13. 决定继续循环或退出。
14. 通知 observer：退出 loop。

休眠的核心是用户态到内核态的 `mach_msg()`，没有消息时线程休眠，有消息时唤醒。

## 8. 多线程与同步

### 8.1 iOS 常见多线程方案

| 方案 | 特点 | 使用频率 |
|---|---|---|
| pthread | C API，跨平台，手动管理，使用复杂 | 低 |
| NSThread | OC 封装，可直接操作线程对象 | 偶尔 |
| GCD | C API，队列抽象，系统管理线程池 | 高 |
| NSOperationQueue | 基于 GCD，支持依赖、取消、状态、优先级 | 高 |

### 8.2 同步、异步、串行、并发

准确理解：

- 同步 `dispatch_sync`：提交任务后等待任务完成，当前调用栈被阻塞。
- 异步 `dispatch_async`：提交任务后立即返回，不等待任务完成。
- 串行队列：同一队列中的任务一个接一个执行。
- 并发队列：同一队列中的多个任务可以重叠执行。

需要修正课件中的简化说法：异步不等于一定开启新线程，同步也不等于一定不切线程。GCD 决定使用哪个线程，主队列异步仍在主线程执行。

### 8.3 常见死锁

在当前串行队列中同步派发到同一个串行队列，会死锁：

```objc
dispatch_sync(dispatch_get_main_queue(), ^{
    // 如果当前已经在主线程，这里永远等不到执行机会
});
```

原因：当前任务等待 sync block 完成，而 sync block 又排在当前任务之后，队列无法前进。

### 8.4 队列组

并发执行任务 1、任务 2，全部完成后回主线程执行任务 3：

```objc
dispatch_group_t group = dispatch_group_create();
dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

dispatch_group_async(group, queue, ^{
    // task 1
});

dispatch_group_async(group, queue, ^{
    // task 2
});

dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    // task 3
});
```

### 8.5 线程安全隐患

线程安全问题通常来自多个线程同时访问同一份可变资源：

- 多线程读同一不可变资源通常安全。
- 多线程写同一资源不安全。
- 一个线程读、另一个线程写同一可变资源也不安全。

解决思路：把共享可变状态保护起来，或用不可变数据、消息传递、串行队列、锁、actor 等方式避免共享写。

### 8.6 锁与同步方案

| 方案 | 特点 | 注意 |
|---|---|---|
| `OSSpinLock` | 自旋锁，忙等 | 已废弃且不安全，不建议使用 |
| `os_unfair_lock` | 取代 OSSpinLock，等待线程会阻塞 | 不递归，注意成对 lock/unlock |
| `pthread_mutex` | 互斥锁，等待线程休眠 | 可配置普通锁、递归锁、条件锁 |
| `dispatch_semaphore` | 信号量 | 初始值为 1 可做互斥 |
| 串行 `dispatch_queue` | 队列隔离共享资源 | 注意同步派发死锁 |
| `NSLock` | mutex 封装 | 简洁，但功能有限 |
| `NSRecursiveLock` | 递归锁 | 避免滥用递归掩盖设计问题 |
| `NSCondition` | mutex + condition | 适合生产者消费者 |
| `NSConditionLock` | 条件值封装 | 逻辑更复杂，慎用 |
| `@synchronized` | 递归互斥封装 | 简单但开销较大 |

自旋锁适合临界区极短、竞争很少、多核且 CPU 不紧张的场景。但在 iOS 应用层，优先使用 `os_unfair_lock`、串行队列、semaphore、OperationQueue 或更高层抽象。

### 8.7 读写安全

多读单写场景：

- 同一时刻允许多个读。
- 同一时刻只允许一个写。
- 写时不允许读。

方案一：`pthread_rwlock`。

方案二：自建并发队列 + barrier：

```objc
dispatch_queue_t queue = dispatch_queue_create("com.example.rw", DISPATCH_QUEUE_CONCURRENT);

dispatch_sync(queue, ^{
    // read
});

dispatch_barrier_async(queue, ^{
    // write
});
```

barrier 必须用于自己创建的并发队列。传入串行队列或全局并发队列时，barrier 退化为普通 async/sync。

### 8.8 `atomic`

`atomic` 只保证属性 getter/setter 本身的原子性，不保证复合操作线程安全。

不安全示例：

```objc
self.count = self.count + 1;
```

这包含读、加、写多个步骤，即使属性是 atomic，也可能发生竞争。

## 9. 内存管理

### 9.1 内存布局

概念上可以分为：

- 代码段 `__TEXT`：编译后的代码。
- 数据段 `__DATA`：全局变量、静态变量等。
- 字符串常量区：如 `@"123"`。
- 堆：`alloc`、`malloc`、`calloc` 等动态分配。
- 栈：函数调用栈、局部变量。
- 内核区。

实际地址会受 ASLR、平台和运行时布局影响，不要把示意图当成固定地址分布。

### 9.2 Tagged Pointer

Tagged Pointer 用于优化小对象，例如部分 `NSNumber`、`NSDate`、`NSString`。它把数据直接编码进指针值里，减少堆分配和引用计数维护成本。

注意：

- Tagged Pointer 的判断细节与平台、架构、Runtime 版本有关。
- 不建议在业务中硬编码最高位或最低位判断。
- 面试可讲「小对象直接编码在指针中，大对象才走堆对象」。

### 9.3 引用计数

MRC 规则：

- `alloc`、`new`、`copy`、`mutableCopy` 返回的对象由调用方拥有。
- `retain` 引用计数加 1。
- `release` 引用计数减 1。
- 引用计数归零时调用 `dealloc` 并释放内存。

ARC 做的事：编译器在合适位置插入 retain、release、autorelease 等内存管理调用，Runtime 配合弱引用表、SideTable、autorelease pool 等机制执行。

引用计数可能存储在：

- non-pointer isa 的 `extra_rc`。
- SideTable 的引用计数表。

### 9.4 `copy` 和 `mutableCopy`

常见规律：

| 源对象 | `copy` | `mutableCopy` |
|---|---|---|
| `NSString` | 不可变对象常见浅拷贝 | 新的可变对象 |
| `NSMutableString` | 新的不可变对象 | 新的可变对象 |
| `NSArray` | 不可变对象常见浅拷贝 | 新的可变数组 |
| `NSMutableArray` | 新的不可变数组 | 新的可变数组 |
| `NSDictionary` | 不可变对象常见浅拷贝 | 新的可变字典 |
| `NSMutableDictionary` | 新的不可变字典 | 新的可变字典 |

属性建议：

- `NSString`、`NSArray`、`NSDictionary` 对外暴露不可变类型时通常用 `copy`，防止外部传入 mutable 子类后被外部修改。
- block 属性建议用 `copy`。

### 9.5 `dealloc`

对象释放路径可概括为：

```text
dealloc
_objc_rootDealloc
rootDealloc
object_dispose
objc_destructInstance
free
```

释放过程中会处理：

- C++ 析构。
- strong ivar 释放。
- weak 引用清零。
- 关联对象清理。
- 内存释放。

### 9.6 Autorelease Pool

自动释放池底层核心结构：

- `__AtAutoreleasePool`
- `AutoreleasePoolPage`

每个 `AutoreleasePoolPage` 常见大小为 4096 字节，多个 page 通过双向链表连接。调用 `push` 时压入边界标记 `POOL_BOUNDARY`，调用 `pop` 时从栈顶开始对 autorelease 对象发送 `release`，直到遇到对应边界。

主线程 RunLoop 中通常注册 observer：

- 进入 RunLoop 时 push。
- 即将休眠时 pop 再 push。
- 退出 RunLoop 时 pop。

大量临时对象循环中应主动加 `@autoreleasepool`：

```objc
for (...) {
    @autoreleasepool {
        // create temporary objects
    }
}
```

### 9.7 Timer 与循环引用

`NSTimer`、`CADisplayLink` 会强引用 target。如果 target 又强引用 timer，就会形成循环引用。

解决方式：

- 用 block API，并在 block 中弱引用 self。
- 使用代理对象或 `NSProxy`。
- 及时 `invalidate`。
- 对重复 timer，明确生命周期归属。

## 10. 性能优化

### 10.1 卡顿来源

屏幕渲染链路可以简化为：

```text
CPU 计算、布局、解码、绘制 -> GPU 合成、渲染 -> 帧缓存 -> 显示器
```

60 FPS 下每帧预算约 16.67 ms。120 Hz 屏幕预算更紧，约 8.33 ms。主线程长期占用、CPU 计算过重、GPU 渲染过重、同步 I/O、锁等待等都会造成卡顿。

### 10.2 CPU 优化

- 避免主线程做耗时任务。
- 提前计算布局，减少 cell 复用过程中的重复计算。
- 避免频繁修改 `frame`、`bounds`、`transform` 等导致布局和渲染更新。
- 文本高度、富文本排版、图片解码放到后台。
- 控制并发数量，避免线程过多导致调度开销。
- Auto Layout 不是不能用，而是避免在高频滚动场景构造过多复杂约束。
- 图片尺寸尽量匹配显示尺寸，避免大图直接进列表。

### 10.3 GPU 优化

- 降低视图层级和透明混合。
- 不透明视图设置合适背景和 `opaque = YES`。
- 避免短时间显示大量大图。
- 大图先 downsample。
- 避免不必要的离屏渲染。
- 阴影设置 `shadowPath`。
- 对圆角、遮罩、阴影组合做真机 Instruments 验证。

### 10.4 离屏渲染

离屏渲染指 GPU 需要在当前屏幕缓冲区之外开辟额外缓冲区，再把结果合成回屏幕。成本来自额外缓冲区和上下文切换。

可能触发或加重离屏的操作：

- `layer.shouldRasterize = YES`
- `layer.mask`
- 复杂圆角和裁剪组合
- 动态阴影，尤其未设置 `shadowPath`

修正课件中的绝对化说法：现代 iOS 对部分简单圆角已有优化，不能简单说所有 `cornerRadius + masksToBounds` 都必然造成严重离屏。应该以 Instruments 的 Core Animation、Hitches、Time Profiler 真机结果为准。

### 10.5 卡顿检测

常见方案：

- RunLoop observer 监控主线程状态切换耗时。
- 主线程 watchdog。
- Instruments: Time Profiler、Core Animation、Hitches。
- MetricKit 收集线上卡顿和启动指标。
- `os_signpost` 标记关键路径。

### 10.6 耗电优化

CPU/GPU：

- 减少无意义轮询和 timer。
- 合理批处理。
- 避免频繁唤醒。

I/O：

- 小数据合并写。
- 大文件读写考虑异步 I/O。
- 大量结构化数据用 SQLite/Core Data 等。

网络：

- 减少请求次数。
- 压缩数据。
- 合理缓存。
- 支持断点续传。
- 网络不可用时不要反复重试。
- 设置超时和取消。

定位和传感器：

- 不需要实时定位就不要持续定位。
- 降低精度。
- 定位完成后停止。
- 后台定位要设置合理策略。
- 不需要时关闭加速度计、陀螺仪等硬件。

### 10.7 启动优化

冷启动阶段：

1. dyld 加载 Mach-O 和动态库。
2. Runtime 解析 ObjC 结构，注册类、selector、protocol，调用 `+load` 等。
3. 进入 `main`，执行 `UIApplicationMain` 和 AppDelegate 启动逻辑。

优化：

- 减少动态库数量。
- 清理无用类、分类、selector。
- 避免大量 `+load`、C++ 静态构造器、`__attribute__((constructor))`。
- 启动首屏不需要的工作延迟或懒加载。
- 减少启动期同步 I/O 和网络等待。
- 用 Instruments App Launch、Time Profiler、`os_signpost` 做实测。

### 10.8 包体瘦身

资源：

- 无损压缩图片。
- 删除未使用资源。
- 大图按需下载或使用更合适格式。

可执行文件：

- 开启编译优化。
- strip 符号。
- 清理无用代码。
- 分析 LinkMap。
- 谨慎引入大型三方库。

## 11. 架构与设计模式

### 11.1 架构是什么

架构是软件设计方案，关注：

- 类与类之间的关系。
- 模块与模块之间的关系。
- 客户端与服务端之间的关系。
- 业务、网络、本地数据、界面层的边界。

### 11.2 MVC、MVP、MVVM

Apple MVC：

- Model 保存业务数据。
- View 展示和接收用户交互。
- Controller 协调 Model 和 View。
- 优点是 View 和 Model 可复用。
- 缺点是 Controller 容易膨胀。

变种 MVC：

- 将 View 的细节进一步封装，Controller 变薄。
- 风险是 View 可能依赖 Model，导致复用和测试变差。

MVP：

- Presenter 负责表现逻辑。
- View 被动展示。
- Model 不直接驱动 View。
- 测试性通常比胖 Controller 好。

MVVM：

- ViewModel 暴露 View 需要的数据和命令。
- View 绑定 ViewModel。
- Model 保持业务数据。
- 适合状态驱动 UI，但需要避免 ViewModel 变成新的大杂烩。

### 11.3 常见设计模式

创建型：

- 单例。
- 工厂方法。
- 抽象工厂。
- Builder。

结构型：

- 代理。
- 适配器。
- 装饰器。
- 组合。
- Facade。

行为型：

- 观察者。
- 命令。
- 策略。
- 责任链。
- 模板方法。

面试时不要只背模式名，要能讲清楚项目中为什么用、替代方案是什么、代价是什么。

## 12. 高频面试速答

### 一个 NSObject 对象占用多少内存？

64 位下 `NSObject` 实例内部通常只需要 8 字节 `isa`，但 malloc 实际分配常见为 16 字节。用 `class_getInstanceSize` 看实例变量布局大小，用 `malloc_size` 看分配器实际分配大小。

### OC 方法调用流程？

方法调用会转成 `objc_msgSend(receiver, selector, ...)`。先从 receiver 的 class cache 查，再查方法列表，再沿 superclass 查找。找不到进入动态方法解析，仍找不到进入消息转发，最后 `doesNotRecognizeSelector:`。

### KVO 本质？

Runtime 动态创建子类，修改被观察对象 `isa`，重写 setter，在 setter 中触发 will/did change 通知。直接改 ivar 不触发自动 KVO。

### Category 能否添加成员变量？

不能直接给已存在类通过 Category 添加 ivar，因为类实例布局已确定。可以通过关联对象间接实现属性效果。

### `+load` 和 `+initialize` 区别？

`+load` 在类和分类加载时调用，直接按函数地址调用，不走消息发送。`+initialize` 在类第一次收到消息前调用，父类先于子类，走消息发送，继承实现可能导致父类逻辑多次执行。

### Block 为什么用 copy？

捕获 auto 变量的 block 初始可能在栈上。copy 后会到堆上，才能在作用域外安全使用。ARC 下编译器会自动处理很多场景，但属性语义仍推荐 `copy`。

### `__block` 作用？

允许 block 内修改外部 auto 变量。底层会把变量包装成 byref 结构，使用 `__forwarding` 保证栈到堆迁移后访问同一份数据。

### RunLoop 和线程关系？

每条线程最多一个 RunLoop。主线程 RunLoop 自动运行，子线程默认不运行。RunLoop 让线程有事做事、没事休眠。

### NSTimer 滚动时不触发怎么办？

原因是滚动时 RunLoop 切到 `UITrackingRunLoopMode`，默认 timer 在 default mode。可把 timer 加到 common modes，或换用更合适的 GCD timer/CADisplayLink。

### GCD sync/async 与 serial/concurrent 区别？

sync/async 影响提交者是否等待；serial/concurrent 影响队列内任务是否可并发执行。async 不保证开新线程，main queue async 仍在主线程执行。

### `dispatch_barrier_async` 使用条件？

用于自己创建的并发队列。传入串行队列或全局并发队列时，行为等同普通 async。

### atomic 是否线程安全？

只保证 getter/setter 原子性，不保证复合操作线程安全。

### Autorelease 对象何时释放？

对象加入当前 autorelease pool。pool pop 时对其中对象发送 release。主线程 RunLoop 会在进入、休眠前、退出等时机维护 pool。

### 卡顿怎么定位？

先区分 CPU、GPU、I/O、锁等待、主线程同步任务。用 Instruments 的 Time Profiler、Core Animation/Hitches、Allocations、System Trace，配合 `os_signpost` 和线上 MetricKit。

## 13. 错误、过时点与修正

整体没有发现会推翻主线的严重错误。以下是需要修正、补充限定条件或按现代实践更新的点。

| 来源 | 原表述或问题 | 修正 |
|---|---|---|
| 01-OC语法 Slide 25 | meta-class 的 `isa` 指向基类 meta-class | 对非根类可这样简化，但根 meta-class 的 `isa` 指向自己；根 meta-class 的 `superclass` 指向根 class |
| 01-OC语法 KVO 部分 | 强调 `_NSSet*ValueAndNotify` 等私有实现 | 可用于理解，但这是私有实现细节，业务代码不应依赖类名或函数名 |
| 01-OC语法 Slide 52 | ARC 下 block 属性可写 `strong` 或 `copy` | ARC 下很多场景 strong 可工作，但属性语义仍推荐 `copy`，尤其便于和 MRC/历史代码一致 |
| 04-多线程 Slide 8 | 异步具备开启新线程能力 | 过度简化。异步表示不等待完成，不保证新线程；主队列异步仍在主线程 |
| 04-多线程 Slide 21/32 | OSSpinLock 性能高 | `OSSpinLock` 已废弃且存在优先级反转风险，不应推荐用于新代码 |
| 04-多线程 Slide 37 | `dispatch_queue_cretate` | 拼写错误，应为 `dispatch_queue_create` |
| 04-多线程 Slide 37 | barrier 用法 | 课件结论正确：必须是自己创建的并发队列；全局并发队列或串行队列会退化 |
| 05-内存管理 Slide 7 | iOS 用最高有效位判断 Tagged Pointer，Mac 用最低位 | 这是历史/教学简化。现代 Runtime、arm64e 和 tagged pointer 混淆策略下不应硬编码位判断 |
| 05-内存管理 Slide 6 | 内存布局图 | 只能当概念图。真实虚拟地址受 ASLR、架构、系统版本影响 |
| 06-性能优化 Slide 7 | GPU 最大纹理尺寸 4096x4096 | 明显过时。Apple Metal feature set 中许多 GPU family 的 2D texture limit 已是 8192、16384 或更高 |
| 06-性能优化 Slide 8 | `cornerRadius + masksToBounds` 触发离屏渲染 | 应改成「可能触发或加重渲染成本」。现代系统对部分简单圆角有优化，应真机验证 |
| 06-性能优化 Slide 18 | 用 `+initialize` 和 `dispatch_once` 取代所有 `+load` | 方向是减少 `+load`，但 `+initialize` 也不适合复杂初始化。更推荐显式懒加载、模块启动器和按需初始化 |
| 06-性能优化 Slide 12 | 尽量不要使用 significant location change | 过于绝对。显著位置变化服务本身是低功耗粗粒度方案，应按定位精度、频率、后台需求选择 |
| 07-设计模式 | 架构只覆盖 MVC/MVP/MVVM | 对入门足够，但实际项目还应补充路由、依赖注入、模块化、数据层、测试策略 |

## 14. PPT 建议补充内容

### Objective-C / Runtime

- weak 指针实现：SideTable、weak table、对象释放时 weak 清零。
- `objc_msgSend` 函数指针调用时的类型转换风险。
- 方法交换最佳实践：只在 `+load` 或明确初始化点执行一次，交换前校验 Method，避免多库重复交换。
- `objc_direct`、Swift 与 ObjC Runtime 交互限制。
- `class_copy*List` 返回值需要 `free`。

### KVO / KVC

- KVO observer 生命周期和移除策略。
- KVO context 的正确使用。
- 自动通知与手动通知的关闭方式。
- Swift 中 `@objc dynamic`、`NSKeyValueObservation` token 生命周期。

### Block

- weak-strong dance 的标准模板。
- block 作为异步回调时 self 生命周期策略。
- `__block` 在 ARC 下不等于弱引用。

### RunLoop

- `NSRunLoopCommonModes` 是 mode 集合标签，不是实际 mode。
- `CADisplayLink` 与屏幕刷新关系。
- `dispatch_source_t` timer 和 RunLoop timer 对比。
- RunLoop 卡顿监控的误报问题，比如后台、调试器、长事务。

### 多线程

- QoS 和优先级反转。
- OperationQueue 的依赖、取消、状态 KVO。
- Thread Sanitizer、Main Thread Checker。
- Swift Concurrency、actor、MainActor 与旧 GCD 的关系。
- 数据隔离优先于加锁。

### 内存管理

- ARC 修饰符：`strong`、`weak`、`copy`、`assign`、`unsafe_unretained`、`autoreleasing`。
- 循环引用场景：delegate、timer、notification、block、display link。
- Instruments Leaks、Allocations、Zombies。
- autorelease pool 在 GCD 队列中的释放时机不保证精确，内存敏感循环要手动建 pool。

### 性能

- Instruments 实战流程：先定量，再定位，再改动，再复测。
- 图片 downsampling 与预解码。
- 列表预取、缓存、复用、异步布局。
- `os_signpost` 和 MetricKit。
- 120 Hz 设备下每帧预算更短。
- 启动优化分 pre-main、main、首屏可交互三段衡量。

### 架构

- Coordinator / Router 处理页面流转。
- Repository / Service 分离数据来源。
- Dependency Injection 提升测试性。
- 模块化、组件边界、公共库治理。
- 单元测试、快照测试、接口 mock。

## 15. 来源覆盖与参考资料

### 本地 PPT 覆盖

| 文件 | 页数 | 覆盖主题 |
|---|---:|---|
| `01-OC语法.pptx` | 65 | 对象模型、KVO/KVC、Category、关联对象、Block |
| `02-Runtime.pptx` | 36 | Runtime、方法缓存、消息发送、动态解析、消息转发、Runtime API |
| `03-RunLoop.pptx` | 18 | RunLoop、mode、source、timer、observer、休眠唤醒 |
| `04-多线程.pptx` | 38 | GCD、队列、线程安全、锁、读写安全 |
| `05-内存管理.pptx` | 20 | Timer 循环引用、Tagged Pointer、引用计数、copy、autorelease pool |
| `06-性能优化.pptx` | 20 | 卡顿、CPU/GPU、离屏渲染、耗电、启动、包体 |
| `07-设计模式与架构.pptx` | 9 | MVC、MVP、MVVM、分层、设计模式 |
| `08-总结.pptx` | 3 | 学习建议与推荐资料 |

### 官方参考

- Apple Developer: Objective-C Runtime, `objc_setAssociatedObject`: https://developer.apple.com/documentation/objectivec/objc_setassociatedobject%28_%3A_%3A_%3A_%3A%29
- Apple Developer: `NSObject +initialize`: https://developer.apple.com/documentation/objectivec/nsobject/1418639-initialize
- Apple Developer: NSKeyValueObserving: https://developer.apple.com/documentation/objectivec/nskeyvalueobserving
- Apple Archive: Run Loop Management: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html
- Apple Developer: Dispatch Barrier: https://developer.apple.com/documentation/dispatch/dispatch_barrier_async
- Apple Developer: Dispatch Group Notify: https://developer.apple.com/documentation/dispatch/1452933-dispatch_group_notify
- Apple Developer: `os_unfair_lock_lock`: https://developer.apple.com/documentation/os/os_unfair_lock_lock
- Apple Developer: Metal Feature Set Tables: https://developer.apple.com/metal/limits/
- Apple Developer: `CALayer.shadowPath`: https://developer.apple.com/documentation/quartzcore/calayer/shadowpath
- Apple Developer: Xcode sanitizers: https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early

