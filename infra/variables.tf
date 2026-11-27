variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Location for the BigQuery datasets and the Dataform repository (must be the same)."
  type        = string
  default     = "us-central1"
}

variable "dataset_prefix" {
  description = "Prefix of the three BigQuery datasets (<prefix>_raw, <prefix>_dataform, <prefix>_dataform_assertions)."
  type        = string
  default     = "qatar_wc"
}

variable "dataform_repo_name" {
  description = "Name of the Dataform repository."
  type        = string
  default     = "world-cup-qatar-elt-dataform"
}

variable "github_repo_url" {
  description = "HTTPS URL of the GitHub repository connected to Dataform."
  type        = string
}

variable "github_token_secret_name" {
  description = "Name of the existing Secret Manager secret that holds the GitHub token. Only the name is used, the value never enters Terraform."
  type        = string
}

variable "time_zone" {
  description = "Time zone of the Dataform schedules (same alias Dataform already stores)."
  type        = string
  default     = "America/Cordoba"
}

variable "github_repository" {
  description = "GitHub repository allowed to authenticate through Workload Identity Federation, as OWNER/NAME (exact case)."
  type        = string
}

variable "tf_state_bucket" {
  description = "Name of the GCS bucket that holds the Terraform state. Used to grant the CI service accounts access to it."
  type        = string
}
