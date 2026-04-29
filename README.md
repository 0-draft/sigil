<div align="center">

<img src="./assets/sigil-mark.svg" alt="sigil" width="160" />

# sigil

*every release under signature.*

[![scorecard](https://api.securityscorecards.dev/projects/github.com/0-draft/sigil/badge)](https://securityscorecards.dev/viewer/?uri=github.com/0-draft/sigil)
[![ci](https://github.com/0-draft/sigil/actions/workflows/ci.yml/badge.svg)](https://github.com/0-draft/sigil/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

</div>

fork it. push. your release ships with sigstore signatures, slsa v1.0 provenance, and npm trusted publisher.
no `NPM_TOKEN`. no path to publish without provenance.

## the chain

```mermaid
flowchart TB
    src["1. source<br/>gitsign + signed-commit branch protection"]
    deps["2. deps<br/>npm ci --ignore-scripts + lockfile + dependabot"]
    bld["3. build<br/>harden-runner + SHA-pinned actions"]
    pub["4. publish<br/>npm OIDC --provenance + cosign sign-blob"]
    dst["5. distribute<br/>npm registry attestation"]
    con["6. consume<br/>verify.sh: audit + cosign + slsa-verifier"]

    src --> deps --> bld --> pub --> dst --> con

    classDef src  fill:#f05032,stroke:#000,color:#fff
    classDef deps fill:#cb3837,stroke:#000,color:#fff
    classDef bld  fill:#fbca04,stroke:#000,color:#000
    classDef pub  fill:#2ea44f,stroke:#000,color:#fff
    classDef dst  fill:#7a52d6,stroke:#000,color:#fff
    classDef con  fill:#326ce5,stroke:#000,color:#fff

    class src src
    class deps deps
    class bld bld
    class pub pub
    class dst dst
    class con con
```

if any link breaks, the next step refuses the input. that is the only behaviour.

## use this template

```bash
# 1. click "Use this template" on github
# 2. clone your new repo
git clone https://github.com/<you>/<your-repo>.git
cd <your-repo>

# 3. rename + sha-pin every action
./scripts/init.sh <your-org> <your-repo>

# 4. install + verify locally
npm ci
npm run check

# 5. configure npm trusted publisher on npmjs.com
#    settings -> packages -> add trusted publisher
#    repository:  <your-org>/<your-repo>
#    workflow:    .github/workflows/release.yml
#    environment: release
```

`init.sh` prints the `gh api` one-liner to apply branch protection. run it.

## verify a release (consumer side)

```bash
./scripts/verify.sh @<org>/<repo>@1.0.0
```

three independent proofs, three exit codes:

1. `npm audit signatures` — registry-served sigstore attestation
2. `cosign verify-blob` — workflow identity pinned via OIDC
3. `slsa-verifier verify-npm-package` — slsa v1.0 provenance

any one fails -> non-zero -> install rejected.

## see also

- [chainscope](https://github.com/0-draft/chainscope) for the conceptual map
- [docs/github-settings.md](./docs/github-settings.md) for the one-time UI hardening
- [docs/branch-protection.md](./docs/branch-protection.md) for the branch protection api call
- [SECURITY.md](./SECURITY.md) for vulnerability reporting
- [CONTRIBUTING.md](./CONTRIBUTING.md) for contributor rules
- [MIT](./LICENSE)
