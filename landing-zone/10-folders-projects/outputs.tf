output "folder_ids" {
  description = "Folder resource names. Empty when scope_type is project."
  value       = { for key, folder in google_folder.env : key => folder.name }
}

output "project_ids" {
  description = "Logical project name to project id. In project scope every name points at scope_id."
  value = local.create_hierarchy ? {
    for key, project in google_project.projects : key => project.project_id
    } : {
    for key, _ in local.projects : key => var.scope_id
  }
}

output "project_numbers" {
  description = "Logical project name to project number. Null in project-only mode because this stack does not read the existing project."
  value = local.create_hierarchy ? {
    for key, project in google_project.projects : key => project.number
  } : {}
}
