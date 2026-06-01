# Pi Agent Learning Plan

## Target Knowledge Base

- Target Directory: Pi
- Final Index: Pi/README.md

## Learning Goal

- Outcome: Understand Pi's architecture well enough to run it, trace one prompt through the system, and build a minimal custom tool or extension.
- Current Level: Initial orientation; project links collected, source not yet cloned locally.
- Time Budget: 7 focused sessions, 45-90 minutes each.
- Preferred Depth: Practical architecture reading first, then implementation-level tracing.

## Learning Nodes

| Order | Node | Prerequisites | Output Draft | KB Target | Completion Standard |
|---|---|---|---|---|---|
| 1 | Orientation | None | drafts/orientation.md | Pi/01-orientation.md | Explain what Pi is, the monorepo package roles, and the high-level prompt flow. |
| 2 | Run And Use Pi | Orientation | drafts/run-and-use.md | Pi/02-run-and-use.md | Install or run from source, authenticate, start a session, use core commands, and inspect settings. |
| 3 | CLI And Session Model | Run And Use Pi | drafts/cli-sessions.md | Pi/03-cli-sessions.md | Explain command routing, session JSONL storage, branching, resume/fork, and compaction. |
| 4 | Agent Runtime | Orientation | drafts/agent-runtime.md | Pi/04-agent-runtime.md | Explain `Agent`, `agentLoop`, event flow, message conversion, steering/follow-up, and tool execution modes. |
| 5 | LLM Provider Layer | Agent Runtime | drafts/provider-layer.md | Pi/05-provider-layer.md | Build a minimal `pi-ai` streaming/tool-call script and explain provider adapter boundaries. |
| 6 | TUI Layer | Run And Use Pi | drafts/tui-layer.md | Pi/06-tui-layer.md | Explain component rendering, editor behavior, overlays, focus, and markdown rendering. |
| 7 | Extensions And Skills | Agent Runtime | drafts/extensions-skills.md | Pi/07-extensions-skills.md | Build a tiny extension or skill and explain Pi package distribution. |
| 8 | End-To-End Trace | Nodes 2-7 | drafts/end-to-end-trace.md | Pi/08-end-to-end-trace.md | Trace one prompt from editor input to provider stream, tool execution, session persistence, and TUI output. |

## Practice Plan

| Node | Practice Task | Evidence |
|---|---|---|
| Orientation | Create a package map and prompt-flow diagram. | `Pi/01-orientation.md` and Feynman answer. |
| Run And Use Pi | Run Pi in a disposable project and use `/login`, `/model`, `/settings`, `/session`, `/tree`, `/compact`, `/quit`. | Session note with commands tried and observations. |
| CLI And Session Model | Inspect a saved session JSONL file and reconstruct one branch path. | Draft note with sample entry fields and branching explanation. |
| Agent Runtime | Create a minimal `Agent` with one `get_time` or `read_file` tool. | Runnable TypeScript snippet and event log. |
| LLM Provider Layer | Use `@earendil-works/pi-ai` to stream a response and validate a tool call. | Runnable TypeScript snippet and short explanation. |
| TUI Layer | Build or read a minimal `pi-tui` app using `Text`, `Editor`, and one overlay. | Draft note with component contract. |
| Extensions And Skills | Create one local extension command or tool. | Extension files and a session note showing it loaded. |
| End-To-End Trace | Choose one prompt and annotate each subsystem involved. | `Pi/08-end-to-end-trace.md`. |

## Completion Criteria

- Every planned node is `done` in `progress.md`.
- Every migrated node has a target knowledge-base note.
- Blocking weak points are resolved or recorded as open questions.
- Review cards exist for concepts that require recall.
