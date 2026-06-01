# Pi Agent Feynman Tests

## Explanation Tests

### Test: orientation-001

- Date: 2026-05-31
- Node: Orientation
- Source: drafts/orientation.md
- Status: open

Prompt: Explain Pi Agent to a beginner in plain language.

Answer:

Feedback:

Follow-up Questions:

- What is the difference between `pi-coding-agent`, `pi-agent-core`, `pi-ai`, and `pi-tui`?
- Why does Pi use an extension system instead of putting every workflow in the default CLI?
- What happens when the model asks to call a tool?

Misconceptions:

- "Pi is only a CLI." It is also a set of reusable packages: agent runtime, LLM API, and TUI library.
- "Tool execution is provider-specific." Providers emit tool calls, but validation and execution are agent/runtime responsibilities.
