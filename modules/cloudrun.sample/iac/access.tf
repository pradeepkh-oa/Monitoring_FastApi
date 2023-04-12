# ======================================================================================== #
#    _____                  __                   _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __     /_\  __ __ ___ ______
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   / _ \/ _/ _/ -_|_-<_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| /_/ \_\__\__\___/__/__/
#
# ======================================================================================== #
# To provide permissions on this module to other service accounts, or groups
# N.B. For members that are external to this project, please prefer setup/access

# -- Apigee direct access with service url
resource "google_cloud_run_service_iam_member" "apigee_invoker_permission" {
  count    = local.apigee_sa == null ? 0 : 1
  provider = google-beta
  location = local.region
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.apigee_sa}"
}


# -- Secret used to control the access to the module for requests sent through Apigee
resource "google_secret_manager_secret" "apigee_access" {
  provider  = google-beta
  secret_id = "${local.app_name_short}-srt-${local.module_name_short}_externalpermission_chk-${local.project_env}"
  replication {
    automatic = true
  }
  labels = {
    env     = local.project_env
    module  = local.module_name
    purpose = "apigee-access-control"
  }
}

# Mandatory: a secret cannot be accessed without version
resource "google_secret_manager_secret_version" "apigee_access_content" {
  provider    = google-beta
  secret      = google_secret_manager_secret.apigee_access.id
  secret_data = "ok"
}

resource "google_secret_manager_secret_iam_member" "apigee_authorized_members" {
  for_each  = local.apigee_authorized_groups
  provider  = google-beta
  secret_id = google_secret_manager_secret.apigee_access.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "group:${each.value}"
}
