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
echo "  1. configure npm trusted publisher"
echo "     https://docs.npmjs.com/trusted-publishers"
echo "       repository:  $NEW_ORG/$NEW_REPO"
echo "       workflow:    .github/workflows/release.yml"
echo "       environment: release"
echo
echo "  2. create the github environment named 'release'"
echo "     gh api -X PUT repos/$NEW_ORG/$NEW_REPO/environments/release"
echo
echo "  3. apply branch protection on main (one shot, requires admin):"
echo
cat <<EOF
       gh api -X PUT repos/$NEW_ORG/$NEW_REPO/branches/main/protection \\
         -F required_pull_request_reviews.required_approving_review_count=1 \\
         -F required_pull_request_reviews.dismiss_stale_reviews=true \\
         -F required_pull_request_reviews.require_code_owner_reviews=true \\
         -F required_status_checks.strict=true \\
         -F 'required_status_checks.contexts[]=ci' \\
         -F 'required_status_checks.contexts[]=pinned-actions' \\
         -F enforce_admins=true \\
         -F required_linear_history=true \\
         -F required_signatures.enabled=true \\
         -F allow_force_pushes=false \\
         -F allow_deletions=false
EOF
echo
echo "  4. commit the rewrite, push, watch ci go green."
echo
echo "done."
