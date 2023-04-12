# ======================================================================================== #
#     ___               _                 _
#    / __|___ _ _ ___  | |   ___  __ __ _| |___
#   | (__/ _ \ '_/ -_) | |__/ _ \/ _/ _` | (_-<
#    \___\___/_| \___| |____\___/\__\__,_|_/__/
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

# templating variables
locals {
  common_template_vars = {
    project                 = local.project
    project_env             = local.project_env
    app_name                = local.app_name
    app_name_short          = local.app_name_short
    multiregion             = local.multiregion
    location                = local.multiregion
    region                  = local.region
    region_id               = local.region_id
    zone                    = local.zone
    zone_id                 = local.zone_id
    btdpback_project        = local.btdpback_project
    btdpfront_project       = local.btdpfront_project
    workflow_region         = local.workflow_region
    workflow_region_id      = local.workflow_region_id
    cloudrun_url_suffix     = local.cloudrun_url_suffix
    default_service_account = data.google_service_account.workflows_sa.email # DEPRECATED
  }
  user_defined_template_vars = jsondecode(
    try(
      templatefile(
        "${local.configuration_folder}/variables.json", local.common_template_vars
      ),
      "{}" # allow missing file
    )
  )

  template_vars = merge(local.common_template_vars, local.user_defined_template_vars)
}
