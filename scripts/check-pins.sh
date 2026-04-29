#!/usr/bin/env bash
# check-pins.sh — fail if any `uses: owner/repo@<tag>` still references a tag
# instead of a 40-character commit sha. run as a ci gate.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

shopt -s nullglob
files=(.github/workflows/*.yml .github/workflows/*.yaml)
if [ "${#files[@]}" -eq 0 ]; then
  echo "no workflow files; nothing to check"
  exit 0
fi

bad=0
for f in "${files[@]}"; do
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*([^@[:space:]]+)@([^[:space:]#]+) ]]; then
      ref="${BASH_REMATCH[1]}"
      tag="${BASH_REMATCH[2]}"
      if [[ ! "$tag" =~ ^[0-9a-f]{40}$ ]]; then
        echo "$f: $ref@$tag is not pinned to a sha"
        bad=$((bad + 1))
      fi
    fi
  done <"$f"
done

if [ "$bad" -gt 0 ]; then
  echo
  echo "found $bad unpinned action reference(s)."
  echo "run: npm run pin-actions"
  exit 1
fi

echo "all action references are sha-pinned."
