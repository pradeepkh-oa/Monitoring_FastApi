# ======================================================================================== #
#    _____                  __                __      __       _   _              _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   \ \    / /__ _ _| |_| |___  __ _ __| |
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   \ \/\/ / _ \ '_| / / / _ \/ _` / _` |
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   \_/\_/\___/_| |_\_\_\___/\__,_\__,_|
#
# ======================================================================================== #

# -- main service account of the workload
resource "google_service_account" "default" {
  provider     = google-beta
  account_id   = "${local.app_name_short}-sa-${local.module_name_short}-${local.project_env}"
  display_name = "Main identity for ${local.module_name} service"
}

# -- deployment of the GCF v2 module
locals {
  service_name = "${local.app_name_short}-gcf-${local.module_name_short}-${local.region_id}-${local.project_env}"
}
resource "google_cloudfunctions2_function" "default" {
  provider    = google-beta
  name        = local.service_name
  location    = local.region
  description = "Demo sample for Google Function v2"

  build_config {
    runtime     = "python310"
    entry_point = "main"
    source {
      storage_source {
        bucket = local.deploy_bucket
        object = "terraform-state/${local.module_name}/gcf-src_${local.revision}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "512Mi"
    timeout_seconds       = local.timeout
    service_account_email = google_service_account.default.email
    environment_variables = {
      PROJECT           = local.project
      PROJECT_ENV       = local.project_env
      APP_NAME          = local.app_name
      APP_NAME_SHORT    = local.app_name_short
      MODULE_NAME       = local.module_name
      MODULE_NAME_SHORT = local.module_name_short
      SERVICE_URL       = "https://${local.service_name}-${local.cloudrun_url_suffix}.a.run.app"
      IDENTITY          = google_service_account.default.email
      TIMEOUT           = local.timeout
    }
  }
  labels = {
    env     = local.project_env
    project = local.project
    module  = local.module_name
  }
}
