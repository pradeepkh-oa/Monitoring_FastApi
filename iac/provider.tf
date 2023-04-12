# ======================================================================================== #
#    _____                  __                                  _    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    _ __ _ _ _____ _(_)__| |___ _ _
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | '_ \ '_/ _ \ V / / _` / -_) '_|
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| | .__/_| \___/\_/|_\__,_\___|_|
#                                             |_|
# ======================================================================================== #
# backend should always be GCS. It's configured from the CLI with:
# terraform init \
#   -backend-config=bucket=$DEPLOY_BUCKET \
#   -backend-config=prefix=terraform-state/global \
#   iac;
terraform {
  backend "gcs" {}
  required_version = "~> 1.3.7"

  required_providers {
    restapi = {
      source  = "mastercard/restapi"
      version = "1.16.1"
    }
  }
}

# google-beta provider is preferred to ensure the last functionalities
# are available
provider "google-beta" {
  project = local.project
  region  = local.region
  zone    = local.zone
}

# -- Get the GCR url suffix
data "google_storage_bucket_object_content" "cloudrun_url_suffix" {
  name   = "cloudrun-url-suffix/${local.region}"
  bucket = local.deploy_bucket
}

# -- Generate OAuth2 access token to call btdp APIs through apigee
## on global envs, access token is generated for user-defined cloudbuild SA (self)
## to call APIs through apigee
data "google_service_account_access_token" "cloudbuild_sa" {
  count = local.is_sbx ? 0 : 1

  provider               = google-beta
  target_service_account = local.cloudbuild_sa
  scopes                 = ["cloud-platform"]
}

# -- Creates the current project cloud workflows service account.
data "google_service_account" "workflows_sa" {
  project    = local.project
  account_id = "${local.app_name_short}-sa-workflows-${local.project_env}"
}
