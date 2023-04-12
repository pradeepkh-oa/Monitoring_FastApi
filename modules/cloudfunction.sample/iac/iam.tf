# ======================================================================================== #
#    _____                  __                 ___   _   __  __
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   |_ _| /_\ |  \/  |
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   | | / _ \| |\/| |
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |___/_/ \_\_|  |_|
#
# ======================================================================================== #
# To provide permissions to this module service account

# -- self-invocation
# Additional permissions to act as itself with other Google services
resource "google_service_account_iam_member" "act_as_itself" {
  for_each = toset([
    "iam.serviceAccountUser",
    "iam.serviceAccountTokenCreator",
  ])
  provider           = google-beta
  service_account_id = google_service_account.default.name
  role               = "roles/${each.key}"
  member             = "serviceAccount:${google_service_account.default.email}"
}

# -- function specific permissions
resource "google_cloudfunctions_function_iam_member" "self_invoker" {
  for_each = toset([
    "cloudfunctions.invoker",
    # ...
  ])
  provider       = google-beta
  project        = local.project
  region         = local.region
  cloud_function = google_cloudfunctions_function.default.name

  role   = "roles/${each.key}"
  member = "serviceAccount:${google_service_account.default.email}"
}

# -- Global project permissions
resource "google_project_iam_member" "permissions" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/errorreporting.writer",
    # ...
  ])
  provider = google-beta
  project  = local.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.default.email}"
}

# -- Others
# ...
