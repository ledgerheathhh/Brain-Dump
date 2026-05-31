---
name: learn-anything
description: Markdown-first technical learning coach for Brain-Dump. Use when the user wants to learn a new topic, continue a saved learning topic, record study notes, find current learning resources, generate Feynman-style questions, create review cards, migrate drafts into the outer knowledge base, or archive completed learning work.
---

# Learn Anything

Use this skill to manage Brain-Dump learning topics stored under `Learning/topics/<topic-slug>/`.

## Core Rule

Read the topic workspace before acting. If the topic exists, inspect `progress.md` first, then relevant files such as `plan.md`, `resources.md`, `feynman.md`, `reviews.md`, latest `sessions/`, and `drafts/`.

## Workspace Shape

```text
Learning/topics/<topic-slug>/
  plan.md
  progress.md
  resources.md
  feynman.md
  reviews.md
  archive.md
  sessions/
  drafts/
```

The `Learning/` folder stores process artifacts. Final systematized notes belong in outer knowledge-base directories such as `Git/`, `iOS/`, `LeetCode/`, or another confirmed target.

## Start A Topic

When the user says they want to learn a topic:

1. Infer topic, current level, goal, time budget, preferred depth, and target knowledge-base directory from context.
2. Ask only for information that cannot be inferred and would change the plan.
3. If the technical topic is current or the user asks for current resources, browse the web and prefer official documentation, maintained projects, books, courses, and authoritative articles.
4. Create the topic with `scripts/new-learning-topic.sh "<topic>" "<target-kb>" <topic-slug>` when the repository has that script.
5. Fill `plan.md` with ordered learning nodes, prerequisites, output drafts, target notes, practice tasks, and completion standards.
6. Fill `resources.md` with curated resources. Record title, URL, type, stage, reason, order, and status. Do not copy large external pages.
7. Update `progress.md` with the current node and next action.

If the target outer directory is ambiguous, ask before creating or modifying it.

## Continue A Topic

When the user asks to continue:

1. Read `progress.md`.
2. Check current node, `Next Action`, weak points, due review cards, and latest session.
3. Default to the planned next step.
4. If weak points or due cards exist, insert review or repair before advancing.
5. Write the session outcome to `sessions/YYYY-MM-DD.md`.
6. Update the matching draft in `drafts/` when durable knowledge was produced.
7. Update `progress.md`, `feynman.md`, and `reviews.md` only for real state changes.

## Record Notes

When the user provides notes:

1. Append raw context to the current dated session.
2. Extract durable concepts into the relevant draft.
3. Add review card candidates to `reviews.md`.
4. Record unclear points and explanation gaps in `feynman.md`.
5. Keep drafts readable without relying on session logs.

## Feynman Test

When the user asks to be tested:

1. Choose prompts from the current node, weak points, drafts, and due review cards.
2. Ask for a plain-language explanation.
3. Evaluate accuracy, simplicity, examples, and missing pieces.
4. Ask follow-up questions for vague or wrong parts.
5. Record prompt, answer, feedback, follow-ups, and misconceptions in `feynman.md`.
6. Update review cards and node weak points.

## Migrate And Archive

When the user asks to migrate, settle, or archive a node:

1. Read the relevant draft, sessions, Feynman feedback, and review cards.
2. Produce a polished note in the target outer knowledge-base directory.
3. Preserve useful source links.
4. Update `archive.md` with date, node, source draft, target note, status, and unresolved questions.
5. Mark a node `done` only when the migrated note exists and blocking weak points are resolved.

## Draft Standard

Drafts in `drafts/` are working versions of future knowledge-base notes. Prefer this shape:

```md
# <Node Title>

## What Problem This Solves

## Core Idea

## Mental Model

## Key Details

## Example

## Common Misunderstandings

## Related Concepts

## Open Questions
```

## Review Cards

Use this Markdown card format:

```md
### Card: <node-slug>-001

- Source: drafts/<node-slug>.md
- Due: YYYY-MM-DD
- Level: 1
- Status: active

Q:
A:
```

Review schedule:

- Level 1: 1 day.
- Level 2: 3 days.
- Level 3: 7 days.
- Level 4: 14 days.
- Level 5: 30 days.
