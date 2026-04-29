#!/usr/bin/env bash
# verify.sh — consumer-side proof check for a sigil-shaped npm package.
# checks three independent attestations:
#   1. registry-served sigstore attestation  (npm audit signatures)
#   2. cosign sign-blob, oidc identity pinned to the release workflow
#   3. slsa v1.0 provenance                  (slsa-verifier verify-npm-package)
#
# any failure -> non-zero exit. install rejected.
#
# usage:
#   ./verify.sh @<org>/<repo>@1.0.0
#   ./verify.sh @<org>/<repo>            # latest
#
# env:
#   EXPECTED_ISSUER          default: https://token.actions.githubusercontent.com
#   EXPECTED_SUBJECT_REGEX   default: any release.yml on a v* tag

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <package-spec>"
  exit 1
fi

SPEC="$1"
EXPECTED_ISSUER="${EXPECTED_ISSUER:-https://token.actions.githubusercontent.com}"
EXPECTED_SUBJECT_REGEX="${EXPECTED_SUBJECT_REGEX:-^https://github.com/[^/]+/[^/]+/.github/workflows/release.yml@refs/tags/v.*$}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1"; exit 1; }; }
need npm
need cosign
need slsa-verifier
need gh
need jq

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> 1/3 npm audit signatures"
(
  cd "$WORK"
  npm init -y >/dev/null 2>&1
  npm install --ignore-scripts --no-save "$SPEC" >/dev/null 2>&1
  npm audit signatures
)
echo "    ok"

echo "==> 2/3 cosign verify-blob"
GH_URL="$(npm view "$SPEC" repository.url 2>/dev/null | sed 's|^git+||; s|\.git$||')"
GH_REPO="${GH_URL#https://github.com/}"
VERSION="$(npm view "$SPEC" version 2>/dev/null)"
TARBALL="$(cd "$WORK" && npm pack "$SPEC" --silent | tail -n 1)"

gh release download "v${VERSION}" \
  -R "$GH_REPO" \
  -D "$WORK" \
  -p "${TARBALL}.sigstore.json" \
  -p "${TARBALL}.intoto.jsonl" 2>/dev/null || true

if [ ! -f "$WORK/${TARBALL}.sigstore.json" ]; then
  echo "    missing ${TARBALL}.sigstore.json on github release v${VERSION} of ${GH_REPO}"
  exit 1
fi

cosign verify-blob \
  --certificate-identity-regexp "$EXPECTED_SUBJECT_REGEX" \
  --certificate-oidc-issuer "$EXPECTED_ISSUER" \
  --bundle "$WORK/${TARBALL}.sigstore.json" \
  "$WORK/${TARBALL}"
echo "    ok"

echo "==> 3/3 slsa-verifier verify-npm-package"
if [ ! -f "$WORK/${TARBALL}.intoto.jsonl" ]; then
  echo "    missing ${TARBALL}.intoto.jsonl on github release v${VERSION} of ${GH_REPO}"
  exit 1
fi

slsa-verifier verify-npm-package "$WORK/${TARBALL}" \
  --attestations-path "$WORK/${TARBALL}.intoto.jsonl" \
  --source-uri "github.com/${GH_REPO}"
echo "    ok"

echo
echo "all three attestations passed. ${SPEC} is vouched for."
