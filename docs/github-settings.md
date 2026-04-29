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

## settings -> branches

apply branch protection on `main`. see [branch-protection.md](./branch-protection.md)
for the full setting list and a `gh api` one-liner.

## settings -> code security

| setting                         | value                                     |
| ------------------------------- | ----------------------------------------- |
| dependabot alerts               | on                                        |
| dependabot security updates     | on                                        |
| dependabot version updates      | on (auto, reads `.github/dependabot.yml`) |
| secret scanning                 | on                                        |
| secret scanning push protection | on                                        |
| code scanning (codeql)          | on                                        |
| private vulnerability reporting | on                                        |

`SECURITY.md` already wires private vulnerability reporting; flipping the toggle
exposes the form to reporters.

## settings -> actions -> general

| setting                                          | value                                                                              |
| ------------------------------------------------ | ---------------------------------------------------------------------------------- |
| actions permissions                              | `allow <your-org>, and select non-<your-org> actions and reusable workflows`       |
| allowed actions                                  | enumerate by full name and sha (see below)                                         |
| fork pull request workflows from outside collabs | "require approval for first-time contributors who are new to github" (or stricter) |
| workflow permissions                             | "read repository contents and packages permissions" (default to read)              |
| allow github actions to create / approve prs     | off                                                                                |

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

`*` is github's allowed-actions wildcard, not a sha. the sha is enforced by
`scripts/check-pins.sh` in ci.

## settings -> environments -> release

create the `release` environment used by `release.yml`. set:

| setting                      | value                            |
| ---------------------------- | -------------------------------- |
| required reviewers           | at least 1 maintainer            |
| wait timer                   | 5 minutes (rollback window)      |
| deployment branches and tags | protected branches and tags only |
| environment secrets          | none (oidc replaces tokens)      |
| environment variables        | none unless required             |

reviewers must approve every release before npm publish runs.

## settings -> webhooks

webhooks should be empty. every webhook is an outbound trust point.
if you need ci notifications, prefer github built-ins (slack github app, github email).

## settings -> deploy keys

deploy keys should be empty. deploy keys never rotate.
use github app installations or oidc workloads instead.

## settings -> integrations and third-party access

| setting            | value                           |
| ------------------ | ------------------------------- |
| third-party access | restrict to vetted apps         |
| github apps        | review installed apps quarterly |
| oauth apps         | none unless required            |

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

## verifying

after applying everything, run the [openssf scorecard](https://securityscorecards.dev)
on your repo. target score: **8.5+**. anything below means a check above was missed.
