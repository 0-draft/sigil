# branch and tag protection (one-time, applied via api)

github does not let you commit branch protection to a repo. you set it once
in `Settings → Rules → Rulesets` (recommended) or, for legacy setups,
`Settings → Branches → Branch protection rules`.

sigil expects two rulesets: one on `main` and one on every release tag (`v*`).
both block force-push and deletion; the branch ruleset additionally requires
review, signed commits, linear history, and the `ci` / `pinned-actions` status
checks.

## main branch ruleset

| setting                                     | value                                  |
| ------------------------------------------- | -------------------------------------- |
| target                                      | branch                                 |
| target branches                             | default branch                         |
| enforcement                                 | active                                 |
| restrict deletions                          | on                                     |
| block force pushes                          | on                                     |
| require linear history                      | on                                     |
| require signed commits                      | on                                     |
| require a pull request before merging       | on                                     |
| required approvals                          | 1                                      |
| dismiss stale reviews on push               | on                                     |
| require review from codeowners              | on                                     |
| require status checks to pass               | `ci`, `pinned-actions`                 |
| require branches to be up to date           | on                                     |
| bypass list                                 | empty (no admin bypass)                |

## release tag ruleset

| setting                | value                |
| ---------------------- | -------------------- |
| target                 | tag                  |
| target tags            | `refs/tags/v*`       |
| enforcement            | active               |
| restrict deletions     | on                   |
| block force pushes     | on                   |
| bypass list            | empty                |

tag protection prevents an attacker (or careless rebase) from moving `v0.0.1`
to a different commit after release. the signature attached to the tarball
becomes pointless if the tag itself is mutable.

## apply via cli

requires `gh` and admin scope on the repo. paste both calls.

```bash
ORG=<your-org>; REPO=<your-repo>

# main branch ruleset
gh api -X POST "repos/$ORG/$REPO/rulesets" --input - <<'EOF'
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
EOF

# release tag ruleset
gh api -X POST "repos/$ORG/$REPO/rulesets" --input - <<'EOF'
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
EOF
```

`scripts/init.sh` prints both calls at the end with your org/repo substituted.

## why rulesets, not classic branch protection

both satisfy the openssf scorecard `Branch-Protection` check. but rulesets
are where github is investing: tag targeting, org-level rules, layered
bypass lists with audit trails. if you start a new repo today, start with
rulesets. classic branch protection still works on existing repos.
