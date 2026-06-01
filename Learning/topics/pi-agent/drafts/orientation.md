# Orientation

## What Problem This Solves

Pi provides a terminal coding-agent harness that can be adapted through extension points instead of forks. It also exposes reusable TypeScript libraries for agent state, tool execution, provider-neutral model calls, and terminal UI rendering.

## Core Idea

Keep the core small and make workflow-specific behavior loadable through extensions, skills, prompt templates, themes, and pi packages.

## Mental Model

User prompt -> CLI/editor -> session state -> agent runtime -> provider-neutral model stream -> tool calls -> tool results -> more model turns if needed -> TUI and session updates.

## Key Details

- `@earendil-works/pi-coding-agent`: user-facing CLI and SDK entry point.
- `@earendil-works/pi-agent-core`: stateful agent loop, events, tools, steering, follow-up, and hooks.
- `@earendil-works/pi-ai`: unified LLM API, provider adapters, streaming, tool-call validation, model registry, and OAuth.
- `@earendil-works/pi-tui`: terminal rendering, components, editor, overlays, markdown, and focus handling.

## Example

When the model asks to read a file, the provider layer only surfaces a tool call. The agent runtime validates and executes the tool, appends the result, and may call the model again so it can incorporate the result into the final answer.

## Common Misunderstandings

- Pi is not only the `pi` CLI; it is also a set of packages that can be embedded or extended.
- Provider adapters should not own local tool behavior.
- Terminal UI rendering is not just printing strings; components must respect width and focus/cursor rules.

## Related Concepts

- Agent loop
- Tool calling
- JSONL session storage
- Terminal UI differential rendering
- Extension/plugin systems
- Context compaction

## Open Questions

- Exact source files for the CLI entry point and built-in command registration.
- Exact source files for built-in tools.
- Exact source files for session JSONL read/write and branching.
