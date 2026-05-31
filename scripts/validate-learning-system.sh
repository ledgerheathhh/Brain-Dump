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
  "Learning/codex-skills/learn-anything/SKILL.md"
  "Learning/codex-skills/learn-anything/agents/openai.yaml"
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
require_text "Learning/codex-skills/learn-anything/SKILL.md" "name: learn-anything"
require_text "Learning/codex-skills/learn-anything/SKILL.md" "Read the topic workspace before acting"
require_text "README.md" "[Learning](./Learning/README.md)"

printf 'PASS: learning system repository checks passed\n'
