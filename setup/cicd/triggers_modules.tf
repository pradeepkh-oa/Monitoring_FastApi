# ======================================================================================== #
#    _____                  __                 _____    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   |_   _| _(_)__ _ __ _ ___ _ _ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \    | || '_| / _` / _` / -_) '_(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   |_||_| |_\__, \__, \___|_| /__/
#                                                        |___/|___/
# ======================================================================================== #

# ---------------------------------------------------------------------------------------- #
# -- < Module Triggers > --
# ---------------------------------------------------------------------------------------- #
#  -- trigger invoked to validate PULL REQUEST on a module
resource "google_cloudbuild_trigger" "module-pullrequest-trigger" {
  provider    = google-beta
  for_each    = local.modules_triggers_pr
  project     = local.triggers_env_conf[each.value.env].project
  name        = "${local.app_name_short}-trigger-${each.value.module_short}-pr-${each.value.env}"
  description = "Plan the module ${each.value.module} IaC in ${each.value.env}. Trigger invoked by a pull request in branch ${each.value.branch}."

  github {
    owner = local.owner
    name  = local.repository_name
    pull_request {
      branch = "^${each.value.branch}$"
    }
  }

  # adding the user specified service account appendable to an AAD group
  service_account = local.gcb_sa_id_map[each.value.env]

  build {
    # adding the custom storage for logging user specified GCB SA builds
    logs_bucket = local.gcb_bucket_map[each.value.env]

    step {
      id         = "[${each.value.module_short}] Check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5 | md5sum -c -"
      ]
    }

    step {
      id         = "[${each.value.module_short}] Test and build on ${each.value.env}"
      name       = local.generic_build_image
      entrypoint = "make"
      args = [
        "ENV=${each.value.env}",
        "build-module-${each.value.module}"
      ]
    }

    step {
      id         = "[${each.value.module_short}] Terraform plan on ${each.value.env}"
      name       = local.generic_build_image
      entrypoint = "make"
      args = [
        "ENV=${each.value.env}",
        "iac-plan-module-${each.value.module}"
      ]
    }

    tags = [
      "pull-request",
      local.repository_name,
      each.value.module
    ]
    timeout = "${local.trigger_timeout}s"
  }

  # modification in this directory will invoke the trigger
  included_files = [
    "modules/${each.value.module}/**",
    "environments/${each.value.env}.json"
  ]

  # modification of these won't invoke the trigger
  ignored_files = ["**/*.md"]
}

#  -- trigger invoked when MERGING change for a module
resource "google_cloudbuild_trigger" "module-deploy-trigger" {
  for_each    = local.modules_triggers_deploy
  provider    = google-beta
  project     = local.triggers_env_conf[each.value.env].project
  name        = "${local.app_name_short}-trigger-${each.value.module_short}-deploy-${each.value.env}"
  description = "Deploy the module ${each.value.module} IaC in ${each.value.env}. Trigger invoked by a merge in branch ${each.value.branch}."
  disabled    = lookup(each.value, "disabled", false)

  github {
    owner = local.owner
    name  = local.repository_name
    push {
      branch = "^${each.value.branch}$"
    }
  }

  # adding the user specified service account appendable to an AAD group
  service_account = local.gcb_sa_id_map[each.value.env]

  build {
    # adding the custom storage for logging user specified GCB SA builds
    logs_bucket = local.gcb_bucket_map[each.value.env]

    step {
      id         = "[${each.value.module_short}] Check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5 | md5sum -c -"
      ]
    }

    step {
      id         = "[${each.value.module_short}] Deploy ${each.value.env}"
      name       = local.generic_build_image
      entrypoint = "make"
      args = [
        "ENV=${each.value.env}",
        each.value.module
      ]
    }

    dynamic "step" {
      for_each = toset(contains(local.e2etests_envs, each.value.env) ? [1] : [])
      content {
        id         = "[${each.value.module_short}] Perform e2e-tests on ${each.value.env}"
        name       = local.generic_build_image
        entrypoint = "make"
        args = [
          "ENV=${each.value.env}",
          "e2e-test-module-${each.value.module}"
        ]
      }
    }

    dynamic "step" {
      for_each = toset(lookup(each.value, "next", "") != "" ? [1] : [])
      content {
        id   = "goto ${each.value.next}"
        name = "gcr.io/cloud-builders/gcloud"
        args = [
          "beta",
          "builds",
          "triggers",
          "run",
          "${local.app_name_short}-trigger-${each.value.module_short}-deploy-${each.value.next}",
          "--project",
          lookup(local.triggers_env_conf, each.value.next, null).project,
          "--branch",
          each.value.name
        ]
      }
    }

    tags = [
      "deploy",
      local.repository_name,
      each.value.module
    ]
    timeout = "${local.trigger_timeout}s"
  }

  # modification in this directory will invoke the trigger
  included_files = [
    "modules/${each.value.module}/**",
    "environments/${each.value.env}.json"
  ]

  # modification that won't trigger
  ignored_files = ["**/*.md"]
}
