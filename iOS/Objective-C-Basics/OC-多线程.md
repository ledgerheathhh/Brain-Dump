# 多线程

对于任意一个iOS应用，程序运行起来后，默认会产生一个主线程（MainThread），主线程专门用来处理UIKit对象的操作，如界面的显示与更新、处理用户交互事件等等。（所有与UI相关的操作都要在主线程中进行）

对于一个App应用来说，之所以需要引入多个线程，很大程度上是由于存在一些操作是非常耗时的，例如：发送网络请求并等待服务器的响应，这种耗时操作是不能够放在主线程中进行操作的，因为在等待的时间内，主线程被使用，用户是不能做任何交互动作的，因而会极大影响用户体验。对于耗时的操作，需要再另外创建一个线程，放到后台处理，当处理完成得到结果后，再返回主线程去设置UI界面，这就涉及到线程间通信的相关知识。

多线程同时处理任务，还会涉及到线程安全（thread-safe）的问题，当多个线程对一个对象进行同时操作时，就会影响结果的正确性。因此，线程对某个对象操作时，需要使用到“锁”的机制，即当一个线程操作一个对象的过程中，会给这个对象上锁，其他线程就不能够访问该对象了。加锁虽然解决了线程安全的问题，但带来的另外一个弊端就是影响了程序运行的效率。

当我们给一个自定义类中添加属性的时候，属性关键字其中就有：atomic和nonatomic的区分。`atomic` 是默认值，它保证属性 getter/setter 本身的原子性，但不等于对象整体线程安全，也不能保证“读取后再修改”这类复合操作的正确性。实际开发中通常使用 `nonatomic`，再根据业务使用串行队列、锁、不可变对象或 actor/operation 等方式处理真正的线程安全问题。

## NSThread类

NSThread类是苹果提供的管理线程的类，提供了一些线程管理的方法。但是随着GCD和NSOperation的推出，NSThread的使用场景已经大大减少。在实际的开发中，偶尔会使用NSThread类来获取一些线程信息。常用的一些方法如下：

* 获取当前线程对象

```objectivec
+ (NSThread *)currentThread; 
```

* 获取主线程对象

```objectivec
+ (NSThread *)mainThread;
```

* 使当前线程休眠ti秒

```objectivec
+ (void)sleepForTimeInterval:(NSTimeInterval)ti; 
```

## GCD(Grand Central Dispatch)

GCD是苹果推出的专门用于简化多线程编程的技术。在GCD中，程序员已经不再需要去关心有关线程的操作（如：线程创建、线程销毁、线程调度），而是引入了任务和队列两个核心概念。由于GCD是苹果推出的技术，因此GCD能够很好的调度苹果设备的CPU资源，不论是在Mac平台，还是在iOS平台。特别是iPhone中引入多核CPU之后，GCD的使用就变得越发重要。

由于GCD对线程管理进行了封装，因此，当工程师使用GCD时，只需要把任务（通常封装在一个block中）添加到一个队列中执行，有关线程调度的工作，完全交由GCD完成。

在使用GCD处理多任务执行时，只要按照如下步骤执行即可，

* 在block中定义需要执行的任务内容；
* 把任务添加到队列queue中

GCD对队列中的任务，按照“先进先出”的原则，根据任务添加到队列的顺序来对队列进行处理，GCD会根据任务和队列的类型，自动在多个线程之间分配工作。

#### 任务

在GCD中，需要处理的事务统一使用block封装起来，称为任务。任务有两种类型，同步任务和异步任务。我们通过调用不同的函数，来设置任务的类型。同时，任务编写在函数的block参数中。

* 异步任务：执行任务时，会在另外的线程中执行，即可能会创建新的线程；

```objectivec
dispatch_async(dispatch_queue_t queue, dispatch_block_t block); 
```

* 同步任务：执行任务时，会在当前的线程中执行，当前线程有可能是主线程，也有可能是子线程。

```objectivec
dispatch_sync(dispatch_queue_t queue, dispatch_block_t block); 
```

#### 队列

GCD中，队列是一个重要概念。系统提供了若干预定义的队列，其中包括可以获取应用程序的主队列（任务始终在主线程上执行，与更新UI相关的操作**必须**在主队列中完成）。另外，工程师可以自由创建不同类型的队列，例如：并行队列和串行队列，队列的类型决定了任务的执行方式。GCD队列严格按照“先进先出”的原则，添加到GCD队列中的任务，始终会按照加入队列的顺序被执行。

* **并行队列** ：并行队列中的任务可以在多个线程之间分配执行，分配的原则由GCD控制，因此，并行队列中的任务，虽然分配执行时按照先进先出进行分配的，但由于各个任务被分配到不同的线程执行，因此其**完成时间**有可能不同，即：后分配的任务有可能先执行完成；并发队列一定需要和异步执行的任务(使用dispatch_async())结合起来使用才有意义。
* **串行队列** ：串行队列中的任务是按照顺序一个一个完成的，当一个任务完成后，才去执行下一个任务；因此，串行队列对应一个线程执行。
* **主队列** ：主队列也是一个串行队列，主队列中的任务都在主线程中执行。

程序员可以通过如下的函数来创建不同类型的队列。

* 获取系统定义的并行队列，一般来说，开发中通常不需要自己创建并行队列，使用系统提供的即可

```objectivec
dispatch_get_global_queue(long identifier, unsigned long flags);
```

* 创建队列。可以创建并行队列，也可以创建串行队列。该方法常用于创建串行队列。

```objectivec
dispatch_queue_create(const char *label, dispatch_queue_attr_t attr);
```

* 获取主队列

```objectivec
dispatch_get_main_queue(void); 
```

#### 1、异步任务+并行队列

把异步任务放到并行队列进行执行，异步任务会在不同的线程中执行，这是最常使用的一种组合。

```objectivec
    //获取并行队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);  
    //创建异步任务，并放到并行队列中执行
    dispatch_async(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task1:%d",i);
        }
        NSLog(@"task1----%@",[NSThread currentThread]);
    });  
    dispatch_async(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task2:%d",i);
        }
        NSLog(@"task2----%@",[NSThread currentThread]);
    });  
    dispatch_async(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task3:%d",i);
        }
        NSLog(@"task3----%@",[NSThread currentThread]);
    });   
```

#### 2、异步任务+串行队列

对于异步任务放在串行队列中执行时，任务只会在一个新开的线程中，按照顺序进行执行。

```objectivec
    //创建串行队列
    dispatch_queue_t queue = dispatch_queue_create("test", NULL); 
    //创建异步任务
    dispatch_async(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task1:%d",i);
        }
        NSLog(@"task1----%@",[NSThread currentThread]);
    });  
    dispatch_async(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task2:%d",i);
        }
        NSLog(@"task2----%@",[NSThread currentThread]);
    });   
    dispatch_async(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task3:%d",i);
        }
        NSLog(@"task3----%@",[NSThread currentThread]);
    });
```

#### 3、异步任务+主队列

把异步任务放在主队列中执行，由于主队列是一个特殊的串行队列，因此任务是串行执行的，但由于主队列对应序号为1的线程，因此，即便是异步任务，也不会再创建新的线程。

```objectivec
    //获取主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    //创建异步任务
    dispatch_async(mainQueue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task1:%d",i);
        }
        NSLog(@"task1----%@",[NSThread currentThread]);
    });
    dispatch_async(mainQueue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task2:%d",i);
        }
        NSLog(@"task2----%@",[NSThread currentThread]);
    });
    dispatch_async(mainQueue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task3:%d",i);
        }
        NSLog(@"task3----%@",[NSThread currentThread]);
    });
```

#### 4、同步任务+并行队列

同步任务的执行是在当前线程中完成的，因此，即便是把同步任务放在并行队列中执行，由于只有1个线程，任务也是一个一个按顺序执行的(串行执行)。

```objectivec
    //获取并行队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //同步执行
    dispatch_sync(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task1:%d",i);
        }
        NSLog(@"task1----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task2:%d",i);
        }
        NSLog(@"task2----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task3:%d",i);
        }
        NSLog(@"task3----%@",[NSThread currentThread]);
    });
```

#### 5、同步任务+串行队列

同步任务放在串行队列中执行，任务会在当前线程依次执行。

```objectivec
    //创建串行队列
    dispatch_queue_t queue = dispatch_queue_create("com.99ios", NULL);
    //同步执行
    dispatch_sync(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task1:%d",i);
        }
        NSLog(@"task1----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task2:%d",i);
        }
        NSLog(@"task2----%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task3:%d",i);
        }
        NSLog(@"task3----%@",[NSThread currentThread]);
    });
```

#### 6、同步任务+主队列

如果在主线程中对主队列调用 `dispatch_sync`，主线程会等待主队列中的 block 执行，而主队列又必须等当前主线程空闲后才能执行该 block，因此会产生死锁。这个组合不是绝对不能用，但不能从主线程同步派发到主队列。

```objectivec
    //获取主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue(); 
    //同步执行
    //1
    dispatch_sync(mainQueue, ^{ //block 1
        for (int i = 0; i<2; i++) {
            NSLog(@"task1:%d",i);
        }
        NSLog(@"task1----%@",[NSThread currentThread]);
    });
    //2
    dispatch_sync(mainQueue, ^{
        for (int i = 0; i<2; i++) {
            NSLog(@"task2:%d",i);
        }
        NSLog(@"task2----%@",[NSThread currentThread]);
    });
    //3
    dispatch_sync(mainQueue, ^{ 
        for (int i = 0; i<2; i++) {
            NSLog(@"task3:%d",i);
        }
        NSLog(@"task3----%@",[NSThread currentThread]);
    });
```

#### 队列组dispatch group

> 在使用GCD进行任务操作时，有时会希望若干个任务执行之间有先后执行的依赖关系，例如，当A、B两个异步任务完成后，再去完成C任务，这时就可以使用队列组dispatch group来完成。

在串行队列中，任务是按照进入队列的顺序依次执行，因此任务和任务之间是有明确的先后顺序的。但是对于并行队列的任务来说，由于任务会被自动分配到不同的线程中执行，因此任务完成的顺序是不确定的。假如希望给并行队列中的任务设置执行顺序，例如，当任务A和任务B完成后，再去完成任务C，就需要使用到任务组dispatch group。

在GCD中，苹果官方为我们提供了如下一些有关队列组操作的函数。

* 创建队列组

```objectivec
dispatch_group_t dispatch_group_create(void);
```

* 向队列组中插入一个异步任务

```objectivec
void dispatch_group_async( dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block); 
```

* 队列组中其他任务执行完成后，执行的任务，通常可以用来设置UI界面

```objectivec
void dispatch_group_notify( dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block); 
```

#### GCD 延时执行方法：dispatch_after

在GCD中可以使用dispatch_after()函数，封装一段代码到block中，在设置的延迟时间**dispatch_time_t**之后执行。

```objectivec
void dispatch_after( dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block);
```

如下所示：在2.0秒后，输出一段日志。在该方法中，延迟执行的代码在主队列中执行，我们也可以修改执行的队列。

```objectivec
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"延迟2.0秒后打印出来的日志！");
    });
```

#### GCD 一次性代码（只执行一次）：dispatch_once

我们在创建单例、或者有整个程序运行过程中只执行一次的代码时，我们就用到了 GCD 的 `dispatch_once` 方法。

使用 `dispatch_once` 方法能保证某段代码在程序运行过程中只被执行 1 次，并且即使在多线程的环境下，`dispatch_once` 也可以保证线程安全。

```objectivec
- (void)once {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 只执行 1 次的代码（这里面默认是线程安全的）
    });
}
```

#### dispatch_group_wait

暂停当前线程（阻塞当前线程），等待指定的 group 中的任务执行完成后，才会往下继续执行。

## NSOperation

由于NSOperation是一个抽象类，因此不能够直接使用NSOperation，但苹果提供了两个NSOperation的子类，NSBlockOperation和NSInvocationOperation，除此之外，我们还可以使用自定义CustomOperation类。

对于NSBlockOperation类来讲，可以把任务封装在一个block块之内。NSBlockOperation类提供了如下操作方法。

* 创建一个NSBlockOperation对象，任务封装在block中

```objectivec
+ (instancetype)blockOperationWithBlock:(void (^)(void))block;
```

对于NSInvocationOperation类来说，需要执行的任务直接指定已定义的方法。

```objectivec
- (nullable instancetype)initWithTarget:(id)target selector:(SEL)sel object:(nullable id)arg;
```

### 无队列情况下执行任务

在不创建队列的情况下，可以直接调用NSOperation类的start方法来执行某个任务。该任务是在当前线程进行执行的，如果是在主线程调用的start方法，那么则会在主线程中执行任务。

下方的示例代码中，在当前线程中**串行**执行两个任务。

```objectivec
/*
 调用operation的start方法，在当前线程中串行执行，无队列
 */
-(void) executeInCurrentThread {
    NSBlockOperation *task1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task1-----%@", [NSThread currentThread]);
    }]; 
    NSBlockOperation *task2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task2-----%@", [NSThread currentThread]);  
    }]; 
    //调用start方法，会在当前线程中串行执行
    [task1 start];
    [task2 start];  
}
```

### 在队列中执行任务

当把任务放到队列（NSOperationQueue类）中进行执行时，系统会自动**并行**执行所有任务，对于开多少条线程之类的事务，完全交由系统处理，开发者只要把任务添加到队列中即可。另外，可以通过设置队列的**maxConcurrentOperationCount**属性，来设置并行执行任务的数量。

下方的示例代码中，在一个队列中插入了5个任务，这5个任务并行执行。系统会同时开启多个线程，多个任务并行执行。另外，maxConcurrentOperationCount决定了“并发”任务的数量，而不是创建线程的数量。即便设置为1，不同的任务也有可能在不同的线程中执行

```objectivec
-(void) executeInQueue {
    NSBlockOperation *task1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task1-----%@", [NSThread currentThread]);
    }];  
    NSBlockOperation *task2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task2-----%@", [NSThread currentThread]);   
    }];   
    NSBlockOperation *task3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task3-----%@", [NSThread currentThread]);  
    }];  
    NSBlockOperation *task4 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task4-----%@", [NSThread currentThread]);  
    }];
        NSBlockOperation *task5 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task5-----%@", [NSThread currentThread]);  
    }];
    //创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    //设置队列属性
    queue.maxConcurrentOperationCount = 5;   
    //添加任务到队列
    [queue addOperation:task1];
    [queue addOperation:task2];
    [queue addOperation:task3];
    [queue addOperation:task4];
    [queue addOperation:task5];
}
```

### 在任务中添加新任务

通过调用NSOperation类的addExecutionBlock方法，可以为某个NSOperation对象增加额外的任务。当把这些新增的任务放到队列中执行时，也是并行执行的。

```objectivec
- (void)addExecutionBlock:(void (^)(void))block; 
```

下方的示例代码中在任务中添加新任务，所有的任务都会并行执行。

```objectivec
-(void) addTaskInOperation {
    NSBlockOperation *task1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task1-----%@", [NSThread currentThread]);
    }];   
    NSBlockOperation *task2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task2-----%@", [NSThread currentThread]);   
    }];  
    //task1中添加task
    [task1 addExecutionBlock:^{
        NSLog(@"task1 add task-----%@", [NSThread currentThread]);
    }];  
    //task2中添加task
    [task2 addExecutionBlock:^{
        NSLog(@"task2 add task-----%@", [NSThread currentThread]);
    }];  
    //创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];  
    //添加任务到队列
    [queue addOperation:task1];
    [queue addOperation:task2]; 
}
```

### 在队列中直接添加任务

```objectivec
//在queue中添加任务
    [queue addOperationWithBlock:^{
        NSLog(@"queue task-----%@", [NSThread currentThread]);
    }];  
```

### 在任务中创建completionBlock

在NSOperation类中，可以通过设置completionBlock来创建所有任务执行完成后，自动调用的一个block块。该block的执行是在任务执行后被调用的，有 **先后顺序** 。

```objectivec
/*
 可以给任务Operation结束后添加block，但是block中的任务会在新的线程中执行，即：仅仅是添加了一个任务执行的先后顺序关系
 */
-(void) addCompletionBlock {
    NSBlockOperation *task1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task1-----%@", [NSThread currentThread]);
    }];  
    NSBlockOperation *task2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task2-----%@", [NSThread currentThread]);   
    }];   
    //task1中添加task
    [task1 addExecutionBlock:^{
        NSLog(@"task1 add task-----%@", [NSThread currentThread]);
    }];  
    task1.completionBlock = ^{
        NSLog(@"task1 end!!! %@", [NSThread currentThread]);
    };  
    //task2中添加task
    [task2 addExecutionBlock:^{
        NSLog(@"task2 add task-----%@", [NSThread currentThread]);
    }];  
    task2.completionBlock = ^{
        NSLog(@"task2 end!!! %@", [NSThread currentThread]);
    };  
    //创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];  
    //添加任务到队列
    [queue addOperation:task1];
    [queue addOperation:task2];
} 
```

### NSOperation：3-任务间的执行依赖

> 在GCD中可以使用队列组来设置任务之间的依赖关系，而在NSOperation中则提供了更加方便直观的方式来设置任务执行的先后顺序关系。通过NSOperation类中的**addDependency**方法，即可添加任务之间的依赖关系。由于addDependency是NSOperation类中的方法，与队列无关，因此也可以针对不同队列中的任务设置任务执行的先后依赖关系。

```objectivec
//设置任务之间的执行依赖关系
[task3 addDependency:task1];
[task3 addDependency:task2];
[task2 addDependency:task1];  
```

### NSOperation与GCD的区别

* GCD是底层的C语言构成的API，而NSOperationQueue及相关对象是Objective-C的对象。在GCD中，在队列中执行的是由block构成的任务，这是一个轻量级的数据结构；而NSOperation作为一个对象，为我们提供了更多的选择；
* 在NSOperationQueue中，我们可以随时取消已经设定要准备执行的任务(已经开始的任务无法阻止)，而GCD没法停止已经加入queue的block(其实是有的，但需要许多复杂的代码)；
* NSOperation能够方便地设置依赖关系，我们可以让一个Operation依赖于另一个Operation，这样的话尽管两个Operation处于同一个并行队列中，但前者会直到后者执行完毕后再执行；
* 我们能将KVO应用在NSOperation中，可以监听一个Operation是否完成或取消，这样能比GCD更加有效地掌控我们执行的后台任务；
* 在NSOperation中，我们能够设置NSOperation的priority优先级，能够使同一个并行队列中的任务区分先后地执行，而在GCD中，我们只能区分不同任务队列的优先级，如果要区分block任务的优先级，也需要大量的复杂代码；
* 我们能够对NSOperation进行继承，在这之上添加成员变量与成员方法，提高整个代码的复用度，这比简单地将block任务排入执行队列更有自由度，能够在其之上添加更多自定制的功能。
