# ======================================================================================== #
#    _____                  __                 ___     _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | _ \___| |___ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  |   / _ \ / -_|_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |_|_\___/_\___/__/
#
# ======================================================================================== #

locals {
  gcb_roles = toset(split("\n", trimspace(file("resources/roles/gcb.txt"))))
}

# manages the IAM rules for the CloudBuild service account.
resource "google_project_iam_member" "cicd_cloudbuild_iam" {
  provider   = google-beta
  project    = local.project
  for_each   = local.gcb_roles
  role       = "roles/${each.value}"
  member     = "serviceAccount:${data.google_project.default.number}@cloudbuild.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}

# IAM rules for the compute service account.
resource "google_project_iam_member" "compute_permissions" {
  provider   = google-beta
  project    = local.project
  for_each   = toset(local.generic_technical_roles)
  role       = "roles/${each.key}"
  member     = "serviceAccount:${data.google_project.default.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}

# IAM rules for GS project service account to publish in local topic
data "google_storage_project_service_account" "gcs_account" {
  provider = google-beta
  project  = local.project
}

resource "google_project_iam_member" "gcs_account_pubsub_publisher" {
  provider   = google-beta
  project    = local.project
  role       = "roles/pubsub.publisher"
  member     = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  depends_on = [google_project_service.apis]
}
