# Remote state in GCS. The bucket and prefix are passed at init time so no
# project-specific value is committed:
#
#   terraform init \
#     -backend-config="bucket=<your-state-bucket>" \
#     -backend-config="prefix=world-cup-dataform"
terraform {
  backend "gcs" {}
}
