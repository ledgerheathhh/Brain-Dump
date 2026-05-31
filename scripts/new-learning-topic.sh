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
