# security policy

## supported versions

sigil is a template repository. the only supported version is the latest commit on `main`.
downstream forks are responsible for their own release lines.

## reporting a vulnerability

use github private vulnerability reporting:

1. open <https://github.com/0-draft/sigil/security/advisories/new>
2. include reproduction steps and affected commit sha
3. expect an acknowledgement within 72 hours

do not open public issues for security reports.

## scope

in scope:

- the workflow templates under `.github/workflows/`
- the bootstrap scripts under `scripts/`
- the library code under `src/`

out of scope:

- forks of sigil after `init.sh` has been run (you own those)
- third-party actions referenced from sigil workflows (report to the action owner)

## what sigil itself defends against

sigil ships defenses for the six surfaces enumerated in
[chainscope](https://github.com/0-draft/chainscope).
when reporting, indicate which surface the issue concerns:
source, deps, build, publish, distribute, or consume.
