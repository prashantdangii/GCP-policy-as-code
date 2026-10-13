terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.6"
    }
  }
}

provider "google" {
  region                = var.region
  billing_project       = var.scope_type == "project" ? var.scope_id : null
  user_project_override = var.scope_type == "project"
}
