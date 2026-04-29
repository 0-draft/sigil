# branch protection settings (manual, applied once)

github does not let you commit branch protection rules to a repo. you set
them in `Settings → Branches → Branch protection rules` (or via the api).
sigil expects these on `main`:

| setting                                 | value                                  |
| --------------------------------------- | -------------------------------------- |
| require a pull request before merging   | on                                     |
| require approvals                       | 1                                      |
| dismiss stale reviews on new commits    | on                                     |
| require review from codeowners          | on                                     |
| require status checks to pass           | `ci` and `pinned-actions`              |
| require branches to be up to date       | on                                     |
| require signed commits                  | on                                     |
| require linear history                  | on                                     |
| do not allow bypassing the above        | on (no admin bypass)                   |
| restrict who can push to matching       | maintainers only                       |
| allow force pushes                      | off                                    |
| allow deletions                         | off                                    |

apply once via the cli (requires `gh` and admin scope):

```bash
gh api -X PUT repos/<org>/<repo>/branches/main/protection \
  -F required_pull_request_reviews.required_approving_review_count=1 \
  -F required_pull_request_reviews.dismiss_stale_reviews=true \
  -F required_pull_request_reviews.require_code_owner_reviews=true \
  -F required_status_checks.strict=true \
  -F 'required_status_checks.contexts[]=ci' \
  -F 'required_status_checks.contexts[]=pinned-actions' \
  -F enforce_admins=true \
  -F required_linear_history=true \
  -F required_signatures.enabled=true \
  -F allow_force_pushes=false \
  -F allow_deletions=false
```

`scripts/init.sh` prints this command at the end with your org/repo substituted.
