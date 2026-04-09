# Git Notes

这一组笔记按章节讲 Git 的对象模型与存储路径，适合从“`git add` / `git commit` 背后发生了什么”这个问题开始读。

## 建议阅读顺序

1. [01 Blob Object](./01-blob-object.md)：理解 Git 如何把文件内容写成可寻址对象
2. [02 Tree Commit Tag](./02-tree-commit-tag.md)：理解目录、提交历史与标签如何把对象组织起来
3. [03 Packfile](./03-packfile.md)：理解 Git 如何把同一批对象高效存储和传输

## 读完你会搞清楚什么

- blob、tree、commit、tag 分别负责什么
- 为什么 commit 指向 tree，而不是直接指向文件
- loose object 和 packfile 的关系
- 为什么 Git 能同时做到内容复用、历史追踪和高效传输

## 范围说明

这个系列只覆盖 Git 的对象模型和存储路径，不展开 refs、index、reflog、分支实现等其他内部机制。
