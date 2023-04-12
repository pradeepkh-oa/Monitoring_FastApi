# ======================================================================================== #
#    _____                  __                 _____    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   |_   _| _(_)__ _ __ _ ___ _ _ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \    | || '_| / _` / _` / -_) '_(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   |_||_| |_\__, \__, \___|_| /__/
#                                                        |___/|___/
# ======================================================================================== #

# ---------------------------------------------------------------------------------------- #
# -- < setup/access Iac Triggers > --
# ---------------------------------------------------------------------------------------- #
#  -- trigger invoked to validate PULL REQUEST on the setup/access IAC
resource "google_cloudbuild_trigger" "accessrights-pullrequest-trigger" {
  provider    = google-beta
  for_each    = local.pr_triggers
  project     = local.triggers_env_conf[each.key].project
  name        = "${local.app_name_short}-trigger-accessrights-pr-${each.key}"
  description = "Pull Request ${each.key} to change the External Access Rights in branch ${each.value.branch}."

  github {
    owner = local.owner
    name  = local.repository_name
    pull_request {
      branch = "^${each.value.branch}$"
    }
  }

  # Adding the user specified service account AAD group appendable
  service_account = local.gcb_sa_id_map[each.key]

  build {
    # Adding the custom storage for logging user specified GCB SA builds
    logs_bucket = local.gcb_bucket_map[each.key]

    step {
      id         = "[accessrights] Check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5 | md5sum -c -"
      ]
    }

    step {
      id         = "[accessrights] Terraform plan on ${each.key}"
      name       = local.generic_build_image
      entrypoint = "make"
      dir        = "setup/access"
      args = [
        "ENV=${each.key}",
        "iac-plan"
      ]
    }

    tags    = ["pull-request", local.repository_name, "accessrights"]
    timeout = "${local.trigger_timeout}s"
  }

  # modification in this directory will invoke the trigger
  included_files = [
    "setup/access/**",
    "environments/${each.key}.json"
  ]

  # modification of these won't invoke the trigger
  ignored_files = ["**/*.md"]
}

#  -- trigger invoked when MERGING change for the setup/access IAC
resource "google_cloudbuild_trigger" "accessrights-deploy-trigger" {
  for_each    = local.triggers_env
  provider    = google-beta
  project     = local.triggers_env_conf[each.key].project
  name        = "${local.app_name_short}-trigger-accessrights-deploy-${each.key}"
  description = "Deploy the change of external access rights in ${each.key}. Trigger invoked by a merge in branch ${each.value.branch}."
  disabled    = lookup(each.value, "disabled", false)

  github {
    owner = local.owner
    name  = local.repository_name
    push {
      branch = "^${each.value.branch}$"
    }
  }

  # Adding the user specified service account AAD group appendable
  service_account = local.gcb_sa_id_map[each.key]

  build {
    # Adding the custom storage for logging user specified GCB SA builds
    logs_bucket = local.gcb_bucket_map[each.key]

    step {
      id         = "[accessrights] Check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5 | md5sum -c -"
      ]
    }

    step {
      id         = "[accessrights] Grant external access rights for ${each.key}"
      name       = local.generic_build_image
      entrypoint = "make"
      dir        = "setup/access"
      args = [
        "ENV=${each.key}",
        "iac-deploy",
      ]
    }

    dynamic "step" {
      for_each = toset(lookup(each.value, "next", "") != "" ? [each.value.next] : [])
      content {
        id   = "[accessrights] Goto ${each.value.next}"
        name = "gcr.io/cloud-builders/gcloud"
        dir  = "setup/access"
        args = [
          "beta",
          "builds",
          "triggers",
          "run",
          "${local.app_name_short}-trigger-accessrights-deploy-${each.value.next}",
          "--project",
          local.triggers_env_conf[each.value.next].project,
          "--branch",
          each.value.branch
        ]
      }
    }

    tags    = ["deploy-iac", local.repository_name, "accessrights"]
    timeout = "${local.trigger_timeout}s"
  }

  # modification in this directory will invoke the trigger
  included_files = [
    "setup/access/**",
    "environments/${each.key}.json"
  ]

  # modification of these won't invoke the trigger
  ignored_files = ["**/*.md"]
}
