# Learning System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first version of the Brain-Dump learning system: Markdown learning workspace templates, a deterministic topic scaffolder, and a `learn-anything` Codex skill.

**Architecture:** Keep durable learning state in repository Markdown under `Learning/`. Use a small shell script to create consistent topic workspaces from templates. Store the skill source inside the repository at `.agent/skills/learn-anything` and use it project-locally for Brain-Dump learning work.

**Tech Stack:** Markdown, POSIX shell, Git, Codex skills.

---

## File Structure

Create or modify these files:

- Create: `scripts/validate-learning-system.sh`
  - Validates that the repository contains the required Learning templates, scaffolder, README links, and skill source.
- Create: `scripts/new-learning-topic.sh`
  - Creates `Learning/topics/<topic-slug>/` from templates and replaces placeholders.
- Create: `Learning/README.md`
  - Documents how the learning workspace is used.
- Create: `Learning/templates/topic/plan.md`
  - Template for route, nodes, outputs, and completion standards.
- Create: `Learning/templates/topic/progress.md`
  - Template for current state, node status table, and next action.
- Create: `Learning/templates/topic/resources.md`
  - Template for curated resources and source evaluation.
- Create: `Learning/templates/topic/feynman.md`
  - Template for explanation prompts, answers, feedback, and misconceptions.
- Create: `Learning/templates/topic/reviews.md`
  - Template for Markdown review cards and review schedule.
- Create: `Learning/templates/topic/archive.md`
  - Template for migration and archive records.
- Create: `Learning/templates/topic/sessions/session.md`
  - Template for daily learning sessions.
- Create: `Learning/templates/topic/drafts/node.md`
  - Template for systematized draft notes.
- Create: `.agent/skills/learn-anything/SKILL.md`
  - Source-controlled skill instructions.
- Create: `.agent/skills/learn-anything/agents/openai.yaml`
  - UI metadata for the skill.
- Modify: `README.md`
  - Add `Learning/` to the main area list and directory map.
- Keep project-local skill source: `.agent/skills/learn-anything/`
  - Use this repository-local skill source when working in Brain-Dump. Do not install it globally unless the user explicitly asks later.

## Task 1: Add Repository Validation Script

**Files:**
- Create: `scripts/validate-learning-system.sh`

- [ ] **Step 1: Write the validation script**

Create `scripts/validate-learning-system.sh` with this content:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_file() {
  local path="$1"
  [ -f "$path" ] || fail "missing file: $path"
}

require_executable() {
  local path="$1"
  [ -x "$path" ] || fail "not executable: $path"
}

require_text() {
  local path="$1"
  local text="$2"
  grep -Fq "$text" "$path" || fail "missing text in $path: $text"
}

required_files=(
  "Learning/README.md"
  "Learning/templates/topic/plan.md"
  "Learning/templates/topic/progress.md"
  "Learning/templates/topic/resources.md"
  "Learning/templates/topic/feynman.md"
  "Learning/templates/topic/reviews.md"
  "Learning/templates/topic/archive.md"
  "Learning/templates/topic/sessions/session.md"
  "Learning/templates/topic/drafts/node.md"
  ".agent/skills/learn-anything/SKILL.md"
  ".agent/skills/learn-anything/agents/openai.yaml"
  "scripts/new-learning-topic.sh"
)

for path in "${required_files[@]}"; do
  require_file "$path"
done

require_executable "scripts/new-learning-topic.sh"

require_text "Learning/templates/topic/plan.md" "## Learning Nodes"
require_text "Learning/templates/topic/plan.md" "## Target Knowledge Base"
require_text "Learning/templates/topic/progress.md" "## Current State"
require_text "Learning/templates/topic/progress.md" "| Node | Status | Output Draft | KB Target | Review Due | Weak Points |"
require_text "Learning/templates/topic/resources.md" "| Title | URL | Type | Stage | Why It Is Useful | Order | Status |"
require_text "Learning/templates/topic/feynman.md" "## Explanation Tests"
require_text "Learning/templates/topic/reviews.md" "## Review Schedule"
require_text "Learning/templates/topic/archive.md" "## Migration Records"
require_text "Learning/templates/topic/drafts/node.md" "## What Problem This Solves"
require_text "Learning/templates/topic/drafts/node.md" "## Open Questions"
require_text ".agent/skills/learn-anything/SKILL.md" "name: learn-anything"
require_text ".agent/skills/learn-anything/SKILL.md" "Read the topic workspace before acting"
require_text "README.md" "[Learning](./Learning/README.md)"

printf 'PASS: learning system repository checks passed\n'
```

- [ ] **Step 2: Make the validation script executable**

Run:

```bash
chmod +x scripts/validate-learning-system.sh
```

Expected: command exits with status 0.

- [ ] **Step 3: Run validation and confirm it fails before implementation**

Run:

```bash
scripts/validate-learning-system.sh
```

Expected: FAIL with a missing file under `Learning/`, because the templates and skill do not exist yet.

- [ ] **Step 4: Commit**

Run:

```bash
git add scripts/validate-learning-system.sh
git commit -m "test: add learning system validation"
```

Expected: commit succeeds.

## Task 2: Add Learning Workspace Templates

**Files:**
- Create: `Learning/README.md`
- Create: `Learning/templates/topic/plan.md`
- Create: `Learning/templates/topic/progress.md`
- Create: `Learning/templates/topic/resources.md`
- Create: `Learning/templates/topic/feynman.md`
- Create: `Learning/templates/topic/reviews.md`
- Create: `Learning/templates/topic/archive.md`
- Create: `Learning/templates/topic/sessions/session.md`
- Create: `Learning/templates/topic/drafts/node.md`

- [ ] **Step 1: Create template directories**

Run:

```bash
mkdir -p Learning/templates/topic/sessions Learning/templates/topic/drafts
```

Expected: command exits with status 0.

- [ ] **Step 2: Create `Learning/README.md`**

Create `Learning/README.md`:

```md
# Learning

`Learning/` is the active learning workspace for Brain-Dump.

Use it for learning plans, progress tracking, source lists, session logs, Feynman tests, review cards, and draft notes. Final systematized notes should be migrated to the outer knowledge-base directories such as `Git/`, `iOS/`, `LeetCode/`, or future topic directories.

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
```

- [ ] **Step 3: Create `Learning/templates/topic/plan.md`**

Create `Learning/templates/topic/plan.md`:

```md
# {{TOPIC}} Learning Plan

## Target Knowledge Base

- Target Directory: {{TARGET_KB}}
- Final Index: {{TARGET_KB}}/README.md

## Learning Goal

- Outcome:
- Current Level:
- Time Budget:
- Preferred Depth:

## Learning Nodes

| Order | Node | Prerequisites | Output Draft | KB Target | Completion Standard |
|---|---|---|---|---|---|
| 1 | Orientation | None | drafts/orientation.md | {{TARGET_KB}}/01-orientation.md | Explain the topic scope, why it matters, and the main concepts. |

## Practice Plan

| Node | Practice Task | Evidence |
|---|---|---|
| Orientation | Build or explain one minimal example. | Session note and draft section. |

## Completion Criteria

- Every planned node is `done` in `progress.md`.
- Every migrated node has a target knowledge-base note.
- Blocking weak points are resolved or recorded as open questions.
- Review cards exist for concepts that require recall.
```

- [ ] **Step 4: Create `Learning/templates/topic/progress.md`**

Create `Learning/templates/topic/progress.md`:

```md
# {{TOPIC}} Progress

## Current State

- Topic: {{TOPIC}}
- Status: active
- Current Node: Orientation
- Next Action: Complete the first learning session and create the orientation draft.
- Target Knowledge Base: {{TARGET_KB}}
- Last Session:

## Node Status

| Node | Status | Output Draft | KB Target | Review Due | Weak Points |
|---|---|---|---|---|---|
| Orientation | todo | drafts/orientation.md | {{TARGET_KB}}/01-orientation.md |  |  |

## Due Reviews

| Card | Due | Level | Status |
|---|---|---|---|

## Weak Points

| Area | Evidence | Repair Action | Status |
|---|---|---|---|

## Decision Log

| Date | Decision | Reason |
|---|---|---|
```

- [ ] **Step 5: Create `Learning/templates/topic/resources.md`**

Create `Learning/templates/topic/resources.md`:

```md
# {{TOPIC}} Resources

## Selection Rules

- Prefer official documentation for current APIs and tools.
- Prefer maintained projects, classic books, high-quality courses, and authoritative articles.
- Record why each source is useful instead of copying large external content.
- Re-check modern technical sources before claiming they are current.

## Resource List

| Title | URL | Type | Stage | Why It Is Useful | Order | Status |
|---|---|---|---|---|---|---|
|  |  | official documentation | introduction |  | 1 | unread |
```

- [ ] **Step 6: Create `Learning/templates/topic/feynman.md`**

Create `Learning/templates/topic/feynman.md`:

```md
# {{TOPIC}} Feynman Tests

## Explanation Tests

### Test: orientation-001

- Date:
- Node: Orientation
- Source: drafts/orientation.md
- Status: open

Prompt: Explain {{TOPIC}} to a beginner in plain language.

Answer:

Feedback:

Follow-up Questions:

- 

Misconceptions:

- 
```

- [ ] **Step 7: Create `Learning/templates/topic/reviews.md`**

Create `Learning/templates/topic/reviews.md`:

```md
# {{TOPIC}} Reviews

## Review Schedule

- Level 1: review after 1 day.
- Level 2: review after 3 days.
- Level 3: review after 7 days.
- Level 4: review after 14 days.
- Level 5: review after 30 days.

## Cards

### Card: orientation-001

- Source: drafts/orientation.md
- Due:
- Level: 1
- Status: active

Q: What problem does {{TOPIC}} solve?
A:
```

- [ ] **Step 8: Create `Learning/templates/topic/archive.md`**

Create `Learning/templates/topic/archive.md`:

```md
# {{TOPIC}} Archive

## Migration Records

| Date | Node | Source Draft | Target Note | Status | Unresolved Questions |
|---|---|---|---|---|---|

## Completed Sessions

| Date | Summary | Linked Session |
|---|---|---|
```

- [ ] **Step 9: Create `Learning/templates/topic/sessions/session.md`**

Create `Learning/templates/topic/sessions/session.md`:

```md
# {{TOPIC}} Session - {{DATE}}

## Goal

## What I Studied

## Raw Notes

## Durable Ideas

## Questions

## Feynman Candidate Prompts

## Review Card Candidates

## Next Action
```

- [ ] **Step 10: Create `Learning/templates/topic/drafts/node.md`**

Create `Learning/templates/topic/drafts/node.md`:

```md
# {{NODE_TITLE}}

## What Problem This Solves

## Core Idea

## Mental Model

## Key Details

## Example

## Common Misunderstandings

## Related Concepts

## Open Questions
```

- [ ] **Step 11: Run validation and confirm remaining failures**

Run:

```bash
scripts/validate-learning-system.sh
```

Expected: FAIL because `scripts/new-learning-topic.sh`, the skill source, and the README link have not been added yet.

- [ ] **Step 12: Commit**

Run:

```bash
git add Learning/README.md Learning/templates
git commit -m "docs: add learning workspace templates"
```

Expected: commit succeeds.

## Task 3: Add Topic Scaffolder

**Files:**
- Create: `scripts/new-learning-topic.sh`

- [ ] **Step 1: Write `scripts/new-learning-topic.sh`**

Create `scripts/new-learning-topic.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/new-learning-topic.sh "<topic>" "<target-kb>" [topic-slug] [repo-root]

Examples:
  scripts/new-learning-topic.sh "Swift Concurrency" "iOS/Swift-Concurrency" swift-concurrency
  scripts/new-learning-topic.sh "Objective-C Runtime" "iOS/Objective-C-Basics" objective-c-runtime /tmp/brain-dump-test
USAGE
}

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
  usage >&2
  exit 2
fi

TOPIC="$1"
TARGET_KB="${2%/}"
SLUG="${3:-}"
ROOT_DIR="${4:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ -z "$SLUG" ]; then
  SLUG="$(printf '%s' "$TOPIC" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
fi

if [ -z "$SLUG" ]; then
  printf 'ERROR: topic slug is empty. Provide an explicit slug.\n' >&2
  exit 2
fi

TEMPLATE_DIR="$ROOT_DIR/Learning/templates/topic"
TOPIC_DIR="$ROOT_DIR/Learning/topics/$SLUG"
TODAY="$(date +%Y-%m-%d)"

[ -d "$TEMPLATE_DIR" ] || {
  printf 'ERROR: template directory not found: %s\n' "$TEMPLATE_DIR" >&2
  exit 1
}

if [ -e "$TOPIC_DIR" ]; then
  printf 'ERROR: topic already exists: %s\n' "$TOPIC_DIR" >&2
  exit 1
fi

mkdir -p "$TOPIC_DIR/sessions" "$TOPIC_DIR/drafts"

render_template() {
  local src="$1"
  local dst="$2"
  local node_title="${3:-Orientation}"
  sed \
    -e "s|{{TOPIC}}|$TOPIC|g" \
    -e "s|{{TARGET_KB}}|$TARGET_KB|g" \
    -e "s|{{DATE}}|$TODAY|g" \
    -e "s|{{NODE_TITLE}}|$node_title|g" \
    "$src" > "$dst"
}

render_template "$TEMPLATE_DIR/plan.md" "$TOPIC_DIR/plan.md"
render_template "$TEMPLATE_DIR/progress.md" "$TOPIC_DIR/progress.md"
render_template "$TEMPLATE_DIR/resources.md" "$TOPIC_DIR/resources.md"
render_template "$TEMPLATE_DIR/feynman.md" "$TOPIC_DIR/feynman.md"
render_template "$TEMPLATE_DIR/reviews.md" "$TOPIC_DIR/reviews.md"
render_template "$TEMPLATE_DIR/archive.md" "$TOPIC_DIR/archive.md"
render_template "$TEMPLATE_DIR/sessions/session.md" "$TOPIC_DIR/sessions/$TODAY.md"
render_template "$TEMPLATE_DIR/drafts/node.md" "$TOPIC_DIR/drafts/orientation.md" "Orientation"

printf 'Created learning topic: %s\n' "$TOPIC_DIR"
printf 'Target knowledge base: %s\n' "$TARGET_KB"
```

- [ ] **Step 2: Make the scaffolder executable**

Run:

```bash
chmod +x scripts/new-learning-topic.sh
```

Expected: command exits with status 0.

- [ ] **Step 3: Test scaffolding in a temporary copy**

Run:

```bash
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/Learning/templates"
cp -R Learning/templates/topic "$tmpdir/Learning/templates/topic"
scripts/new-learning-topic.sh "Swift Concurrency" "iOS/Swift-Concurrency" swift-concurrency "$tmpdir"
test -f "$tmpdir/Learning/topics/swift-concurrency/plan.md"
test -f "$tmpdir/Learning/topics/swift-concurrency/progress.md"
test -f "$tmpdir/Learning/topics/swift-concurrency/sessions/$(date +%Y-%m-%d).md"
test -f "$tmpdir/Learning/topics/swift-concurrency/drafts/orientation.md"
grep -Fq "Swift Concurrency" "$tmpdir/Learning/topics/swift-concurrency/progress.md"
grep -Fq "iOS/Swift-Concurrency" "$tmpdir/Learning/topics/swift-concurrency/plan.md"
```

Expected: all commands exit with status 0 and the script prints the created topic path.

- [ ] **Step 4: Run validation and confirm remaining failures**

Run:

```bash
scripts/validate-learning-system.sh
```

Expected: FAIL because the skill source and README link have not been added yet.

- [ ] **Step 5: Commit**

Run:

```bash
git add scripts/new-learning-topic.sh
git commit -m "feat: add learning topic scaffolder"
```

Expected: commit succeeds.

## Task 4: Add Source-Controlled Codex Skill

**Files:**
- Create: `.agent/skills/learn-anything/SKILL.md`
- Create: `.agent/skills/learn-anything/agents/openai.yaml`

- [ ] **Step 1: Initialize the skill folder using skill-creator**

Run:

```bash
python3 /Users/ledgerheath/.codex/skills/.system/skill-creator/scripts/init_skill.py learn-anything --path .agent/skills --interface display_name="Learn Anything" --interface short_description="Plan, continue, test, and archive Markdown-first learning topics." --interface default_prompt="Help me start or continue learning a technical topic in Brain-Dump."
```

Expected: creates `.agent/skills/learn-anything/` with `SKILL.md` and `agents/openai.yaml`.

- [ ] **Step 2: Replace `.agent/skills/learn-anything/SKILL.md`**

Replace the generated file with:

```md
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
```

- [ ] **Step 3: Validate the source skill**

Run:

```bash
env PYTHONPATH=/private/tmp/quick_validate_yaml python3 /Users/ledgerheath/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agent/skills/learn-anything
```

Expected: validation passes.

- [ ] **Step 4: Commit**

Run:

```bash
git add .agent/skills/learn-anything
git commit -m "feat: add learn-anything skill source"
```

Expected: commit succeeds.

## Task 5: Update Repository README And Final Validation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add Learning to the English main areas**

Modify the English `Main Areas` list in `README.md` so it includes:

```md
- [Learning](./Learning/README.md): active learning plans, progress, Feynman tests, review cards, and migration workflow
```

- [ ] **Step 2: Add Learning to the Chinese main areas**

Modify the Chinese `主要内容` list in `README.md` so it includes:

```md
- [Learning](./Learning/README.md)：主动学习计划、进度记录、费曼测验、复习卡和知识库沉淀流程
```

- [ ] **Step 3: Add Learning to both directory maps**

In both directory maps in `README.md`, add:

```text
├── Learning/
│   ├── README.md
│   └── templates/
```

Place it alongside `Git/`, `iOS/`, and `LeetCode/`.

- [ ] **Step 4: Run repository validation**

Run:

```bash
scripts/validate-learning-system.sh
```

Expected:

```text
PASS: learning system repository checks passed
```

- [ ] **Step 5: Run scaffold smoke test**

Run:

```bash
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/Learning/templates"
cp -R Learning/templates/topic "$tmpdir/Learning/templates/topic"
scripts/new-learning-topic.sh "Swift Concurrency" "iOS/Swift-Concurrency" swift-concurrency "$tmpdir"
grep -Fq "Current Node: Orientation" "$tmpdir/Learning/topics/swift-concurrency/progress.md"
grep -Fq "Target Directory: iOS/Swift-Concurrency" "$tmpdir/Learning/topics/swift-concurrency/plan.md"
grep -Fq "# Orientation" "$tmpdir/Learning/topics/swift-concurrency/drafts/orientation.md"
```

Expected: all commands exit with status 0.

- [ ] **Step 6: Commit**

Run:

```bash
git add README.md
git commit -m "docs: document learning workspace"
```

Expected: commit succeeds.

## Task 6: Keep The Skill Project-Local

**Files:**
- No new files.

- [ ] **Step 1: Confirm the project-local skill source exists**

Run:

```bash
test -f .agent/skills/learn-anything/SKILL.md
test -f .agent/skills/learn-anything/agents/openai.yaml
```

Expected: both commands exit with status 0.

- [ ] **Step 2: Validate the project-local skill**

Run:

```bash
env PYTHONPATH=/private/tmp/quick_validate_yaml python3 /Users/ledgerheath/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agent/skills/learn-anything
```

Expected: validation passes.

- [ ] **Step 3: Confirm no global install is required**

Run:

```bash
printf 'Using project-local skill source: .agent/skills/learn-anything\n'
```

Expected output:

```text
Using project-local skill source: .agent/skills/learn-anything
```

## Task 7: Final Verification And Git Review

**Files:**
- No new files.

- [ ] **Step 1: Run all local verification commands**

Run:

```bash
scripts/validate-learning-system.sh
env PYTHONPATH=/private/tmp/quick_validate_yaml python3 /Users/ledgerheath/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agent/skills/learn-anything
```

Expected:

```text
PASS: learning system repository checks passed
```

and skill validation passes.

- [ ] **Step 2: Run a final scaffolder smoke test**

Run:

```bash
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/Learning/templates"
cp -R Learning/templates/topic "$tmpdir/Learning/templates/topic"
scripts/new-learning-topic.sh "Objective-C Runtime" "iOS/Objective-C-Basics" objective-c-runtime "$tmpdir"
test -f "$tmpdir/Learning/topics/objective-c-runtime/resources.md"
test -f "$tmpdir/Learning/topics/objective-c-runtime/feynman.md"
test -f "$tmpdir/Learning/topics/objective-c-runtime/reviews.md"
test -f "$tmpdir/Learning/topics/objective-c-runtime/archive.md"
grep -Fq "Objective-C Runtime" "$tmpdir/Learning/topics/objective-c-runtime/resources.md"
```

Expected: all commands exit with status 0.

- [ ] **Step 3: Review git status**

Run:

```bash
git status --short
```

Expected: clean working tree after commits, except possible untracked files outside the repository are not shown.

## Self-Review

Spec coverage:

- Markdown-first learning workspace: Tasks 2 and 5.
- Learning process separated from final knowledge base: Task 2 templates and README.
- Systematized drafts during learning: Task 2 `drafts/node.md` and Task 4 skill rules.
- Node and review-card progress tracking: Task 2 `progress.md` and `reviews.md`.
- Optional current resource discovery: Task 4 skill rules and Task 2 `resources.md`.
- Deterministic continuation from saved state: Task 4 requires reading `progress.md` first.
- Feynman tests: Task 2 `feynman.md` and Task 4 workflow.
- Migration and archive: Task 2 `archive.md` and Task 4 migration workflow.
- Project-local Codex skill source: Tasks 4 and 6.

Placeholder scan:

- The plan intentionally uses template placeholders such as `{{TOPIC}}`, `{{TARGET_KB}}`, `{{DATE}}`, and `{{NODE_TITLE}}` because the scaffolder replaces them.
- No task uses incomplete implementation wording.

Type and name consistency:

- The topic scaffolder expects the same template paths validated by `scripts/validate-learning-system.sh`.
- The skill source path is `.agent/skills/learn-anything`; no global install path is required for the current project-local workflow.
- Triggering skill name is consistently `learn-anything`.
