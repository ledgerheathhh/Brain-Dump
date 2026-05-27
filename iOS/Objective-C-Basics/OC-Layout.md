# Auto Layout

在苹果推出iPhone5之前，苹果的屏幕分辨率只有一种，因此对于iOS开发者来说，是不需要像Android工程师一样去考虑屏幕适配问题的。但随着iPhone5的发布，iPhone的屏幕出现了3.5寸和4.0寸两种尺寸，这种情况下，仍然可以分别为两种尺寸编写各自的界面布局样式，但随着iPhone6以及iPhone6 Plus的发布，iPhone的屏幕尺寸变为4种，考虑到还存在横屏以及竖屏两种展示方式，此时就不能够再为每一种屏幕尺寸来编写单独的布局样式了。而苹果为多屏幕适配提供的解决方案就是自动布局(Auto Layout)。

#### Auto Layout的工作原理

在Auto Layout中的基本工具就是约束(constraint)，一个约束描述了两个视图之间的关系。Auto Layout会根据视图的约束自动计算视图的位置和大小。比如，设置一个按钮的顶部距离一个图片视图（UIImageView)的底部距离为8px。那么一旦图片视图（UIImageView)的位置发生了改变，按钮的位置也会随之发生改变。这种基于约束的设计方法允许你根据内部或者外部约束来动态的构建用户界面。

Auto Layout考虑所有约束，然后通过数学计算来最终确定视图的位置和大小。这些计算都是由Auto Layout来帮我们做的，我们要做的仅仅是设置约束。当我们为一个控件设置的约束不足以确定其大小和位置时，Auto Layout会给我们相关的提示。

另外，当我们为一个控件设置其约束后，不论是横屏还是竖屏状态下，我们都能够确定该控件的位置和大小。

### iOS开发中的Auto Layout详解（使用Objective-C）

Auto Layout是iOS开发中一个强大的基于约束的布局系统，它允许开发者创建动态和自适应的用户界面。Auto Layout会根据约束自动计算视图层次结构中所有视图的大小和位置。

#### Auto Layout的关键概念

1. **视图和子视图**：

   - **UIView**：所有UI元素的构建块。
   - **子视图（Subviews）**：添加到另一个视图（父视图）中的视图。
2. **约束（Constraints）**：

   - 约束定义了布局中不同视图之间的关系。
   - 约束可以指定视图的宽度、高度以及相对于其他视图或其父视图的位置。
3. **固有内容大小（Intrinsic Content Size）**：

   - 一些视图（如UILabel和UIButton）具有固有内容大小，Auto Layout会根据它们的内容来确定其大小。
4. **不明确性和冲突**：

   - 不明确性：当Auto Layout不能唯一确定视图的大小和位置时，就会出现不明确性。
   - 冲突：当多个约束之间相互矛盾时，就会出现冲突。

#### Auto Layout的基本用法

##### 使用代码添加约束

在Objective-C中，可以通过代码来添加约束。通常会使用NSLayoutConstraint类来创建约束，并将其添加到视图中。以下是一个基本的例子：

```objectivec
UIView *superview = self.view;
UIView *subview = [[UIView alloc] init];
subview.translatesAutoresizingMaskIntoConstraints = NO;
[subview setBackgroundColor:[UIColor redColor]];
[superview addSubview:subview];

// 添加约束
[NSLayoutConstraint activateConstraints:@[
    [subview.leadingAnchor constraintEqualToAnchor:superview.leadingAnchor constant:20],
    [subview.trailingAnchor constraintEqualToAnchor:superview.trailingAnchor constant:-20],
    [subview.topAnchor constraintEqualToAnchor:superview.topAnchor constant:20],
    [subview.bottomAnchor constraintEqualToAnchor:superview.bottomAnchor constant:-20]
]];
```

##### 通过Storyboard或XIB文件添加约束

在Interface Builder中，可以通过拖拽和设置属性来添加和管理约束。

1. **选中视图**：在Storyboard或XIB中选中需要设置约束的视图。
2. **添加约束**：点击底部的“Add New Constraints”按钮，选择需要添加的约束类型（如宽度、高度、间距等）。
3. **调整优先级和常量**：设置约束的优先级和常量值，以确保布局的正确性。

##### 更新和移除约束

可以随时更新或移除约束以适应动态布局的需要。

**更新约束**：

```objectivec
[NSLayoutConstraint deactivateConstraints:self.currentConstraints];
self.currentConstraints = @[newConstraint1, newConstraint2];
[NSLayoutConstraint activateConstraints:self.currentConstraints];
```

**移除约束**：

```objectivec
[NSLayoutConstraint deactivateConstraints:@[oldConstraint]];
```

##### 优先级和抗拉伸/抗压缩

- **优先级（Priority）**：每个约束都有一个优先级，范围是1到1000，1000表示必需的约束。
- **抗拉伸/抗压缩（Content Hugging/Compression Resistance）**：用于控制视图在受到拉伸或压缩时的行为。

```objectivec
[view setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
[view setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
```

#### Auto Layout调试

1. **使用Debug视图层级结构**：在Xcode中运行应用，使用Debug视图层级结构查看和调试视图布局。
2. **打印约束**：可以在控制台中打印视图的当前约束，以帮助调试布局问题。

```objectivec
NSLog(@"%@", view.constraints);
```

3. **解决冲突**：当出现布局冲突时，Xcode会在控制台输出详细的冲突信息，帮助定位和解决问题。

通过掌握以上Auto Layout的基本概念和用法，可以创建适应不同屏幕尺寸和方向变化的用户界面，从而提升应用的用户体验。

# Masonry

Masonry是一个流行的第三方库，用于在iOS应用开发中简化Auto Layout的实现。它采用链式语法，使得创建和更新约束更加直观和便捷。以下是关于Masonry的详细介绍及全面的笔记。

### 1. Masonry简介

Masonry 是一个轻量级的布局框架，主要用于简化Auto Layout的代码。它通过使用链式语法，使得开发者可以更容易地添加和修改视图的约束。

### 2. 安装Masonry

Masonry可以通过CocoaPods安装，以下是步骤：

1. 打开 `Podfile`，添加以下内容：
   ```ruby
   pod 'Masonry'
   ```
2. 运行以下命令：
   ```sh
   pod install
   ```

### 3. 基本用法

#### 3.1 创建约束

使用Masonry来创建约束非常简单。以下是一个例子：

```objc
#import "Masonry.h"

UIView *superview = self.view;
UIView *box = [[UIView alloc] init];
box.backgroundColor = [UIColor redColor];
[superview addSubview:box];

[box mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(superview);
    make.size.mas_equalTo(CGSizeMake(100, 100));
}];
```

在这个例子中，`box`视图被添加到 `superview`中，并被设置为居中，大小为100x100。

#### 3.2 更新约束

更新约束同样简单。可以通过保持对约束的引用来更新它们，或者直接在约束block中进行更新：

```objc
[box mas_updateConstraints:^(MASConstraintMaker *make) {
    make.size.mas_equalTo(CGSizeMake(150, 150));
}];
```

#### 3.3 重新制作约束

如果需要移除并重新创建约束，可以使用 `mas_remakeConstraints`方法：

```objc
[box mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(superview);
    make.size.mas_equalTo(CGSizeMake(200, 200));
}];
```

### 4. 高级用法

#### 4.1 约束优先级

可以为约束设置优先级：

```objc
[box mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(superview.mas_left).with.offset(10).priorityLow();
    make.right.equalTo(superview.mas_right).with.offset(-10).priorityHigh();
    make.top.equalTo(superview.mas_top).with.offset(10).priority(750);
}];
```

#### 4.2 使用Insets

设置边距（insets）也非常方便：

```objc
[box mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(superview).insets(UIEdgeInsetsMake(10, 10, 10, 10));
}];
```

#### 4.3 使用倍数和偏移量

可以使用倍数（multiplier）和偏移量（offset）来设置约束：

```objc
[box mas_makeConstraints:^(MASConstraintMaker *make) {
    make.width.equalTo(superview.mas_width).multipliedBy(0.5);
    make.height.equalTo(@100);
    make.center.equalTo(superview).centerOffset(CGPointMake(10, 10));
}];
```

### 5. 示例项目

以下是一个完整的示例项目，展示了Masonry的基本用法和高级用法。

```objc
#import "ViewController.h"
#import "Masonry.h"

@interface ViewController ()
@property (nonatomic, strong) UIView *box1;
@property (nonatomic, strong) UIView *box2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    self.box1 = [[UIView alloc] init];
    self.box1.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.box1];
  
    self.box2 = [[UIView alloc] init];
    self.box2.backgroundColor = [UIColor blueColor];
    [self.view addSubview:self.box2];
  
    [self setupConstraints];
}

- (void)setupConstraints {
    [self.box1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(100, 100));
    }];
  
    [self.box2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.box1);
        make.top.equalTo(self.box1.mas_bottom).with.offset(20);
        make.size.mas_equalTo(CGSizeMake(100, 100));
    }];
}

@end
```

### 6. 总结

Masonry是一个非常强大的Auto Layout工具，可以极大地简化约束的创建和管理。通过链式语法，开发者可以更加直观地设置视图的约束，提升开发效率和代码可读性。

#### 常用方法总结

- `mas_makeConstraints`: 创建约束
- `mas_updateConstraints`: 更新约束
- `mas_remakeConstraints`: 重新制作约束
- `equalTo`: 设置等于关系
- `mas_equalTo`: 设置等于值
- `priority`: 设置优先级
- `insets`: 设置边距
- `multipliedBy`: 设置倍数
- `offset`: 设置偏移量
