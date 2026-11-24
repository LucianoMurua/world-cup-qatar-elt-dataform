locals {
  datasets = {
    raw = {
      id          = "${var.dataset_prefix}_raw"
      description = "Raw data"
    }
    dataform = {
      id          = "${var.dataset_prefix}_dataform"
      description = "Dataform output"
    }
    assertions = {
      id          = "${var.dataset_prefix}_dataform_assertions"
      description = "Dataform assertions"
    }
  }
}

resource "google_bigquery_dataset" "datasets" {
  for_each = local.datasets

  project     = var.project_id
  dataset_id  = each.value.id
  location    = var.region
  description = each.value.description

  # Terraform refuses to delete a dataset that still contains tables.
  delete_contents_on_destroy = false

  depends_on = [google_project_service.apis]
}
