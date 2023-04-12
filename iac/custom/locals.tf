# ======================================================================================== #
#     ___        _               _                 _
#    / __|  _ __| |_ ___ _ __   | |   ___  __ __ _| |___
#   | (_| || (_-<  _/ _ \ '  \  | |__/ _ \/ _/ _` | (_-<
#    \___\_,_/__/\__\___/_|_|_| |____\___/\__\__,_|_/__/
#
# ======================================================================================== #

# -- Locals computed from the main moduleL
locals {
  app_name             = var.app_name
  app_name_short       = var.app_name_short
  project              = var.project
  project_env          = var.project_env
  is_sbx               = var.is_sbx
  deploy_bucket        = var.deploy_bucket
  cloudrun_url_suffix  = var.cloudrun_url_suffix
  env_file             = var.env_file
  zone                 = var.zone
  zone_id              = var.zone_id
  region               = var.region
  region_id            = var.region_id
  multiregion          = var.multiregion
  workflow_region      = var.workflow_region
  workflow_region_id   = var.workflow_region_id
  project_roles        = var.project_roles
  btdpback_project     = var.btdpback_project
  btdpfront_project    = var.btdpfront_project
  apis_base_url        = var.apis_base_url
  cloudbuild_sa        = var.cloudbuild_sa
  configuration_folder = "${path.module}/../../configuration"
}
