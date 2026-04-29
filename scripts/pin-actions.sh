#!/usr/bin/env bash
# pin-actions.sh — rewrite every `uses: owner/repo@<tag>` in .github/workflows/*
# to `uses: owner/repo@<commit-sha> # <tag>`. uses gh api for sha lookup.
# subaction paths (uses: owner/repo/sub@tag) and reusable workflows
# (uses: owner/repo/.github/workflows/x.yml@tag) are handled.

set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh cli is required (https://cli.github.com)"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

shopt -s nullglob
files=(.github/workflows/*.yml .github/workflows/*.yaml)
if [ "${#files[@]}" -eq 0 ]; then
  echo "no workflow files found"
  exit 0
fi

resolve_sha() {
  local owner_repo="$1"
  local ref="$2"
  gh api "repos/${owner_repo}/commits/${ref}" --jq '.sha' 2>/dev/null || true
}

for f in "${files[@]}"; do
  echo "==> $f"
  tmp="$(mktemp)"
  while IFS= read -r line; do
    if [[ "$line" =~ ^([[:space:]]*-?[[:space:]]*uses:[[:space:]]*)([^@[:space:]]+)@([^[:space:]#]+)(.*)$ ]]; then
      prefix="${BASH_REMATCH[1]}"
      ref_path="${BASH_REMATCH[2]}"
      tag="${BASH_REMATCH[3]}"
      tail_rest="${BASH_REMATCH[4]}"

      owner_repo="$(echo "$ref_path" | awk -F/ '{print $1"/"$2}')"

      if [[ "$tag" =~ ^[0-9a-f]{40}$ ]]; then
        echo "$line" >>"$tmp"
        continue
      fi

      # slsa-github-generator reusable workflows must stay tag-pinned.
      # the builder parses the ref as `refs/tags/vX.Y.Z` to fetch its binary;
      # a sha breaks that lookup with "Invalid ref ... Expected refs/tags/vX.Y.Z".
      if [[ "$ref_path" == slsa-framework/slsa-github-generator/* ]]; then
        echo "$line" >>"$tmp"
        continue
      fi

      sha="$(resolve_sha "$owner_repo" "$tag")"
      if [[ ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
        echo "    warn: could not resolve $owner_repo@$tag (use a specific tag like v1.2.3) -- leaving as-is" >&2
        echo "$line" >>"$tmp"
        continue
      fi

      comment_tail="$(echo "$tail_rest" | sed 's/[[:space:]]*#.*$//')"
      echo "${prefix}${ref_path}@${sha} # ${tag}${comment_tail}" >>"$tmp"
      echo "    ${ref_path}@${tag} -> ${sha:0:12}"
    else
      echo "$line" >>"$tmp"
    fi
  done <"$f"
  mv "$tmp" "$f"
done

echo
echo "done. dependabot will keep these in sync."
