# contributing to sigil

sigil is a template. contributions improve the template itself, not downstream forks.

## ground rules

- every commit must be signed. this repo enforces `git config commit.gpgsign true` or sigstore `gitsign`.
- third-party actions must be referenced by full commit sha, never by tag. dependabot bumps the sha; the comment retains the tag for human readability.
- workflow changes require an example of the resulting attestation (rekor entry url or in-toto bundle) in the pr body.
- ai-generated prose is fine; ai-generated commits are not. if you used an assistant, your commit must still be signed by you.

## development

```bash
npm ci
npm run check    # lint + typecheck + test + audit + build
```

`npm run check` is what ci runs. run it before pushing.

## release

releases are cut by tagging `v*` on `main`. the tag triggers `.github/workflows/release.yml`,
which publishes to npm with provenance, signs the tarball with sigstore, and produces a
slsa v1.0 provenance attestation. there is no manual `npm publish` path. there is no
`NPM_TOKEN` secret in this repository.

## reporting issues

bugs in the template: open a public issue.
security issues in the template: see [security.md](./SECURITY.md).
