# ADR 0004: Organization, folder, or project scope

- Status: Accepted
- Date: 2026-10-13

## Context

A landing zone is an organization pattern. A portfolio lab often has only a project, because Cloud Identity and an organization are a human step. Policies written as `organizations/ORG_ID` only would not `validate` into a useful plan for that lab, and they would teach the wrong lesson that org policy requires an org resource in the same state.

## Decision

`var.scope_type` is `organization`, `folder`, or `project`, and `var.scope_id` is the raw id. Org policies, logging sinks, and IAM use that parent. `10-folders-projects` creates folders and projects only when the scope is not `project`; in project mode every logical name points at the one project. Custom roles are organization or project, because Cloud Resource Manager has no folder custom role. The IAM stack rejects `folder` for that reason. VPC Service Controls stay off unless `enable_vpc_sc` is true, and that path still requires an organization access policy.

## Alternatives considered

- Organization only. Smaller code, and the repo is useless without Cloud Identity.
- Project only. Loses folder inheritance, aggregated sinks with `include_children`, and the org-policy story.
- Separate repos per scope. More moving parts than a single variable.

## Consequences

- Security: a project-scoped lab does not inherit org policies onto other projects. The README says so.
- Cost: project mode creates no extra projects.
- Operability: examples use `ORG_ID` and `PROJECT_PREFIX` placeholders. The tfvars examples show both shapes.
