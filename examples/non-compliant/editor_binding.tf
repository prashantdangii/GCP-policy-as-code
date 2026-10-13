# Expected policy: IAM-001 (no-primitive-roles).
# roles/editor on a project.

resource "google_project_iam_member" "editor" {
  project = "PROJECT_PREFIX-app-prod-sample"
  role    = "roles/editor"
  member  = "group:app-admins@example.com"
}
