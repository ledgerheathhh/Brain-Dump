# Pi Agent 学习笔记

这个目录用来记录我学习 [Pi](https://pi.dev/) 的过程。

Pi 是一个以终端为核心的 coding agent harness。它的核心目标不是做一个封闭产品，而是提供一个可以被工作流、模型、工具、技能、主题和扩展持续改造的代理运行框架。

## 项目入口

- 官网: <https://pi.dev/>
- 文档: <https://pi.dev/docs/latest>
- GitHub: <https://github.com/earendil-works/pi>
- 包目录: <https://pi.dev/packages>

## 先理解什么

学习这个项目时，先把它当成几个层次来看：

1. **CLI / TUI 产品层**
   - 包: `@earendil-works/pi-coding-agent`
   - 作用: 终端里的交互式 coding agent，也是用户直接运行的 `pi` 命令。

2. **Agent 运行时层**
   - 包: `@earendil-works/pi-agent-core`
   - 作用: 管理 agent 状态、工具调用、消息流和执行过程。

3. **模型适配层**
   - 包: `@earendil-works/pi-ai`
   - 作用: 统一不同 LLM provider 的 API，包括 OpenAI、Anthropic、Google 等。

4. **终端 UI 层**
   - 包: `@earendil-works/pi-tui`
   - 作用: 提供 TUI 组件和差量渲染能力。

5. **扩展生态**
   - 包括 extensions、skills、prompt templates、themes、Pi packages。
   - 这是 Pi 的重点之一：核心保持小，非通用能力尽量通过扩展实现。

## 本地运行

从官方文档看，直接使用 Pi 可以全局安装：

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
pi
```

如果是学习源码，建议 clone 仓库后从源码运行：

```bash
git clone https://github.com/earendil-works/pi.git
cd pi
npm install --ignore-scripts
npm run build
./pi-test.sh
```

常用检查命令：

```bash
npm run check
./test.sh
```

注意：官方项目规则里提到，代码变更后通常跑 `npm run check`；测试优先使用仓库根目录的 `./test.sh`，避免直接跑完整 vitest e2e。

## 推荐学习路线

### 1. 先跑起来

目标是知道 Pi 的基本体验和交互模型。

- 安装并运行 `pi`
- 试用 `/login` 或配置 API key
- 熟悉常用 slash command
- 看一遍文档里的 Quickstart、Using Pi、Providers、Settings

### 2. 理解用户态能力

目标是知道 Pi 作为工具能做什么。

- interactive mode: 日常交互式 coding agent
- print / JSON mode: 用于脚本化、自动化、管道集成
- RPC mode / SDK: 嵌入到其他程序里
- sessions: 会话树、分支、导出和分享
- compaction: 上下文压缩和摘要

### 3. 阅读源码结构

目标是把包之间的边界搞清楚。

建议顺序：

1. 根目录 `package.json`
   - 看 workspaces、scripts、Node 版本要求、检查命令。

2. `packages/coding-agent`
   - 从 CLI 入口和启动流程开始看。
   - 关注命令解析、配置加载、TUI 启动、会话管理。

3. `packages/agent`
   - 看 agent runtime 如何组织消息、工具、状态和执行循环。

4. `packages/ai`
   - 看 provider 抽象、模型配置、请求/响应统一层。

5. `packages/tui`
   - 看终端 UI 的组件模型和渲染策略。

### 4. 学扩展机制

目标是理解 Pi 为什么说“change the harness, not your workflow”。

重点看：

- extensions: TypeScript 模块，扩展工具、命令、事件和 UI
- skills: 按需加载的能力包
- prompt templates: 可复用提示词
- themes: 终端主题
- pi packages: 把扩展、技能、提示词和主题打包发布

可以从包目录找几个高下载量扩展读 README，再回到源码看扩展加载机制。

### 5. 做一个小练习

建议从低风险目标开始：

- 写一个简单 prompt template
- 写一个只读 extension，例如增加一个展示当前项目摘要的 slash command
- 改一个本地 theme
- 用 print / JSON mode 做一个脚本化调用

不要一开始就改核心 agent loop。先理解边界，再动共享逻辑。

## 读代码时要关注的问题

- 一次用户输入如何变成模型请求？
- 工具调用如何被注册、展示、执行和回传？
- session tree 是怎么存储和分支的？
- provider 差异在哪里被抹平？
- TUI 如何避免整屏重绘？
- 配置从哪些地方加载，优先级是什么？
- extension 能插入哪些生命周期？
- 哪些能力属于 core，哪些应该做成 extension？

## 贡献注意事项

这个项目对贡献质量要求比较明确：

- 先读 `CONTRIBUTING.md` 和 `AGENTS.md`
- 新贡献者的 issue / PR 默认会被自动关闭，维护者之后人工筛选
- PR 前需要通过：

```bash
npm run check
./test.sh
```

- 不要提交自己无法解释清楚的 AI 生成代码
- Pi 的核心哲学是保持 core minimal，很多功能更适合做成 extension

## 我的学习记录

可以按这个格式继续追加：

```markdown
## YYYY-MM-DD

### 今天看了什么

- 

### 搞懂了什么

- 

### 还没懂的问题

- 

### 下一步

- 
```
