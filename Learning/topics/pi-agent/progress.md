# Pi Agent Progress

## Current State

- Topic: Pi Agent
- Status: active
- Current Node: Orientation
- Next Action: Clone or inspect the source tree, then trace the CLI entry point and agent event flow.
- Target Knowledge Base: Pi
- Last Session: 2026-05-31

## Node Status

| Node | Status | Output Draft | KB Target | Review Due | Weak Points |
|---|---|---|---|---|---|
| Orientation | in-progress | drafts/orientation.md | Pi/01-orientation.md | 2026-06-01 | Need source-file-level trace, not just README-level overview. |
| Run And Use Pi | todo | drafts/run-and-use.md | Pi/02-run-and-use.md |  | Need decide install-from-npm vs run-from-source. |
| CLI And Session Model | todo | drafts/cli-sessions.md | Pi/03-cli-sessions.md |  | Need inspect session JSONL format. |
| Agent Runtime | todo | drafts/agent-runtime.md | Pi/04-agent-runtime.md |  | Need identify exact `Agent` and `agentLoop` source files. |
| LLM Provider Layer | todo | drafts/provider-layer.md | Pi/05-provider-layer.md |  | Need minimal runnable script. |
| TUI Layer | todo | drafts/tui-layer.md | Pi/06-tui-layer.md |  | Need understand render-width invariants and focus handling. |
| Extensions And Skills | todo | drafts/extensions-skills.md | Pi/07-extensions-skills.md |  | Need build a small extension. |
| End-To-End Trace | todo | drafts/end-to-end-trace.md | Pi/08-end-to-end-trace.md |  | Depends on earlier nodes. |

## Due Reviews

| Card | Due | Level | Status |
|---|---|---|---|
| orientation-001 | 2026-06-01 | 1 | active |

## Weak Points

| Area | Evidence | Repair Action | Status |
|---|---|---|---|
| Source-level architecture | Current notes are based on repository/docs overview. | Clone or browse the repo and record exact files/functions for the prompt flow. | open |
| Hands-on usage | Pi has not been run locally in this workspace. | Run in a disposable project and capture observations. | open |

## Decision Log

| Date | Decision | Reason |
|---|---|---|
| 2026-05-31 | Study Pi by subsystem: CLI, agent core, provider layer, TUI, extensions. | The monorepo is large; package boundaries are the safest first map. |
