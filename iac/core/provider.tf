# ======================================================================================== #
#     ___               ___             _    _
#    / __|___ _ _ ___  | _ \_ _ _____ _(_)__| |___ _ _
#   | (__/ _ \ '_/ -_) |  _/ '_/ _ \ V / / _` / -_) '_|
#    \___\___/_| \___| |_| |_| \___/\_/|_\__,_\___|_|
#
# ======================================================================================== #

terraform {
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
provider "google" {
  project = local.project
  region  = local.region
  zone    = local.zone
}

# load meta data about the project
data "google_project" "default" {
  provider = google-beta
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
## on sandbox, associated resources are not deployed for now
