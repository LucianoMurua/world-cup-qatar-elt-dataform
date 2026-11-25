output "wif_provider" {
  description = "Value for the WIF_PROVIDER GitHub Actions variable."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "ci_plan_service_account" {
  description = "Value for the CI_PLAN_SA GitHub Actions variable."
  value       = google_service_account.ci_plan.email
}

output "ci_apply_service_account" {
  description = "Value for the CI_APPLY_SA GitHub Actions variable."
  value       = google_service_account.ci_apply.email
}
