# Learning

`Learning/` is the active learning workspace for Brain-Dump.

Use it for learning plans, progress tracking, source lists, session logs, Feynman tests, review cards, and draft notes. Final systematized notes should be migrated to the outer knowledge-base directories such as `Git/`, `iOS/`, `LeetCode/`, or future topic directories.

The project-local learning workflow skill lives at `.agent/skills/learn-anything/`. Keep `Learning/` focused on learning data and templates.

## Directory Shape

```text
Learning/
  templates/
    topic/
  topics/
    <topic-slug>/
      plan.md
      progress.md
      resources.md
      feynman.md
      reviews.md
      archive.md
      sessions/
      drafts/
```

## Artifact Types

- Temporary record: raw session notes, questions, decisions, and learning process details.
- Migratable note: organized draft content that can become a durable knowledge-base article.
- Long-term review card: compact question-and-answer material with a due date and mastery level.

## Common Commands

Create a topic workspace:

```bash
scripts/new-learning-topic.sh "Swift Concurrency" "iOS/Swift-Concurrency" swift-concurrency
```

Validate the learning system files:

```bash
scripts/validate-learning-system.sh
```
