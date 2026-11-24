resource "google_project_service" "apis" {
  for_each = toset([
    "bigquery.googleapis.com",
    "dataform.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
  ])

  project = var.project_id
  service = each.value

  # Never switch an API off when this configuration is destroyed.
  disable_on_destroy = false
}
