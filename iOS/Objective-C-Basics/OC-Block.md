# block

> block是从iOS4开始引入的一个新特性，block是对C语言的一个扩展，在Objective-C中完全支持。block在现在的iOS开发中使用越来越普遍，因为block使用起来非常强大，简单来说， **block就是封装了一组代码语句的对象** ，可以在任何时间执行。

Block块是封装工作单元的对象，是可以在任何时间执行的代码段。其本质上是可移植的匿名函数，可以作为方法和函数的参数传入，可以从方法和函数中返回。

Block是对C语言的一种扩展，它并未作为标准的ANSI C所定义的部分，而是由苹果公司添加到语言中的。Block看起来更像是函数，可以给Block传递参数，Block也可以具有返回值。

在iOS4以后，越来越多的系统框架的API在使用Block。苹果对于Block的使用主要集中在如下几个方面：

* 完成处理–Completion Handlers
* 通知处理–Notification Handlers
* 错误处理–Error Handlers
* 枚举–Enumeration
* 动画与形变–View Animation and Transitions
* 分类–Sorting
* 线程管理：GCD/NSOperation

## 定义与调用

块是以插入字符^开头，后面的一个括号()内表示块所需要的参数，最后面的大括号{}中是块主体，最后以分号;结束。如下面代码所示：

```objectivec
^(int inputNum) {
    NSLog(@"printBlock Called!");
    return inputNum;
};
```

同时，也可以将这个块赋值给一个变量printBlock，声明方式如下。其中，变量printBlock就是 **指向代码块的指针** 。

```objectivec
返回值类型 (^block名称)(参数类型, 参数类型, ...) = ^(参数类型 参数名称, 参数类型 参数名称, ...) {
 //block体（封装的代码）
};
```

如下示例，我们定义了一个变量printBlock，这个变量指向一个Block，Block位于等号右边，这个Block执行时，需要提供一个int型的参数，同时会返回一个int型的返回值。

```objectivec
int (^printBlock)(int) = ^(int inputNum) {
    NSLog(@"printBlock Called!");
    return inputNum;
};
```

当需要调用已经定义的block时，可以使用如下方式，和函数调用十分类似。

```objectivec
int i = printBlock(100);
```

## 把Block声明为类的属性

由于Block就是一个存储了一段代码的对象，因此，也可以把Block设置为某个类的属性。Block属性与其他类型的属性，如：NSString、NSArray，没有什么本质区别，都可以使用点语法来对属性进行取值和赋值。

```objectivec
@property (nonatomic, copy) 返回值类型(^Block名称)(参数类型);
```

*注意：当声明一个block类型的属性时，需要使用属性关键字* *copy* *。*

## 访问Block之外的变量

如果在一个方法中声明了Block，那么Block中也可以访问在该方法中定义的变量，前提是该变量的定义在Block定义之前。如下所示，我们定义了一个int型的变量i，在名称为beginBlock的Block中，可以访问i值。

```objectivec
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        int i =  100;
        void (^beginBlock)(void) = ^(void) {
            NSLog(@"i 在Block中获取的值:%d",i);
        };
        beginBlock();
        //修改i的值
        i = 200;
        beginBlock();
        NSLog(@"i 的当前值: %d",i);
    }
    return 0;
}
```

在上述代码中，Block可以访问i的值，但是当i值发生改变的时候(i=200)，再次调用Block打印的还是原来的i值（100）。也就是说，在block定义时，会“捕捉”一次Block中使用的对象i，当i发生变化的时候，不会影响已经“捕捉”到的值。

同时需要注意的是，此时在Block中是不能对i值进行修改的！！！假如修改Xcode会报错。

## 修改Block之外的变量

在Block中，假如需要更新在Block之外定义的变量时，那么在定义变量时，必须加上__block关键字。如果这样定义，以上面的代码为例，当i的值发生变化时，block中“捕捉”的i值会随时变化。这个在实际开发中比较常用。如下所示：

```objectivec
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        __block int i =  100;
        void (^withBlockWord)(void) = ^(void) {
            NSLog(@"i 在Block中获取的值:%d",i);
        };
        withBlockWord();
        i = 200;
        withBlockWord();
        NSLog(@"i 的当前值: %d",i);
    }
    return 0;
}
```

此时，在Block中可以对i的值进行修改，并且编译器也不会报错。

## OC Block块：4-回调CallBack

> 在iOS的开发过程中，Block的回调使用非常普遍，也是Block的重要用法之一，在使用过程中经常可以用于替换**代理**的实现方法。例如，当一段动画播放完成后，执行一段代码，当得到请求的网络数据后，执行一段对数据的操作代码等等。这些场景中，都使用到了Block的回调机制。Block的回调机制，可以使代码的编写变得十分的清晰，提升了代码的可读性。

当我们需要定义回调Block时，通常情况下可以按照如下步骤进行：

1. 定义带Block参数的方法；
2. 设置Block的回调时机；
3. 定义Block中需要执行的操作

下面通过一个实际的例子来实践一下Block的回调实现方法。

* 创建一个Single View Application类型的工程。
* 定义带Block参数的方法。创建一个Task类，继承自NSObject。在Task.h文件中，添加如下的方法，在该方法中，设置一个Block作为参数。其中，(void(^)(void))表示为一个没有参数和返回值的Block。

```objectivec
#import <Foundation/Foundation.h>
@interface Task : NSObject
-(void) beginTaskWithCallbackBlock:(void (^)(void)) callbackBlock;
@end
```

* 设置Block的回调时机。在Task.m文件中，实现该方法。下面的代码中，当方法被调用时，会打印一行Log，提示任务开始。3秒钟后，会调用Block中的代码。

```objectivec
-(void)beginTaskWithCallbackBlock:(void (^)(void))callbackBlock{
    NSLog(@"任务开始，3秒后调用block中的代码! 现在时间是：%@",[NSDate date]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        callbackBlock();
    });
}
```

* 定义Block中需要执行的操作。在上面代码的实现过程中，最关键的是定义了Block的调用时机，但没有定义Block的代码内容。Block中的代码内容，可以在使用该方法时进行赋值。在工程的ViewController.m文件中，导入Task.h头文件，并添加下面的代码，当执行到Block时，打印一行日志，提示任务完成。

```objectivec
- (void)viewDidLoad {
    [super viewDidLoad];
    Task *task = [[Task alloc] init];
    [task beginTaskWithCallbackBlock:^{
        NSLog(@"block中的代码被执行!现在时间是：%@",[NSDate date]);
    }];
}
```


## 系统框架中的Block

> Apple定义的系统框架的API中，对Block的使用也比较集中，主要在动画、通知等等几个方面，因此，对于普通开发者来说，重点掌握系统框架API中Block的使用也是比较有必要的。

#### 1、系统框架API中的Block

在iOS4以后，越来越多的系统级的API在使用Block。苹果对于Block的使用主要集中在如下几个方面：

* 完成处理–Completion Handlers
* 通知处理–Notification Handlers
* 错误处理–Error Handlers
* 枚举–Enumeration
* 动画与形变–View Animation and Transitions
* 分类–Sorting
* 线程管理：GCD/NSOperation


#### 2、动画与形变

在UIView类的定义中，提供了若干个包含Block参数的方法，用来设置动画，例如修改View的大小、位置、透明度等等。

```objectivec
[UIView animateWithDuration:0.2 animations:^{
        view.alpha = 0.0;
    } completion:^(BOOL finished){
        [view removeFromSuperview];
}];
```

#### 3、完成与错误处理

完成处理Block在某个动作完成后，通过回调的方式进行执行。错误处理Block会在执行某个操作时，假如发生错误而被执行。

```objectivec
- (IBAction)pressBtn:(id)sender {
  
    CGRect cacheFrame = self.imageView.frame;
    [UIView animateWithDuration:1.5 animations:^{//播放动画Block
        CGRect newFrame = self.imageView.frame;
        newFrame.origin.y = newFrame.origin.y + 150.0;
        self.imageView.frame = newFrame;
        self.imageView.alpha = 0.2;
      }
        completion:^ (BOOL finished) {//结束回调Block
            if (finished) {
                // Revert image view to original.
                self.imageView.frame = cacheFrame;
                self.imageView.alpha = 1.0;                                                 
            }
        }
    ];
}
```

#### 4、通知

在注册通知观察者中，有如下的方法，可以在添加/注册观察者时，编写收到通知后需要执行的Block代码。使用这个方法来注册通知，可以使代码简单明了。

```objectivec
- (id )addObserverForName:(nullable NSString *)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block;
```

示例：

```objectivec
- (void)viewDidLoad {
    [super viewDidLoad]; 
    //注册观察者
    [[NSNotificationCenter defaultCenter] addObserverForName:@"AnimationCompleted" object:nil  queue:[NSOperationQueue mainQueue]                                                      usingBlock:^(NSNotification *notif) { 
    NSLog(@"ViewController动画结束");                                              
     }];
}
```

#### 5、线程操作（GCD/NSOperation）

在有关线程操作的GCD以及NSOperation中，也会使用到Block。例如，延迟执行方法。

```oc
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
       //延迟N秒后执行的代码
   });
```

## 补充

用__block修饰符修饰后的局部变量，已经不再是一个普通的局部变量了，而是一个__block变量。就是一个OC对象，因为它里面有isa指针，这个对象内部会有一个成员变量来存储之前那个普通局部变量的值，所以这就跟一个person对象里有一个age属性没啥区别，所以block捕获__block变量就像捕获指针变量一样是捕获地址了，此外它内部还有一个__forwarding指针指向它自己。 所以我们就能在block的执行体里（即block对应的函数体里）通过“block --> block捕获的__block变量地址 --> __block变量 --> __block变量内部的局部变量”这条路线来修改“外界的局部变量”的值了（其实根本就没有“外界的局部变量”这个东西，只是我们开发者看起来像是这样），类似于通过指针修改静态局部变量那种方式。
