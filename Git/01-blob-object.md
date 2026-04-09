# 01 Blob Object

Git 的对象模型从 blob 开始。理解 blob，后面的 tree、commit 和 packfile 才容易串起来。

## 为什么 Git 需要 Blob

Git 不是直接按“文件名 -> 文件内容”保存数据，而是先把内容写成对象，再用对象 ID 组织目录和提交历史。这种方式叫内容寻址。

在传统仓库里，这个对象 ID 默认来自 SHA-1；在较新的仓库格式里也可以使用 SHA-256。无论底层算法是哪一种，核心思路都一样：对象 ID 由对象内容决定。

blob 的职责很单一：保存一段文件内容。

## Blob 到底存了什么

blob 只存文件字节本身，不存下面这些信息：

- 文件名
- 所在目录
- 文件模式
- 属于哪个提交或分支

这些信息由更上层的对象记录：

- tree 记录目录项、名字和模式
- commit 记录某次快照与父提交

这意味着下面两个路径如果内容相同，Git 可以复用同一个 blob：

```text
docs/hello.txt -> Hello
tmp/copy.txt   -> Hello
```

变的是 tree 里的目录项，不是 blob 本身。

## Git 如何为内容生成 Blob

Git 计算 blob 的对象 ID 时，哈希的不是“原始文件内容”本身，而是带对象头的这段数据：

```text
blob <size>\0<content>
```

例如 `Hello Git` 的字节数是 9，那么参与哈希的是：

```text
blob 9\0Hello Git
```

这点很重要，因为对象类型和长度都是对象身份的一部分。同样的正文，如果换成别的对象类型，得到的对象 ID 也不同。

可以用最小命令观察这个过程：

```bash
oid=$(printf 'Hello Git' | git hash-object -w --stdin)
git cat-file -t "$oid"
git cat-file -p "$oid"
```

你会看到：

- `git hash-object -w` 把内容写成对象
- `git cat-file -t` 输出对象类型 `blob`
- `git cat-file -p` 输出原始文件内容 `Hello Git`

`git add` 在把内容写入暂存区时也会生成 blob，只是平时你不一定直接看到这个过程。

## Loose Object 如何存放在 .git/objects

新写入的对象通常先以 loose object 的形式落到 `.git/objects` 目录下。

如果对象 ID 是：

```text
e965047ad7c57865823c7d992b1d046ea66edf78
```

对应路径会是：

```text
.git/objects/e9/65047ad7c57865823c7d992b1d046ea66edf78
```

规则很简单：

- 前 2 位十六进制字符作为目录名
- 剩余字符作为文件名

对象文件本身会经过 zlib 压缩，所以磁盘上存的不是纯文本。之后如果仓库做垃圾回收或重打包，这些 loose objects 还可能被收进 packfile，但逻辑上的 blob 身份不会变。

## 常见误解

- “blob 记录了文件路径。” 不对。路径和文件名由 tree 记录。
- “对象 ID 只对文件正文做哈希。” 不对。对象头 `blob <size>\0` 也参与计算。
- “文件改名一定会生成新 blob。” 不对。只改名不改内容时，通常变的是 tree。
- “只有 `git add` 才会生成 blob。” 不对。`git hash-object -w` 也能直接写对象。

## 小结

blob 是 Git 对文件内容的最小存储单元：它只关心内容，不关心名字；它先以 loose object 的形式写入对象库，再被 tree 和 commit 组织成可追踪的历史。
