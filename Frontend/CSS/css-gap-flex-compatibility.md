# CSS Gap 与 Flex Gap 兼容性

在现代前端布局中，`gap` 是一个非常常用的 CSS 属性，主要用于设置元素之间的间距。它可以用于 `grid`、`flex` 和多列布局中，本质上是 `row-gap` 和 `column-gap` 的简写。MDN 对 `gap` 的定义也是用于设置行与列之间的间隔。([MDN Web Docs][1])

不过在实际项目中，`gap` 最大的问题不是语法，而是**兼容性**。尤其是在移动端 WebView、iOS Safari、企业 App 内嵌页面中，`gap` 的表现需要分场景判断。

---

## 一、`gap` 在 Grid 和 Flex 中的兼容性不同

很多人容易忽略一点：虽然都是 `gap`，但它在 `grid` 和 `flex` 中的支持时间并不一样。

### Grid 中的 `gap`

```css
.grid {
  display: grid;
  gap: 12px;
}
```

`gap` 在 Grid 布局中的兼容性相对较好。Can I use 数据显示，Grid 场景下的 `gap` 在 Chrome 66+、Edge 16+、Safari 12+ 等版本中已经支持。([Can I use][2])

所以如果你的布局是 `display: grid`，通常不需要过度担心 `gap` 的兼容问题，除非你还要兼容 IE 或非常老的 WebView。

### Flex 中的 `gap`

```css
.flex {
  display: flex;
  gap: 12px;
}
```

Flex 场景下就不一样了。`gap` 在 Flexbox 中支持得更晚。Can I use 数据显示，Flex gap 在 Chrome 84+、Firefox 63+、Safari 14.1+ 开始支持；iOS Safari 则是 iOS 14.5+ 才支持。([Can I use][3])

这意味着，如果你的项目需要兼容：

```txt
iOS 13
iOS 14.0 - 14.4
老版本 Android WebView
企业内嵌浏览器
```

就不能直接依赖：

```css
display: flex;
gap: 12px;
```

否则间距可能完全不生效。

---

## 二、移动端 WebView 中的主要风险

在普通现代浏览器中，Flex gap 基本已经可以放心使用。但移动端项目，尤其是 App 内嵌 H5 页面，经常要兼容较低系统版本。

例如你的兼容基线如果是：

```txt
iOS >= 13
Android >= 6
```

那么 Flex gap 就存在明显风险。

原因是：

```css
.container {
  display: flex;
  gap: 12px;
}
```

在 iOS 13 和 iOS 14.4 及以下的 Safari / WKWebView 中不支持。Can I use 明确显示，iOS Safari 3.2 到 14.4 不支持 Flex gap，iOS 14.5 之后才支持。([Can I use][4])

所以在 iOS WebView 项目中，不能只看 Chrome 或现代桌面浏览器的表现。页面在 Chrome DevTools 中正常，不代表在老 iPhone 的 WKWebView 中正常。

---

## 三、不要简单依赖 `@supports`

有些人会写：

```css
@supports (gap: 12px) {
  .list {
    gap: 12px;
  }
}
```

这个判断并不可靠。

因为某些浏览器可能支持 Grid 的 `gap`，但不支持 Flex 的 `gap`。此时 `@supports (gap: 12px)` 可能返回 true，但实际在 `display: flex` 场景下，`gap` 仍然不生效。Safari 14.1 之前就存在这类典型问题：Grid gap 已经支持，但 Flex gap 还没有支持。([CSS-Tricks][5])

所以对于 Flex gap，单纯使用 `@supports (gap: 12px)` 不能完全解决兼容问题。

---

## 四、推荐的兼容写法

如果你的项目只面向现代浏览器，例如：

```txt
iOS >= 15
Android WebView Chrome >= 84
现代 Chrome / Edge / Firefox / Safari
```

可以直接使用：

```css
.list {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
```

但如果要兼容 iOS 13、iOS 14.4 及以下，建议使用 `margin` 模拟 `gap`。

### 方案一：横向间距

```css
.list {
  display: flex;
}

.list > * + * {
  margin-left: 12px;
}
```

适合单行横向布局，例如按钮组、tab、icon 列表。

缺点是只适合不换行的场景。

---

### 方案二：支持换行的 gap 模拟

```css
.list {
  display: flex;
  flex-wrap: wrap;
  margin-left: -12px;
  margin-top: -12px;
}

.list > * {
  margin-left: 12px;
  margin-top: 12px;
}
```

这个写法更适合多行布局，效果接近：

```css
.list {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
```

原理是：

父容器使用负 `margin` 抵消第一行和第一列的额外间距，子元素使用正 `margin` 产生元素之间的间隔。

---

## 五、实际项目中的建议

### 1. Grid 布局可以优先使用 `gap`

```css
.grid {
  display: grid;
  gap: 12px;
}
```

Grid 场景下兼容性较好，适合宫格、卡片列表、二维布局。

### 2. Flex 布局要看兼容基线

如果项目不需要支持老 iOS，可以直接使用：

```css
.flex {
  display: flex;
  gap: 12px;
}
```

如果项目需要支持 iOS 13 或 iOS 14.4 及以下，建议使用 margin fallback。

### 3. App 内嵌 H5 页面不要只看桌面浏览器

尤其是 iOS WKWebView，实际表现取决于系统版本，而不是 App 自身版本。即使 App 更新了，如果用户系统还停留在 iOS 13，Flex gap 仍然不支持。

### 4. 组件库中使用 `gap` 要谨慎

如果 UI 组件库内部用了：

```css
display: flex;
gap: 8px;
```

在老 iOS WebView 中可能出现按钮贴在一起、标签间距消失、列表布局异常等问题。

这种情况下可以通过覆盖样式处理：

```css
.button-group {
  display: flex;
}

.button-group > * + * {
  margin-left: 8px;
}
```

---

## 六、结论

`gap` 是一个很好用的 CSS 属性，但它的兼容性需要区分使用场景。

一句话总结：

> **Grid gap 兼容性较好，Flex gap 在老 iOS 和老 WebView 中存在明显兼容问题。**

如果你的项目是现代浏览器环境，可以放心使用 `flex + gap`。
如果你的项目需要兼容 iOS 13、iOS 14.4 及以下，或者运行在企业 App 内嵌 WebView 中，建议不要在核心布局里直接依赖 Flex gap，而是使用 `margin` 方案做降级处理。

[1]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/gap "gap CSS property - MDN Web Docs"
[2]: https://caniuse.com/?search=grid-gap "\"grid-gap\" | Can I use... Support tables for HTML5, CSS3, etc"
[3]: https://caniuse.com/flexbox-gap "gap property for Flexbox | Can I use... Support tables ..."
[4]: https://caniuse.com/?search=flexbox-gap "\"flexbox-gap\" | Can I use... Support tables for HTML5, ..."
[5]: https://css-tricks.com/safari-14-1-adds-support-for-flexbox-gaps/ "Safari 14.1 Adds Support for Flexbox Gaps"
