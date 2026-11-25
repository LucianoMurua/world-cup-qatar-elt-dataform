# Workload Identity Federation: lets GitHub Actions authenticate to Google Cloud
# with short-lived tokens, so no service account key is ever created or stored.

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Only tokens issued for this repository are accepted.
  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Two identities with different power:
#  - ci_plan:  read-only, used by pull requests to run `terraform plan`.
#  - ci_apply: can change infrastructure, only reachable from the main branch.
resource "google_service_account" "ci_plan" {
  project      = var.project_id
  account_id   = "github-ci-plan"
  display_name = "GitHub CI (plan, read-only)"

  depends_on = [google_project_service.apis]
}

resource "google_service_account" "ci_apply" {
  project      = var.project_id
  account_id   = "github-ci-apply"
  display_name = "GitHub CI (apply, main branch only)"

  depends_on = [google_project_service.apis]
}

# Who can impersonate each service account.
resource "google_service_account_iam_member" "ci_plan_wif" {
  service_account_id = google_service_account.ci_plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

resource "google_service_account_iam_member" "ci_apply_wif" {
  service_account_id = google_service_account.ci_apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.ref/refs/heads/main"
}

locals {
  ci_plan_roles = [
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/iam.workloadIdentityPoolViewer",
    "roles/dataform.viewer",
  ]

  # The apply account can only view (not change) the Workload Identity pool,
  # so the CI cannot modify its own trust configuration.
  ci_apply_roles = [
    "roles/viewer",
    "roles/bigquery.dataOwner",
    "roles/dataform.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.workloadIdentityPoolViewer",
    "roles/resourcemanager.projectIamAdmin",
    "roles/secretmanager.admin",
    "roles/serviceusage.serviceUsageAdmin",
  ]
}

resource "google_project_iam_member" "ci_plan" {
  for_each = toset(local.ci_plan_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci_plan.email}"
}

resource "google_project_iam_member" "ci_apply" {
  for_each = toset(local.ci_apply_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci_apply.email}"
}

# Terraform state: plan only reads it, apply reads and writes it (and the lock).
resource "google_storage_bucket_iam_member" "ci_plan_state" {
  bucket = var.tf_state_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ci_plan.email}"
}

resource "google_storage_bucket_iam_member" "ci_apply_state" {
  bucket = var.tf_state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci_apply.email}"
}

# Needed to create or update workflow configurations that run as dataform-runner.
resource "google_service_account_iam_member" "ci_apply_acts_as_runner" {
  service_account_id = google_service_account.dataform_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.ci_apply.email}"
}
