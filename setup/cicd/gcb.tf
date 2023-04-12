# ======================================================================================== #
#    _____                  __                  ___  ___ ___
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    / __|/ __| _ )
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | (_ | (__| _ \
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|  \___|\___|___/
#
# ======================================================================================== #
locals {
  bucket_region = "eu"

  # map containing the GCB SA email address for each environment
  gcb_sa_email_map = {
    for env, config in local.triggers_env_conf :
    env => "${local.app_name_short}-sa-cloudbuild-${config.project_env}@${config.project}.iam.gserviceaccount.com"
  }

  # map containing the GCB SA full identifier
  gcb_sa_id_map = {
    for env, config in local.triggers_env_conf :
    env => "projects/${config.project}/serviceAccounts/${local.gcb_sa_email_map[env]}"
  }

  # map containing the build bucket for each environment
  gcb_bucket_map = {
    for env, config in local.triggers_env_conf :
    env => "gs://cloudbuild-gcs-${local.bucket_region}-${config.project}/logs"
  }

  # maps to associate the next environment for which a build must be triggered for promotion
  act_as = { for env, item in local.triggers_env : env => item.next if lookup(item, "next", null) != null }
  act_as_next = {
    for env, item in local.triggers_env :
    env => {
      next_env    = item.next
      current_env = env
    } if lookup(item, "next", null) != null
  }
}

/**
 * Defines permissions to allow promotion of build from a low environment to the one above.
 * For instance promotion from qa to np, GCB SA of qa needs to trigger builds in np.
 */
# inter-project trigger: add permissions to trigger
resource "google_project_iam_member" "custom_inter_project" {
  provider = google-beta
  for_each = local.act_as
  project  = lookup(local.triggers_env_conf, each.value, null).project
  role     = "roles/cloudbuild.builds.editor"
  member   = "serviceAccount:${local.gcb_sa_email_map[each.key]}"
}

# -- allow impersonation of the next GCB SA to by the current GCB SA
#    e.g. qa can call np SA (for user-specified SA cloudbuild.builds.editor is not sufficient)
resource "google_service_account_iam_member" "act_as_next_trigger" {
  provider           = google-beta
  for_each           = local.act_as_next
  service_account_id = local.gcb_sa_id_map[each.value.next_env]
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.gcb_sa_email_map[each.value.current_env]}"
}


# ---------------------------------------------------------------------------------------- #
# -- < Grant Roles for Project's GCB SA > --
#
# Grants explicitly roles for the Back GCB SA on use case project.
# ---------------------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------------------- #
# -- granting permissions 4 Project over Project
# ---------------------------------------------------------------------------------------- #
locals {
  roles_on_project = toset(split("\n", trimspace(file("resources/gcb-roles.txt"))))

  # roles for each project
  all_roles_on_project = flatten([
    for env, conf in local.triggers_env_conf : [
      for role in local.roles_on_project : {
        project     = conf.project,
        project_env = conf.project_env
        env         = env
        role        = role
      } if role != ""
    ]
  ])

  custom_roles_on_project = {
    for item in local.all_roles_on_project :
    "${item.project}_${item.role}_${item.project_env}" => item
  }
}

resource "google_project_iam_member" "gcb_roles_on_project" {
  provider = google-beta
  for_each = local.custom_roles_on_project
  project  = each.value.project
  role     = "roles/${each.value.role}"
  member   = "serviceAccount:${local.gcb_sa_email_map[each.value.env]}"
}
