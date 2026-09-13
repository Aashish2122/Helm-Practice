#!/usr/bin/env bash
# Repairs Helm template syntax that a YAML formatter has mangled.
#
# Formatters break templates in three ways:
#   {{ .Values.x }}   ->  { { .Values.x } }     split braces
#   {{- include ... }} ->  {{ - include ... }}   space between {{ and -
#   {{- ... -}}        ->  {{- ... - }}          space between - and }}
#
# Usage: ./scripts/fix-braces.sh
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="charts"
PATTERN='{ {|} }|\{\{ -|- \}\}'

found=$(grep -rlE "$PATTERN" "$TARGET" 2>/dev/null || true)

if [ -z "$found" ]; then
  echo "OK: no mangled template syntax found."
  exit 0
fi

echo "Repairing:"
echo "$found" | sed 's|^|  |'

echo "$found" | while read -r f; do
  sed -i '' \
    -e 's/{ {/{{/g' \
    -e 's/} }/}}/g' \
    -e 's/{{ -/{{-/g' \
    -e 's/- }}/-}}/g' \
    "$f"
done

echo "Done. Re-checking..."
if grep -rEn "$PATTERN" "$TARGET" 2>/dev/null; then
  echo "WARNING: still mangled above. Your editor may be rewriting on save."
  exit 1
fi
echo "Clean."
