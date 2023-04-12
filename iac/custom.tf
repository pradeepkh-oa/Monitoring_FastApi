# ======================================================================================== #
#    _____                  __                  ___        _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    / __|  _ __| |_ ___ _ __
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | (_| || (_-<  _/ _ \ '  \
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|  \___\_,_/__/\__\___/_|_|_|
#
# ======================================================================================== #

module "custom" {
  source = "./custom"

  app_name            = local.app_name
  app_name_short      = local.app_name_short
  project             = local.project
  project_env         = local.project_env
  is_sbx              = local.is_sbx
  deploy_bucket       = local.deploy_bucket
  cloudrun_url_suffix = local.cloudrun_url_suffix
  env_file            = local.env_file
  zone                = local.zone
  zone_id             = local.zone_id
  region              = local.region
  region_id           = local.region_id
  multiregion         = local.multiregion
  workflow_region     = local.workflow_region
  workflow_region_id  = local.workflow_region_id
  project_roles       = local.project_roles
  btdpback_project    = local.btdpback_project
  btdpfront_project   = local.btdpfront_project
  apis_base_url       = local.apis_base_url
  cloudbuild_sa       = local.cloudbuild_sa
  core                = module.core

  depends_on = [
    module.core
  ]
}
