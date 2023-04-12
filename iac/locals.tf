# ======================================================================================== #
#    _____                  __                 _                 _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | |   ___  __ __ _| |___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | |__/ _ \/ _/ _` | (_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |____\___/\__\__,_|_/__/
#
# ======================================================================================== #

# -- main local variables
locals {
  app_name       = var.app_name
  app_name_short = replace(var.app_name, "-", "")

  project     = var.project
  project_env = var.project_env

  is_sbx = contains(["dv", "qa", "np", "pd"], local.project_env) != true

  deploy_bucket       = var.deploy_bucket
  cloudrun_url_suffix = trimspace(data.google_storage_bucket_object_content.cloudrun_url_suffix.content)

  # load the json environment configuration file
  env_file = jsondecode(file(var.env_file))
}

# -- location variables
locals {
  zone      = lookup(local.env_file, "zone", "europe-west1-b")
  zone_id   = lookup(local.env_file, "zone_id", replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-([a-z])/", "$1$2$3$4"))
  region    = lookup(local.env_file, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  region_id = lookup(local.env_file, "region_id", replace(local.region, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])/", "$1$2$3"))

  multiregion = lookup(
    local.env_file, "multiregion",
    regex("^europe-", local.region) == "europe-" ? "eu" : (regex("^us-", local.region) == "us-" ? "us" : null)
  )

  workflow_region    = lookup(local.env_file, "workflow_region", "europe-west1")
  workflow_region_id = lookup(local.env_file, "workflow_region_id", "ew1")
}

# -- common variables for resources
locals {
  project_roles = toset([])

  configuration_folder = "${path.module}/../../configuration"

  btdpback_project = lookup(
    local.env_file,
    "btdpback_project",
    local.is_sbx ? local.project : "itg-btdpback-gbl-ww-${local.project_env}"
  )
  btdpfront_project = lookup(
    local.env_file,
    "btdpfront_project",
    local.is_sbx ? local.project : "itg-btdpfront-gbl-ww-${local.project_env}"
  )

  # Configuration of Rest APIs hosted on apigee
  apis_base_url = jsondecode(file("${dirname(var.env_file)}/apis.json"))
  cloudbuild_sa = "${local.app_name_short}-sa-cloudbuild-${local.project_env}@${local.project}.iam.gserviceaccount.com"
}
