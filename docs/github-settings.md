# github ui settings (one-time, per fork)

config that lives only in github settings, not in repo files.
apply once after `init.sh`. each section says where to click.

## settings -> general

| setting                                         | value                        |
| ----------------------------------------------- | ---------------------------- |
| features: wikis                                 | off                          |
| features: issues                                | on (only if you triage them) |
| features: discussions                           | on (only if you use them)    |
| features: projects                              | off (unless used)            |
| pull requests: allow merge commits              | off                          |
| pull requests: allow squash merging             | on                           |
| pull requests: allow rebase merging             | on                           |
| pull requests: always suggest updating branches | on                           |
| pull requests: automatically delete head branch | on                           |
| archives: include git lfs objects               | off                          |

## settings -> rules -> rulesets

apply two rulesets: one for the default branch, one for release tags.
see [branch-protection.md](./branch-protection.md) for the exact settings
and the `gh api` calls. classic `Settings → Branches → Branch protection
rules` still works but rulesets are the supported path going forward and
are required for tag protection.

## settings -> code security

since 2024 this page is a list of cards rather than a single toggle column.
turn each card on:

| card                                       | action                                   |
| ------------------------------------------ | ---------------------------------------- |
| dependabot alerts                          | enable                                   |
| dependabot security updates                | enable                                   |
| dependabot version updates                 | already configured via `.github/dependabot.yml` |
| secret scanning                            | enable                                   |
| secret scanning push protection            | enable                                   |
| code scanning (codeql)                     | "set up" -> default                      |
| private vulnerability reporting            | enable                                   |

`code scanning -> default setup` is now one click and covers every
language github detects. choose default unless you have a reason to
write your own `codeql.yml`.

`SECURITY.md` already wires private vulnerability reporting; flipping
the toggle exposes the form to reporters.

## settings -> actions -> general

| setting                                            | value                                                                              |
| -------------------------------------------------- | ---------------------------------------------------------------------------------- |
| actions permissions                                | "allow `<your-org>` actions and reusable workflows, and select non-`<your-org>` actions and reusable workflows" |
| allowed actions                                    | enumerate by full name (see below)                                                 |
| approval for fork pull request workflows           | "require approval for first-time contributors" (or stricter)                       |
| run workflows from fork pull requests              | leave default; rely on the approval gate above                                     |
| send write tokens to fork pull request workflows   | off                                                                                |
| send secrets and variables to fork pull request workflows | off                                                                         |
| workflow permissions                               | "read repository contents and packages permissions"                                |
| allow github actions to create or approve pull requests | off                                                                           |

allowed actions list (paste, after `init.sh` pins them):

```text
slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@*
ossf/scorecard-action@*
github/codeql-action/upload-sarif@*
sigstore/cosign-installer@*
step-security/harden-runner@*
softprops/action-gh-release@*
actions/checkout@*
actions/setup-node@*
actions/upload-artifact@*
actions/download-artifact@*
```

`*` is github's allowed-actions wildcard, not a sha. the sha is enforced
by `scripts/check-pins.sh` in ci.

## settings -> environments -> release

create the `release` environment used by `release.yml`. set:

| setting                       | value                                         |
| ----------------------------- | --------------------------------------------- |
| required reviewers            | at least 1 maintainer                         |
| wait timer                    | 5 minutes (rollback window)                   |
| prevent self-review           | off for solo maintainer, on if more than one  |
| deployment branches and tags  | "selected branches and tags" -> add `v*`      |
| environment secrets           | none (oidc replaces tokens)                   |
| environment variables         | none unless required                          |

reviewers must approve every release before npm publish runs. the wait
timer gives you a final five-minute window to cancel the deploy from
the actions tab.

## settings -> webhooks

webhooks should be empty. every webhook is an outbound trust point.
if you need ci notifications, prefer github built-ins (slack github app,
github email).

## settings -> deploy keys

deploy keys should be empty. deploy keys never rotate.
use github app installations or oidc workloads instead.

## settings -> integrations and third-party access

| setting                | value                              |
| ---------------------- | ---------------------------------- |
| github apps            | review installed apps quarterly    |
| oauth apps             | none unless required               |
| third-party tokens     | restrict to vetted apps            |

## npmjs.com -> package -> settings -> trusted publisher

set this once per package on npmjs.com. there is no ci file to commit.

| field                | value                            |
| -------------------- | -------------------------------- |
| publisher            | github actions                   |
| repository owner     | `<your-org>`                     |
| repository name      | `<your-repo>`                    |
| workflow filename    | `release.yml`                    |
| environment name     | `release`                        |

once trusted publisher is configured, `npm publish --provenance` in
`release.yml` mints credentials over oidc per run. there is no
`NPM_TOKEN` and never will be.

## organization-level (if you own the org)

beyond the repo, set these org-wide:

| setting                             | value                                             |
| ----------------------------------- | ------------------------------------------------- |
| require two-factor authentication   | on for all members                                |
| require sso                         | on if your idp supports it                        |
| restrict member repository creation | on (route via templates)                          |
| restrict member repository forking  | as policy dictates                                |
| organization secrets                | scope to specific repos, never "all repositories" |
| outside collaborators               | minimize, audit quarterly                         |
| sso session duration                | as short as your team tolerates                   |

org-level rulesets (`Settings → Rules → Rulesets` at the org) let you
apply the main-branch protection across every repo at once instead of
per-repo. recommended once you operate more than a handful of repos.

## verifying

after applying everything, run the [openssf scorecard](https://securityscorecards.dev)
on your repo. target score: **8.5+**. anything below means a check above
was missed (or a check that needs time, like `Maintained` which requires
the repo to be 90+ days old).
