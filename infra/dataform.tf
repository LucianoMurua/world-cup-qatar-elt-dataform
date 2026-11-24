locals {
  github_token_secret_version = "projects/${data.google_project.this.number}/secrets/${var.github_token_secret_name}/versions/latest"
}

resource "google_dataform_repository" "repo" {
  provider = google-beta

  project = var.project_id
  region  = var.region
  name    = var.dataform_repo_name

  git_remote_settings {
    url                                 = var.github_repo_url
    default_branch                      = "main"
    authentication_token_secret_version = local.github_token_secret_version
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_iam_member.agent_reads_github_token,
  ]
}

# Compiles branch `main` every Monday at 05:00.
resource "google_dataform_repository_release_config" "production" {
  provider = google-beta

  project    = var.project_id
  region     = var.region
  repository = google_dataform_repository.repo.name

  name          = "production"
  git_commitish = "main"
  cron_schedule = "0 5 * * 1"
  time_zone     = var.time_zone
}

# Runs every action of the released compilation every Monday at 06:00.
resource "google_dataform_repository_workflow_config" "weekly_full_refresh" {
  provider = google-beta

  project    = var.project_id
  region     = var.region
  repository = google_dataform_repository.repo.name

  name           = "weekly_full_refresh"
  release_config = google_dataform_repository_release_config.production.id
  cron_schedule  = "0 6 * * 1"
  time_zone      = var.time_zone

  invocation_config {
    service_account = google_service_account.dataform_runner.email
  }

  depends_on = [google_service_account_iam_member.agent_acts_as_runner]
}

# Runs only the actions tagged `data_quality`. No schedule: triggered manually.
resource "google_dataform_repository_workflow_config" "data_quality_only" {
  provider = google-beta

  project    = var.project_id
  region     = var.region
  repository = google_dataform_repository.repo.name

  name           = "data_quality_only"
  release_config = google_dataform_repository_release_config.production.id

  invocation_config {
    included_tags   = ["data_quality"]
    service_account = google_service_account.dataform_runner.email
  }

  depends_on = [google_service_account_iam_member.agent_acts_as_runner]
}
