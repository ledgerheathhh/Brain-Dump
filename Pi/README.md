# Pi Agent

Pi is a TypeScript monorepo for a terminal coding agent and reusable agent libraries.

## Official Links

- GitHub: https://github.com/earendil-works/pi
- Website: https://pi.dev/
- Documentation: https://pi.dev/docs/latest
- SDK docs: https://pi.dev/docs/latest/sdk
- Extensions docs: https://pi.dev/docs/latest/extensions

## What This Project Contains

| Area | Package | Role |
|---|---|---|
| CLI coding agent | `@earendil-works/pi-coding-agent` | User-facing `pi` command, interactive TUI, commands, sessions, settings, skills, extensions, export/share, and SDK entry points. |
| Agent runtime | `@earendil-works/pi-agent-core` | Stateful agent loop, tool execution, event streaming, message conversion, steering/follow-up queues, and hooks. |
| LLM abstraction | `@earendil-works/pi-ai` | Unified API across model providers, streaming events, tool-call validation, model registry, OAuth, usage/cost metadata, and image APIs. |
| Terminal UI | `@earendil-works/pi-tui` | Differential terminal renderer, editor/input components, overlays, markdown rendering, keyboard handling, and terminal image support. |

## Recommended Reading Order

1. [Orientation](./01-orientation.md): understand what problem Pi solves and how the packages fit together.
2. CLI behavior: read `packages/coding-agent/README.md`, then trace `packages/coding-agent/src/cli.ts`.
3. Agent loop: read `packages/agent/README.md`, then trace the low-level loop and `Agent` class.
4. Provider layer: read `packages/ai/README.md`, then inspect provider adapters and model registry code.
5. TUI layer: read `packages/tui/README.md`, then inspect rendering, editor, and component contracts.
6. Extension system: read Pi docs for extensions, skills, prompt templates, themes, and pi packages.

## Learning Workspace

- Active plan: [../Learning/topics/pi-agent/plan.md](../Learning/topics/pi-agent/plan.md)
- Progress: [../Learning/topics/pi-agent/progress.md](../Learning/topics/pi-agent/progress.md)
- Resources: [../Learning/topics/pi-agent/resources.md](../Learning/topics/pi-agent/resources.md)

## Practice Checklist

- Install and run Pi in a disposable project.
- Start a session, use `/model`, `/settings`, `/session`, `/tree`, and `/compact`.
- Read one saved session JSONL file and explain how branching works.
- Build a minimal `@earendil-works/pi-ai` tool-calling script.
- Build a minimal `@earendil-works/pi-agent-core` agent with one custom tool.
- Write a tiny extension that registers one command or one tool.
- Trace one user prompt from terminal input to LLM stream to rendered response.
