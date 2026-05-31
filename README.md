# Brain-Dump

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Language](https://img.shields.io/badge/Language-TypeScript%20%7C%20Markdown-blue)](#)

*Choose Language: [English](#english-version) | [中文版](#中文版)*

---

## English Version

Brain-Dump is a personal knowledge base for technical notes, interview prep, and LeetCode solutions.

### Main Areas

- [Git](./Git/README.md): three-part tutorial on Git objects, snapshots, and packfiles
- [iOS](./iOS/README.md): iOS interview and study material
- [Learning](./Learning/README.md): active learning plans, progress, Feynman tests, review cards, and migration workflow
- [LeetCode](./LeetCode/README.md): TypeScript and JavaScript problem solutions by difficulty

### Directory Map

```text
.
├── .agent/
│   └── skills/
│       └── learn-anything/
├── Git/
│   ├── README.md
│   ├── 01-blob-object.md
│   ├── 02-tree-commit-tag.md
│   └── 03-packfile.md
├── iOS/
│   ├── README.md
│   └── interview/
│       ├── ios-objective-c-qa-2025-06-20.md
│       └── xiaomi-2024-ios-written-test.md
├── Learning/
│   ├── README.md
│   └── templates/
└── LeetCode/
    ├── README.md
    ├── Easy/
    ├── Medium/
    └── Hard/
```

### Naming Rules

- Topic index pages use `README.md`
- Git tutorial chapters use numeric prefixes like `01-` to make reading order explicit
- Markdown notes use descriptive names instead of date-only names
- LeetCode solutions keep `LC<number>.ts/js`

### How To Use

- Start from the topic README files above
- For Git internals, open `Git/README.md` and read chapter `01` -> `03`
- Open Markdown notes directly in GitHub, Obsidian, or any Markdown editor
- Run a LeetCode solution with `ts-node LeetCode/Easy/LC997.ts`

---

## 中文版

Brain-Dump 是一个个人技术知识库，用来整理技术笔记、面试资料和 LeetCode 题解。

### 主要内容

- [Git](./Git/README.md)：Git 对象模型、快照结构与 packfile 的三篇教程
- [iOS](./iOS/README.md)：iOS 面试与学习资料
- [Learning](./Learning/README.md)：主动学习计划、进度记录、费曼测验、复习卡和知识库沉淀流程
- [LeetCode](./LeetCode/README.md)：按难度分类的 TypeScript / JavaScript 题解

### 目录结构

```text
.
├── .agent/
│   └── skills/
│       └── learn-anything/
├── Git/
│   ├── README.md
│   ├── 01-blob-object.md
│   ├── 02-tree-commit-tag.md
│   └── 03-packfile.md
├── iOS/
│   ├── README.md
│   └── interview/
│       ├── ios-objective-c-qa-2025-06-20.md
│       └── xiaomi-2024-ios-written-test.md
├── Learning/
│   ├── README.md
│   └── templates/
└── LeetCode/
    ├── README.md
    ├── Easy/
    ├── Medium/
    └── Hard/
```

### 命名约定

- 目录索引页统一使用 `README.md`
- Git 教程章节使用 `01-` 这类数字前缀来表达阅读顺序
- Markdown 笔记使用有语义的文件名，避免只用日期
- LeetCode 题解继续保持 `LC<number>.ts/js`

### 使用方式

- 从上面的主题 README 开始浏览
- Git 笔记建议先打开 `Git/README.md`，再按 `01` -> `03` 顺序阅读
- Markdown 笔记可以直接在 GitHub、Obsidian 或任意 Markdown 编辑器中打开
- LeetCode 题解可通过 `ts-node LeetCode/Easy/LC997.ts` 运行
