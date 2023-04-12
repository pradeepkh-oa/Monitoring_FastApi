# ======================================================================================== #
#    _____                  __                 ___     _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | _ \___| |___ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  |   / _ \ / -_|_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |_|_\___/_\___/__/
#
# ======================================================================================== #
# manages the IAM rules for the CloudBuild service account.
resource "google_project_iam_member" "cicd_cloudbuild_iam" {
  provider = google-beta
  for_each = local.gcb_roles
  project  = each.value.project
  role     = "roles/${each.value.role}"
  member   = "serviceAccount:${data.google_project.env_projects[each.value.env].number}@cloudbuild.gserviceaccount.com"
}

/**
 * Defines permissions to allow promotion of build from a low environment to the one above.
 * For instance promotion from qa to np, GCB SA of qa needs to trigger builds in np.
 */
# inter-project trigger: add permissions to trigger
resource "google_project_iam_member" "inter_project" {
  provider = google-beta
  for_each = { for key, val in local.triggers_env : key => val.next if lookup(val, "next", null) != null }
  project  = lookup(local.triggers_env_conf, each.value, null).project
  role     = "roles/cloudbuild.builds.editor"
  member   = "serviceAccount:${data.google_project.env_projects[each.key].number}@cloudbuild.gserviceaccount.com"
}
