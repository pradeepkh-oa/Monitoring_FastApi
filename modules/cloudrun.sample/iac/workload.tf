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

# -- deployment of the GCR module
locals {
  service_name = "${local.app_name_short}-gcr-${local.module_name_short}-${local.region_id}-${local.project_env}"
}

resource "google_cloud_run_service" "default" {
  provider = google-beta
  name     = local.service_name
  location = local.region

  template {
    spec {
      containers {
        image = "gcr.io/${local.project}/${local.module_name}@${local.revision}"
        env {
          name  = "PROJECT"
          value = local.project
        }
        env {
          name  = "PROJECT_ENV"
          value = local.project_env
        }
        env {
          name  = "APP_NAME"
          value = local.app_name
        }
        env {
          name  = "APP_NAME_SHORT"
          value = local.app_name_short
        }
        env {
          name  = "MODULE_NAME"
          value = local.module_name
        }
        env {
          name  = "MODULE_NAME_SHORT"
          value = local.module_name_short
        }
        env {
          name  = "TIMEOUT"
          value = local.timeout
        }
        env {
          name  = "CONCURRENCY"
          value = local.concurrency
        }
        env {
          name  = "IDENTITY"
          value = google_service_account.default.email
        }
        env {
          name  = "SERVICE_URL"
          value = "https://${local.service_name}-${local.cloudrun_url_suffix}.a.run.app"
        }
        env {
          name  = "APIGEE_ACCESS_SECRET_ID"
          value = google_secret_manager_secret.apigee_access.id
        }
        env {
          name  = "APIGEE_SA"
          value = local.apigee_sa
        }
        resources {
          limits = {
            cpu    = "1000m"
            memory = "1024Mi"
          }
        }

      }
      service_account_name  = google_service_account.default.email
      container_concurrency = local.concurrency
      timeout_seconds       = local.timeout
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"     = "1000"
        "run.googleapis.com/startup-cpu-boost" = true
      }
      labels = {
        env     = local.project_env
        project = local.project
        module  = local.module_name
      }
    }
  }
  autogenerate_revision_name = true

  traffic {
    percent         = 100
    latest_revision = true
  }
}
