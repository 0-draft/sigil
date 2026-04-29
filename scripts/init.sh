#!/usr/bin/env bash
# init.sh — bootstrap a sigil-templated repo.
# rewrites every reference to 0-draft/sigil with <your-org>/<your-repo>
# and the package name in package.json. run once after `Use this template`.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <new-org> <new-repo>"
  echo "example: $0 acme widget"
  exit 1
fi

NEW_ORG="$1"
NEW_REPO="$2"
OLD_ORG="0-draft"
OLD_REPO="sigil"

if ! [[ "$NEW_ORG" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
  echo "error: org must be a valid github org/user name"
  exit 1
fi
if ! [[ "$NEW_REPO" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  echo "error: repo name has invalid characters"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> rewriting $OLD_ORG/$OLD_REPO -> $NEW_ORG/$NEW_REPO"

FILES=$(grep -rl --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.git \
  -e "$OLD_ORG/$OLD_REPO" \
  -e "@$OLD_ORG/$OLD_REPO" \
  . 2>/dev/null || true)

if [ -z "$FILES" ]; then
  echo "    nothing to rewrite (already initialized?)"
else
  for f in $FILES; do
    if [ "$f" = "./scripts/init.sh" ]; then
      continue
    fi
    sed -i.bak "s|@$OLD_ORG/$OLD_REPO|@$NEW_ORG/$NEW_REPO|g; s|$OLD_ORG/$OLD_REPO|$NEW_ORG/$NEW_REPO|g" "$f"
    rm -f "$f.bak"
    echo "    rewrote $f"
  done
fi

# CODEOWNERS uses team references (@<org>/<team>) that the prior pass leaves alone.
# rewrite the org prefix in CODEOWNERS only, so other 0-draft links (e.g. chainscope) survive.
if [ -f ".github/CODEOWNERS" ]; then
  sed -i.bak "s|@$OLD_ORG/|@$NEW_ORG/|g" .github/CODEOWNERS
  rm -f .github/CODEOWNERS.bak
  echo "    rewrote .github/CODEOWNERS team references"
fi

echo "==> pinning every action in .github/workflows to a full commit sha"
if command -v gh >/dev/null 2>&1; then
  bash "$ROOT/scripts/pin-actions.sh"
else
  echo "    skipped (gh cli not installed) — run \`npm run pin-actions\` later"
fi

echo
echo "==> next steps:"
echo
echo "  1. create the github environment named 'release'"
echo "     gh api -X PUT repos/$NEW_ORG/$NEW_REPO/environments/release"
echo
echo "  2. apply rulesets on main and on release tags (requires admin):"
echo
cat <<EOF
       gh api -X POST repos/$NEW_ORG/$NEW_REPO/rulesets --input - <<'JSON'
       {
         "name": "main protection",
         "target": "branch",
         "enforcement": "active",
         "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
         "rules": [
           { "type": "deletion" },
           { "type": "non_fast_forward" },
           { "type": "required_linear_history" },
           { "type": "required_signatures" },
           { "type": "pull_request", "parameters": {
               "required_approving_review_count": 1,
               "dismiss_stale_reviews_on_push": true,
               "require_code_owner_review": true,
               "require_last_push_approval": false,
               "required_review_thread_resolution": false
           }},
           { "type": "required_status_checks", "parameters": {
               "required_status_checks": [
                 { "context": "ci" },
                 { "context": "pinned-actions" }
               ],
               "strict_required_status_checks_policy": true
           }}
         ]
       }
       JSON

       gh api -X POST repos/$NEW_ORG/$NEW_REPO/rulesets --input - <<'JSON'
       {
         "name": "release tag protection",
         "target": "tag",
         "enforcement": "active",
         "conditions": { "ref_name": { "include": ["refs/tags/v*"], "exclude": [] } },
         "rules": [
           { "type": "deletion" },
           { "type": "non_fast_forward" }
         ]
       }
       JSON
EOF
echo
echo "  3. configure npm trusted publisher at npmjs.com:"
echo "     https://docs.npmjs.com/trusted-publishers"
echo "       repository:        $NEW_ORG/$NEW_REPO"
echo "       workflow filename: release.yml"
echo "       environment name:  release"
echo
echo "  4. commit the rewrite, push, watch ci go green."
echo
echo "done."
