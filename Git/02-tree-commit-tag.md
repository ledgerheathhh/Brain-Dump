# 02 Tree Commit Tag

有了 blob 之后，Git 仍然不知道“这个内容属于哪个文件名、哪个目录、哪一次提交”。tree、commit 和 tag 就是把这些对象组织起来的关键层。

## 为什么只有 Blob 还不够

如果只有 blob，Git 只能知道“仓库里有这些内容”，但还不知道：

- 这些内容在目录树里的位置
- 哪些内容组成了一次完整快照
- 哪些快照先后相连
- 哪些对象被人类可读的名字标记出来

所以 Git 需要再引入 tree、commit 和 tag。

## Tree 如何组织目录项

tree 表示一个目录。它记录的是一组目录项，每一项至少包含：

- mode
- name
- 指向的对象 ID

常见的被引用对象是 blob 和子 tree，因此 tree 可以递归地表示整棵目录树。

用 `git cat-file -p <tree-oid>` 查看时，常见输出类似：

```text
100644 blob a1b2c3... README.md
040000 tree d4e5f6... src
```

可以这样理解：

- `100644` 表示普通文件
- `040000` 表示子目录
- `README.md` 和 `src` 是目录项名字
- 后面的对象 ID 指向具体的 blob 或 tree

tree 不是“文本版目录列表”，而是 Git 用来描述目录结构的对象格式。文件名、模式和对象引用都在这里，而不是在 blob 里。

## Commit 真正记录了什么

commit 记录一次仓库快照的元数据。它至少会包含：

- 一个 tree
- 零个或多个 parent
- author / committer
- 提交说明

用 `git cat-file -p <commit-oid>` 查看时，常见结构类似：

```text
tree 9fceb02...
parent 3e1f0a2...
author Alice <alice@example.com> ...
committer Alice <alice@example.com> ...

Fix bug
```

关键点有两个：

- commit 指向的是 tree，不是直接指向每个文件
- parent 可以有多个，所以提交历史不是单链表，而是 DAG

常见情况：

- 根提交没有 parent
- 普通提交有 1 个 parent
- 合并提交有 2 个或更多 parent

## Tag、轻量标签与附注标签

“tag” 这个词在 Git 里容易混用，最好拆开看。

| 概念 | 实际含义 |
| --- | --- |
| tag 名称 / tag ref | `refs/tags/<name>` 这个引用 |
| lightweight tag | 一个直接指向目标对象的引用 |
| annotated tag | 一个先指向 tag object，再由 tag object 指向目标对象的引用 |
| tag object | 一种真正的 Git 对象，保存被标记对象、类型、tagger 和说明 |

最常见的目标对象是 commit，所以我们平时常说“给某次提交打 tag”。但模型本身并不只限于 commit，tag 也可以指向其他 Git 对象。

可以先看有哪些 tag 引用：

```bash
git show-ref --tags
```

如果是附注标签，还可以继续查看 tag object：

```bash
git cat-file -p <tag-oid>
```

一个附注标签对象通常长这样：

```text
object <target-oid>
type commit
tag v1.0.0
tagger Alice <alice@example.com> ...

Release v1.0.0
```

## 对象如何连成图

把三类对象放在一起看，关系会更清楚：

```text
refs/tags/v1.0
      |
      v
   tag object
      |
      v
    commit ----------> parent commit
      |
      v
     tree
      |
      +- README.md -> blob
      +- src       -> tree
```

常见阅读顺序可以记成：

- blob 解决“内容是什么”
- tree 解决“内容放在哪里”
- commit 解决“这次快照和上一次什么关系”
- tag 解决“给某个对象起一个稳定名字”

## 常见误解

- “tag 只是 commit 的别名。” 不对。轻量标签和附注标签不同，而且 tag 的目标不只限于 commit。
- “commit 直接保存所有文件内容。” 不对。文件内容在 blob 里，commit 通过 tree 间接引用它们。
- “tree 就是一段目录文本。” 不对。`git cat-file -p` 只是 pretty-print，真实存储是 Git 的对象格式。
- “提交历史一定是一条直线。” 不对。合并提交会让历史形成 DAG。

## 小结

tree 让 Git 知道文件名和目录结构，commit 让 Git 知道某次快照及其父关系，tag 让对象拥有更稳定的人类可读名字。它们共同把零散的 blob 组织成可浏览、可比较、可发布的版本历史。
