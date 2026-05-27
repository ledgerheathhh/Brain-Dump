# Objective-C内存管理

> 内存管理的核心工作就是及时清理回收不用的内存空间，以便高效的利用内存空间。在面向对象编程开发中，内存管理的核心就是管理对象的释放。当一个对象不再被使用时，需要及时从内存中清除。

哪些对象需要进行**内存管理**

* 绝大多数 Objective-C 对象需要进行生命周期管理
* 非对象类型(int、char、float、double、struct、enum等) 通常由其所在作用域、栈帧或持有它的对象负责管理

这是因为

* Objective-C 对象通常存储在堆里。
* 操作系统的堆：一般由程序员分配释放，若程序员不释放，程序结束时可能由OS回收，分配方式类似于链表
* 局部的非对象值类型一般放在栈里面；如果它们作为对象成员、全局变量或动态分配内存的一部分，也可能位于堆或全局存储区。
* 操作系统的栈：由操作系统自动分配释放，存放函数的参数值，局部变量的值等。其操作方式类似于数据结构中的栈(先进后出)

## 引用计数(Reference Count)

引用计数是在Objective-C中用于管理对象生命周期的机制。当一个对象通过 `alloc/new/copy/mutableCopy` 等方式创建时，调用方获得对象所有权。只有产生所有权关系的操作（如 `retain`、`strong`、`copy`）才会增加引用计数；普通指针赋值、`assign`、`weak` 不会增加引用计数。当对象不再被任何强所有权持有时，它会被销毁，占用的内存被回收。

## MRC(Manual Reference Counting)

MRC，即手工引用计数。在Xcode4.2版本之前，对象的引用计数都需要程序员来手工管理，因此，程序员需要花费大量的经历来管理对象的创建与销毁，其中一个最基本的原则就是：谁创建谁销毁。

在MRC中，程序员需要手工管理对象的引用计数，在NSObject类中，有关引用计数有如下常用方法。

* 引用计数加一

```objectivec
- (instancetype)retain OBJC_ARC_UNAVAILABLE;
```

* 引用计数减一

```objectivec
- (oneway void)release OBJC_ARC_UNAVAILABLE;
```

* 获取对象当前的引用计数

```objectivec
- (NSUInteger)retainCount OBJC_ARC_UNAVAILABLE;
```

```objectivec
// 只要创建一个对象默认引用计数器的值就是1
        Person *p = [[Person alloc] init];
        NSLog(@"retainCount = %lu", [p retainCount]); // 1

        // 只要给对象发送一个retain消息, 对象的引用计数器就会+1
        [p retain];

        NSLog(@"retainCount = %lu", [p retainCount]); // 2
        // 通过指针变量p,给p指向的对象发送一条release消息
        // 只要对象接收到release消息, 引用计数器就会-1
        // 只要一个对象的引用计数器为0, 系统就会释放对象

        [p release];
        // 需要注意的是: release并不代表销毁\回收对象, 仅仅是计数器-1
        NSLog(@"retainCount = %lu", [p retainCount]); // 1

        [p release]; // 0
        NSLog(@"--------");
//    [p setAge:20];    // 此时对象已经被释放
```

* 当一个对象的引用计数器值为0时，这个对象即将被销毁，其占用的内存被系统回收,对象即将被销毁时系统会自动给对象发送一条dealloc消息(因此，从dealloc方法有没有被调用,就可以判断出对象是否被销毁)
* dealloc方法的重写:一般会重写dealloc方法，在这里释放相关资源,一旦重写了dealloc方法，就必须调用[super dealloc]，并且放在最后面调用
* 不能直接调用dealloc方法
* 一旦对象被回收了, 它占用的内存就不再可用，坚持使用会导致程序崩溃（野指针错误）

#### 野指针和空指针

* 只要一个对象被释放了，我们就称这个对象为 "僵尸对象(不能再使用的对象)"
* 当一个指针指向一个僵尸对象(不可用内存)，我们就称这个指针为野指针
* 只要给一个野指针发送消息就会报错(EXC_BAD_ACCESS错误)

```objectivec
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person *p = [[Person alloc] init]; // 执行完引用计数为1   

        [p release]; // 执行完引用计数为0，实例对象被释放
        [p release]; // 此时，p就变成了野指针，再给野指针p发送消息就会报错
        [p release];
    }
    return 0;
}
```

* 为了避免给野指针发送消息会报错，一般情况下，当一个对象被释放后我们会将这个对象的指针设置为空指针
* 空指针
  * 没有指向存储空间的指针(里面存的是nil, 也就是0)
  * 给空指针发消息是没有任何反应的

#### MRC中避免循环retain

如果在property后边加上retain，系统就会自动帮我们生成getter/setter方法内存管理的代码，但是仍需要我们自己重写dealloc方法

如果在property后边加上assign，系统就不会帮我们生成set方法内存管理的代码，仅仅只会生成普通的getter/setter方法，默认什么都不写就是assign

A对象要拥有B对象，而B对应又要拥有A对象，此时会形成循环retain，导致A对象和B对象永远无法释放

解决方案：

* 不要让A retain B，B retain A
* 让其中一方不要做retain操作即可
* 当两端互相引用时，应该一端用retain，一端用assign

## ARC(Automatic Reference Counting)

随着Xcode4.2的发布，苹果引入了其中一个新特性就是自动引用计数(ARC：Automatic Reference Counting)。与MRC不同，自动引用计数(ARC)模式中，对象的引用计数管理完全交由系统来管理，也就是说，在MRC中的retain/release操作都由系统自动完成了。ARC 通过自动管理强引用和弱引用，简化了内存管理，避免了许多手动管理内存时容易出现的问题。强引用确保对象在被使用时不会被销毁，而弱引用则避免了循环引用和悬空指针问题。

#### ARC的判断原则

只要还有一个强指针变量指向对象，对象就会保持在内存中。

* 强指针
  * 默认所有对象的指针变量都是强指针
  * 被__strong修饰的指针

在 ARC 中，所有对象默认都是强引用（strong reference）。强引用会增加对象的引用计数，确保对象在强引用存在期间不会被释放。

```objectivec
 Person *p1 = [[Person alloc] init];
 __strong  Person *p2 = [[Person alloc] init];
```

* 弱指针
  * 被__weak修饰的指针

弱引用（weak reference）不会增加对象的引用计数。当一个对象没有强引用指向它时，即使存在弱引用，该对象也会被销毁。弱引用在对象被销毁时会自动置为 `nil`，避免了悬空指针（dangling pointer）的问题。

运行时系统维护一个弱引用表，当对象被销毁时，自动将所有指向该对象的弱引用置为 `nil`。

```objectivec
__weak  Person *p = [[Person alloc] init];
// 如果 obj 被释放，p 会自动置为 nil
```

#### ARC的注意点

* 不允许调用对象的 release方法
* 不允许调用 autorelease方法
* 重写父类的dealloc方法时，不能再调用 [super dealloc];

#### ARC的单对象内存管理

* 局部变量释放对象随之被释放

```objectivec
int main(int argc, const char * argv[]) {
   @autoreleasepool {
        Person *p = [[Person alloc] init];
    } // 执行到这一行局部变量p释放
    // 由于没有强指针指向对象, 所以对象也释放
    return 0;
}
```

* 清空指针对象随之被释放

```objectivec
int main(int argc, const char * argv[]) {
   @autoreleasepool {
        Person *p = [[Person alloc] init];
        p = nil; // 执行到这一行, 由于没有强指针指向对象, 所以对象被释放
    }
    return 0;
}
```

* 注意: 千万不要使用弱指针保存新创建的对象

```objectivec
int main(int argc, const char * argv[]) {
   @autoreleasepool {
        // p是弱指针, 对象会被立即释放
        __weak Person *p1 = [[Person alloc] init];
    }
    return 0;
}
```

#### ARC下循环引用问题

* ARC和MRC一样，如果A拥有B，B也拥有A，那么必须一方使用弱指针

```objectivec
@interface Person : NSObject
@property (nonatomic, strong) Dog *dog;
@end

@interface Dog : NSObject
// 错误写法, 循环引用会导致内存泄露
//@property (nonatomic, strong) Person *owner;

// 正确写法, 当如果保存对象建议使用weak
@property (nonatomic, weak) Person *owner;
@end
```
