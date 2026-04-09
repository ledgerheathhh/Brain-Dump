# 03 Packfile

理解了 blob、tree、commit 和 tag 之后，还差最后一层：Git 在逻辑上是对象数据库，但在物理存储和网络传输上，不会一直把对象拆成海量小文件。packfile 就是这层优化。

## 为什么 Loose Object 不够

新对象通常先写成 loose object，这对 `git add` 和 `git commit` 很方便：写入简单，定位直接。

但如果仓库很大，长期保留海量 loose objects 会带来问题：

- 小文件太多，文件系统开销高
- 相似对象重复存储，压缩率不高
- `clone` 和 `fetch` 传输大量零散对象效率差

所以 Git 会把对象重新组织成 packfile。

## Packfile 是什么

packfile 是 Git 的一种存储和传输表示，不是新的逻辑对象类型。

它打包的仍然是同一批对象：

- blob
- tree
- commit
- tag

常见文件是成对出现的：

| 文件 | 作用 |
| --- | --- |
| `.pack` | 存放对象数据和 delta 编码结果 |
| `.idx` | 按对象 ID 建立索引，帮助快速定位 `.pack` 中的偏移 |

常见位置：

```text
.git/objects/pack/
  pack-xxxx.pack
  pack-xxxx.idx
```

理解这一点很关键：packfile 改变的是对象的物理存放方式，不是 Git 的对象模型。

## Git 如何把对象打包

本地仓库常见的打包入口有：

- `git gc`
- `git repack`
- 后台维护任务

远程交互时，服务器也会在 `git clone` 和 `git fetch` 过程中生成或发送 pack 数据。

因此可以把两种表示方式分开看：

- loose object 适合增量写入
- packed object 适合批量存储和传输

同一个仓库里，这两种形式可以同时存在。

## Delta Compression 如何工作

packfile 的重要优化之一是 delta compression。它不会为每个相似对象都保存一份完整内容，而是尽量记录“在某个基础对象上做了哪些变化”。

例如：

```text
A: Hello Git World
B: Hello Git World!!!
```

在逻辑上它们仍然是两个独立对象；但在 packfile 里，Git 可能保存为：

```text
base  -> A
delta -> 从 A 变到 B 的差异
```

恢复读取时，Git 会把 base 和 delta 重新还原成完整对象。

packfile 里常见的 delta 编码类型有：

- `OFS_DELTA`：基于 pack 内偏移
- `REF_DELTA`：基于对象 ID 引用基础对象

这些都是 pack 内部的编码细节，不是新增的 Git 顶层对象类型。

## 什么时候会看到 Packfile

几个常见场景：

- 运行 `git gc` 后，很多 loose objects 会被收进 pack
- 执行 `git clone` 时，服务端通常发送 pack 数据
- 执行 `git fetch` 时，新对象也常以 pack 形式传输

如果想看 pack 索引里的对象概况，可以用：

```bash
git verify-pack -v .git/objects/pack/pack-*.idx
```

输出里你会看到普通对象以及 delta 条目，但它们最终仍然会被 Git 还原成熟悉的 blob、tree、commit 或 tag。

## 常见误解

- “packfile 会替代 blob/tree/commit/tag。” 不对。它只是这些对象的打包表示。
- “Git clone 是把所有版本的文件逐个拷贝过来。” 不对。通常传输的是 pack 数据，然后在本地展开对象库。
- “`git gc` 会改变提交历史。” 一般不会。它主要整理和压缩对象存储。
- “只要进了 pack，就不能再按对象读取。” 不对。`.idx` 就是为了帮助 Git 继续按对象 ID 定位数据。

## 小结

如果说 blob、tree、commit 和 tag 解释了 Git “逻辑上保存什么”，那么 packfile 解释的就是 Git “物理上怎么高效保存和传输”。它没有改变对象模型，只是让同一套对象在大仓库和网络场景下更高效。
