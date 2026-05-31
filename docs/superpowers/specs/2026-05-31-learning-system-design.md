# Learning System Design

Date: 2026-05-31

## Purpose

Build a Markdown-first learning system for Brain-Dump that helps plan, study, review, test, and preserve knowledge for new technical topics.

The system should behave as both:

- A knowledge base system: durable files, structured notes, clear migration into the outer Brain-Dump topic directories.
- A learning coach: guided plans, progress continuation, weak-point detection, Feynman-style testing, review scheduling, and source discovery.

The first version prioritizes technical learning while leaving room for broader subjects later.

## Design Goals

- Keep all long-term state in Markdown so it remains readable in GitHub, Obsidian, Logseq, or a plain editor.
- Separate learning-process artifacts from final knowledge-base notes.
- Generate systematized notes during learning, not only at the end.
- Track progress at both node level and review-card level.
- Support optional web research for current technical resources without automatically importing large external content.
- Make Codex behavior deterministic enough that repeated sessions can continue from the last recorded state.

## External Project References

This design borrows specific ideas from existing open-source or public learning projects:

- roadmap.sh: represent a topic as ordered learning nodes with prerequisites, outputs, and completion criteria.
- PathFlow: customize the learning path from the learner's current level, target outcome, and available study time.
- PageLM: treat learning as a pipeline from resources to notes, questions, feedback, and review assets.
- Logseq and SilverBullet: keep the system local-first and Markdown-first, with links that can connect learning artifacts to durable notes.
- GoCard and Obsidian Spaced Repetition: store review cards directly in Markdown with due dates, levels, and source references.

The system should not copy any one project wholesale. It should adapt these ideas to the existing Brain-Dump repository.

## Repository Structure

Learning work lives under `Learning/`. Final knowledge lives in the existing top-level topic directories such as `Git/`, `iOS/`, `LeetCode/`, or future directories like `AI/`.

```text
Brain-Dump/
  Learning/
    README.md
    topics/
      <topic-slug>/
        plan.md
        progress.md
        resources.md
        feynman.md
        reviews.md
        archive.md
        sessions/
          YYYY-MM-DD.md
        drafts/
          <node-slug>.md

  iOS/
    Swift-Concurrency/
      README.md
      01-async-await.md
      02-task.md
      03-actor.md
      04-mainactor.md
```

## Workspace Versus Knowledge Base

`Learning/topics/<topic-slug>/` is the learning workspace. It stores the plan, progress, source list, session logs, drafts, Feynman tests, review cards, and archive records.

Outer topic directories are the long-term knowledge base. They should contain cleaned, systematized notes intended for future reading and reuse.

Every learning artifact must be classified as one of:

- Temporary record: session details, rough observations, open questions, incomplete thoughts.
- Migratable note: organized material that can become a durable knowledge-base article.
- Long-term review card: compact question-and-answer material used for recall practice.

## Systematized Draft Standard

Drafts in `drafts/` are not loose notes. They are working versions of future knowledge-base articles and should be structured while learning is still in progress.

Each draft should use this shape unless the topic needs a better local format:

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

A draft is ready to migrate when:

- The core idea can be explained in plain language.
- At least one concrete example is included when the topic is practical.
- Known weak points are either resolved or explicitly listed as open questions.
- The note can be read without depending on the session logs.
- The target knowledge-base path is known.

## Topic Files

Each learning topic contains:

- `plan.md`: learning route, nodes, prerequisites, outputs, completion criteria, target knowledge-base directory.
- `progress.md`: current state, next action, node statuses, weak points, due review summary.
- `resources.md`: curated resources, links, source type, reason for selection, learning order, status.
- `sessions/YYYY-MM-DD.md`: daily learning records, decisions, raw notes, questions, and outcomes.
- `drafts/<node-slug>.md`: systematized notes produced during learning and later migrated outward.
- `feynman.md`: explanation prompts, user answers, feedback, follow-up questions, misconceptions.
- `reviews.md`: Markdown review cards, due dates, mastery levels, source links.
- `archive.md`: migration records, completed nodes, target files, unresolved issues.

## Progress Model

The system tracks progress at topic, node, and card levels.

Example current state:

```md
## Current State

- Topic: Swift Concurrency
- Status: active
- Current Node: Actor Isolation
- Next Action: Complete the Actor draft note and run one Feynman explanation test.
- Target Knowledge Base: iOS/Swift-Concurrency/
- Last Session: 2026-05-31
```

Example node table:

```md
| Node | Status | Output Draft | KB Target | Review Due | Weak Points |
|---|---|---|---|---|---|
| async/await | done | drafts/async-await.md | iOS/Swift-Concurrency/01-async-await.md | 2026-06-03 | error propagation |
| Actor Isolation | learning | drafts/actor-isolation.md | iOS/Swift-Concurrency/03-actor.md | 2026-06-02 | reentrancy |
```

Node status values:

- `todo`: planned but not started.
- `learning`: actively being studied.
- `review`: studied but still needs recall practice or Feynman validation.
- `done`: migrated to the knowledge base and has no blocking weak points.

Topic status values:

- `active`: currently being studied.
- `paused`: not active, but intended to resume later.
- `completed`: target learning goal has been met and final notes have been migrated.
- `archived`: learning workspace is preserved as process history.

## Review Card Format

Review cards live in `reviews.md` and stay human-readable.

```md
### Card: actor-isolation-001

- Source: drafts/actor-isolation.md
- Due: 2026-06-02
- Level: 1
- Status: active

Q: Why can an Actor protect its internal mutable state?
A: An Actor isolates mutable state inside its own execution context. External access crosses an asynchronous boundary, which prevents direct concurrent reads and writes.
```

Review levels use a simple first-version schedule:

- Level 1: review after 1 day.
- Level 2: review after 3 days.
- Level 3: review after 7 days.
- Level 4: review after 14 days.
- Level 5: review after 30 days.

The schedule can later be replaced with a richer spaced-repetition algorithm without changing the storage model.

## Core Workflows

### Start Learning

When the user says they want to learn a topic:

1. Ask for missing essentials only if they cannot be reasonably inferred: current level, target outcome, time budget, and preferred depth.
2. Optionally search the web for current resources when the topic is time-sensitive or the user asks for current material.
3. Create `Learning/topics/<topic-slug>/`.
4. Generate `plan.md`, `progress.md`, `resources.md`, initial `reviews.md`, `feynman.md`, `archive.md`, and folders for `sessions/` and `drafts/`.
5. Suggest the target outer knowledge-base directory. If ambiguous, ask before creating or modifying the outer directory.

### Continue Learning

When the user asks to continue:

1. Read `progress.md` first.
2. Check current node, `Next Action`, weak points, due review cards, and latest session.
3. Default to the planned next step.
4. If tests or notes show weak points, insert a review or repair task before advancing.
5. Update `sessions/YYYY-MM-DD.md`, `progress.md`, drafts, and review cards as needed.

### Record Notes

When the user provides notes:

1. Append raw context and decisions to the current session file.
2. Extract durable concepts into the matching `drafts/<node-slug>.md`.
3. Create or update review cards for key recall points.
4. Record unclear points or explanation gaps in `feynman.md`.
5. Update `progress.md` only for meaningful state changes.

### Feynman Test

When the user asks to be tested:

1. Choose prompts from the current node, weak points, drafts, and due review cards.
2. Ask for a plain-language explanation.
3. Evaluate whether the answer is accurate, simple, example-driven, and complete.
4. Add follow-up questions for vague or incorrect parts.
5. Update `feynman.md`, `reviews.md`, and `progress.md`.

### Migrate And Archive

When a node is complete or the user asks to settle material:

1. Read the relevant draft, sessions, Feynman feedback, and review cards.
2. Produce a polished knowledge-base note in the target outer directory.
3. Preserve links back to learning sources where useful.
4. Update `archive.md` with migration date, source draft, target file, and unresolved questions.
5. Mark the node `done` only when the migrated note exists and blocking weak points are resolved.

## Codex Skill Behavior

The planned skill name is `learn-anything`.

Suggested trigger phrases:

- "我要学习 <topic>"
- "继续学习 <topic>"
- "记录今天学习 <topic>"
- "用费曼学习法考我 <topic>"
- "沉淀 <topic> 的当前节点"
- "归档 <topic>"

Skill rules:

- If the topic does not exist, create a new learning workspace.
- If the topic exists, read `progress.md` before deciding the next action.
- For "continue", prioritize `Next Action`, then weak points, then due review cards.
- For "test me", generate questions from current node context rather than generic topic knowledge.
- For "record notes", update both the session log and the relevant draft.
- For "migrate", convert the relevant draft into a polished outer knowledge-base note and update `archive.md`.
- For web resource discovery, prefer official documentation, actively maintained projects, classic books, high-quality courses, and authoritative articles.
- For time-sensitive technical topics, verify resources online before writing recommendations.
- If the target outer directory is ambiguous, ask for confirmation before changing the knowledge-base structure.

## Resource Discovery Rules

The first version supports optional web research. It records curated references rather than copying large external content.

Each resource entry should include:

- Title
- URL
- Type: official documentation, tutorial, book, course, paper, reference, project, article, video
- Recommended stage: introduction, core learning, deep dive, practice, reference
- Why it is useful
- Reading order
- Status: unread, reading, read, skipped

For modern technical topics, Codex should re-check sources before claiming they are current.

## Non-Goals For Version One

- No database.
- No custom web application.
- No automatic full-page ingestion or crawler.
- No complex spaced-repetition algorithm.
- No automatic restructuring of existing top-level knowledge-base directories without confirmation.
- No dependence on Obsidian, Logseq, or any proprietary editor.

## Acceptance Criteria

- A new learning topic can be initialized with a plan, curated resources, progress state, and target knowledge-base location.
- A topic can be resumed from `progress.md` without relying on conversation history.
- Notes produced during learning are maintained as drafts that can become final knowledge-base articles.
- Feynman tests record questions, answers, feedback, and follow-up weak points.
- Review cards have source, due date, level, and status fields.
- A completed node can be migrated to an outer topic directory and recorded in `archive.md`.
- Process artifacts remain in `Learning/`, while durable notes live in the outer knowledge-base directories.
