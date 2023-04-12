# ======================================================================================== #
#    _____                  __                 ___     _           _      _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   / __| __| |_  ___ __| |_  _| |___ _ _ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  \__ \/ _| ' \/ -_) _` | || | / -_) '_(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |___/\__|_||_\___\__,_|\_,_|_\___|_| /__/
#
# ======================================================================================== #

# (optionnal) scheduler to call the Cloud Functions v2
resource "google_cloud_scheduler_job" "scheduler" {
  name        = "${local.app_name_short}-sch-templategcfv2-${local.region_id}-${local.project_env}"
  project     = local.project
  region      = local.region
  schedule    = "0 0 * * *"
  description = "Template scheduler for Cloud Functions v2"

  retry_config {
    retry_count = 5
  }

  http_target {
    uri         = google_cloudfunctions2_function.default.service_config[0].uri
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.default.email
      audience              = google_cloudfunctions2_function.default.service_config[0].uri
    }
  }

  depends_on = [
    google_cloudfunctions2_function_iam_member.self_invoker
  ]
}
