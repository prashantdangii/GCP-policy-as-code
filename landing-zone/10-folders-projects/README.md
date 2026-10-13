# 10-folders-projects

Creates three folders and six projects when `scope_type` is `organization` or `folder`.

| Folder | Projects |
| --- | --- |
| `prod` | `app-prod-sample`, `data-sample` |
| `nonprod` | `app-nonprod-sample` |
| `shared-services` | `logging-hub`, `network-hub`, `sec-tooling` |

Every project gets labels `owner`, `env`, `cost-center`, and `data-classification`. `deletion_policy` is `PREVENT`. The default network is not created. Only the APIs that later stacks need are enabled, and `disable_on_destroy` is false so a destroy does not turn APIs off under active resources.

## Project-only labs

Set `scope_type = "project"` and `scope_id` to the existing project. No folders or projects are created. Outputs map every logical name to that project so downstream stacks still have ids to copy. This mode is the no-org path from ADR 0004.

`project_prefix` is 1-10 characters. The longest id, `app-nonprod-sample`, then stays within the 30-character project-id limit.
