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

if [[ ! "$SLUG" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  printf 'ERROR: topic slug must use lowercase letters, digits, and hyphens only, with no leading or trailing hyphen: %s\n' "$SLUG" >&2
  exit 2
fi

TEMPLATE_DIR="$ROOT_DIR/Learning/templates/topic"
TOPIC_DIR="$ROOT_DIR/Learning/topics/$SLUG"
TOPICS_DIR="$ROOT_DIR/Learning/topics"
TODAY="$(date +%Y-%m-%d)"

[ -d "$TEMPLATE_DIR" ] || {
  printf 'ERROR: template directory not found: %s\n' "$TEMPLATE_DIR" >&2
  exit 1
}

mkdir -p "$TOPICS_DIR"

if [ -e "$TOPIC_DIR" ]; then
  printf 'ERROR: topic already exists: %s\n' "$TOPIC_DIR" >&2
  exit 1
fi

TMP_TOPIC_DIR="$(mktemp -d "$TOPICS_DIR/.new-topic.$SLUG.XXXXXX")"

cleanup_tmp_topic_dir() {
  rm -rf "$TMP_TOPIC_DIR"
}

trap cleanup_tmp_topic_dir EXIT

mkdir -p "$TMP_TOPIC_DIR/sessions" "$TMP_TOPIC_DIR/drafts"

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}

render_template() {
  local src="$1"
  local dst="$2"
  local node_title="${3:-Orientation}"
  local escaped_topic escaped_target_kb escaped_today escaped_node_title
  escaped_topic="$(escape_sed_replacement "$TOPIC")"
  escaped_target_kb="$(escape_sed_replacement "$TARGET_KB")"
  escaped_today="$(escape_sed_replacement "$TODAY")"
  escaped_node_title="$(escape_sed_replacement "$node_title")"

  sed \
    -e "s|{{TOPIC}}|$escaped_topic|g" \
    -e "s|{{TARGET_KB}}|$escaped_target_kb|g" \
    -e "s|{{DATE}}|$escaped_today|g" \
    -e "s|{{NODE_TITLE}}|$escaped_node_title|g" \
    "$src" > "$dst"
}

render_template "$TEMPLATE_DIR/plan.md" "$TMP_TOPIC_DIR/plan.md"
render_template "$TEMPLATE_DIR/progress.md" "$TMP_TOPIC_DIR/progress.md"
render_template "$TEMPLATE_DIR/resources.md" "$TMP_TOPIC_DIR/resources.md"
render_template "$TEMPLATE_DIR/feynman.md" "$TMP_TOPIC_DIR/feynman.md"
render_template "$TEMPLATE_DIR/reviews.md" "$TMP_TOPIC_DIR/reviews.md"
render_template "$TEMPLATE_DIR/archive.md" "$TMP_TOPIC_DIR/archive.md"
render_template "$TEMPLATE_DIR/sessions/session.md" "$TMP_TOPIC_DIR/sessions/$TODAY.md"
render_template "$TEMPLATE_DIR/drafts/node.md" "$TMP_TOPIC_DIR/drafts/orientation.md" "Orientation"

mv "$TMP_TOPIC_DIR" "$TOPIC_DIR"
trap - EXIT

printf 'Created learning topic: %s\n' "$TOPIC_DIR"
printf 'Target knowledge base: %s\n' "$TARGET_KB"
