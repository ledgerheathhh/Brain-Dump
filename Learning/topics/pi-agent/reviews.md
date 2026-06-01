# Pi Agent Reviews

## Review Schedule

- Level 1: review after 1 day.
- Level 2: review after 3 days.
- Level 3: review after 7 days.
- Level 4: review after 14 days.
- Level 5: review after 30 days.

## Cards

### Card: orientation-001

- Source: drafts/orientation.md
- Due: 2026-06-01
- Level: 1
- Status: active

Q: What problem does Pi Agent solve?
A: It provides a small terminal coding-agent harness plus reusable TypeScript libraries for agent state, tool execution, provider-neutral LLM streaming, sessions, TUI rendering, and extensibility.

### Card: package-map-001

- Source: Pi/01-orientation.md
- Due: 2026-06-01
- Level: 1
- Status: active

Q: What are the four main packages in the Pi monorepo?
A: `pi-coding-agent` is the CLI, `pi-agent-core` is the stateful agent runtime, `pi-ai` is the provider-neutral LLM API, and `pi-tui` is the terminal UI library.

### Card: prompt-flow-001

- Source: Pi/01-orientation.md
- Due: 2026-06-01
- Level: 1
- Status: active

Q: What is the high-level flow of one Pi prompt?
A: Terminal editor input becomes a user message, the agent runtime starts a turn, `pi-ai` streams model events, tool calls are validated and executed, results are appended, follow-up turns run if needed, and events update the TUI and session file.
