#!/usr/bin/env bash
# Copies the docs skeleton templates into the target repo.
# Never overwrites an existing file: re-running only fills gaps.
set -euo pipefail

WITH_EVALS=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --evals) WITH_EVALS=1 ;;
    *) TARGET="$arg" ;;
  esac
done
[ -z "$TARGET" ] && TARGET="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SRC="$(cd "$(dirname "$0")/../templates" && pwd)"

created=0
skipped=0
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  if [ "$rel" = "docs/engineering/evals.md" ] && [ "$WITH_EVALS" -ne 1 ]; then
    echo "omit    $rel (ML/agent repos only; pass --evals to include)"
    continue
  fi
  dest="$TARGET/$rel"
  if [ -e "$dest" ]; then
    echo "skip    $rel"
    skipped=$((skipped + 1))
  else
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
    echo "create  $rel"
    created=$((created + 1))
  fi
done < <(find "$SRC" -type f -print0 | sort -z)

echo ""
echo "Done: $created created, $skipped skipped (existing files are never overwritten)."
