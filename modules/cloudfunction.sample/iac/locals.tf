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

  module_name       = var.module_name
  module_name_short = replace(var.module_name, "-", "")

  project     = var.project
  project_env = var.project_env

  revision      = var.revision
  deploy_bucket = var.deploy_bucket

  # load the json environment configuration file
  env_file = jsondecode(file(var.env_file))
}

# -- location
locals {
  zone        = lookup(local.env_file, "zone", "europe-west1-b")
  zone_id     = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-([a-z])/", "$1$2$3$4")
  region      = lookup(local.env_file, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  region_id   = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-[a-z]/", "$1$2$3")
  multiregion = lookup(local.env_file, "multiregion", regex("^europe-", local.zone) == "europe-" ? "eu" : (regex("^us-", local.zone) == "us-" ? "us" : null))
}

# -- instance parameters
locals {
  timeout = lookup(local.env_file, "timeout", 300) # max: 540
}

# -- others
# ...
