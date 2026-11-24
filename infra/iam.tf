data "google_project" "this" {
  project_id = var.project_id
}

locals {
  # Google-managed service agent used by Dataform itself.
  dataform_agent = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# Account used by the scheduled workflow executions (required by strict act-as checks).
resource "google_service_account" "dataform_runner" {
  project      = var.project_id
  account_id   = "dataform-runner"
  display_name = "Dataform runner"

  depends_on = [google_project_service.apis]
}

# The runner creates and writes tables and launches BigQuery jobs.
resource "google_project_iam_member" "runner_bigquery" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.dataform_runner.email}"
}

# Dataform must be able to act as the runner.
resource "google_service_account_iam_member" "agent_acts_as_runner" {
  for_each = toset([
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
  ])

  service_account_id = google_service_account.dataform_runner.name
  role               = each.value
  member             = local.dataform_agent
}

# Dataform reads the GitHub token from Secret Manager.
resource "google_secret_manager_secret_iam_member" "agent_reads_github_token" {
  project   = var.project_id
  secret_id = var.github_token_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = local.dataform_agent
}
