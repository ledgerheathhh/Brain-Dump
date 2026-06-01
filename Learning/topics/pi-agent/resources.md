# Pi Agent Resources

## Selection Rules

- Prefer official documentation for current APIs and tools.
- Prefer maintained projects, classic books, high-quality courses, and authoritative articles.
- Record why each source is useful instead of copying large external content.
- Re-check modern technical sources before claiming they are current.

## Resource List

| Title | URL | Type | Stage | Why It Is Useful | Order | Status |
|---|---|---|---|---|---|---|
| Pi GitHub Repository | https://github.com/earendil-works/pi | source repository | introduction | Canonical source code and monorepo layout. | 1 | reading |
| Pi Documentation | https://pi.dev/docs/latest | official documentation | introduction | Current product overview, install path, configuration, and feature docs. | 2 | reading |
| Pi SDK Docs | https://pi.dev/docs/latest/sdk | official documentation | implementation | Shows how to embed Pi agent capabilities programmatically. | 3 | unread |
| Pi Extensions Docs | https://pi.dev/docs/latest/extensions | official documentation | implementation | Explains how extension APIs add commands, tools, UI, and providers. | 4 | unread |
| `packages/coding-agent/README.md` | https://github.com/earendil-works/pi/tree/main/packages/coding-agent | source documentation | implementation | User-facing CLI behavior, commands, sessions, settings, customization, and SDK entry points. | 5 | unread |
| `packages/agent/README.md` | https://github.com/earendil-works/pi/tree/main/packages/agent | source documentation | implementation | Best entry point for event flow, `Agent`, `agentLoop`, tools, steering, follow-up, and hooks. | 6 | unread |
| `packages/ai/README.md` | https://github.com/earendil-works/pi/tree/main/packages/ai | source documentation | implementation | Provider-neutral model API, streaming events, tool calls, validation, OAuth, and image APIs. | 7 | unread |
| `packages/tui/README.md` | https://github.com/earendil-works/pi/tree/main/packages/tui | source documentation | implementation | Terminal rendering, editor, components, overlays, focus, and IME behavior. | 8 | unread |
| New Home Announcement | https://pi.dev/news/2026/5/7/pi-has-a-new-home | project context | background | Explains the move to `earendil-works/pi` and package scope changes. | 9 | unread |
