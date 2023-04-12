# ======================================================================================== #
#            _____                  __                 _                 _
#           |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | |   ___  __ __ _| |___
#             | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | |__/ _ \/ _/ _` | (_-<
#             |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |____\___/\__\__,_|_/__/
#
# ======================================================================================== #
locals {
  app_name       = var.app_name
  app_name_short = replace(var.app_name, "-", "")

  project     = var.project
  project_env = var.project_env

  env_file = jsondecode(file(var.env_file))

  is_sbx = contains(["dv", "qa", "np", "pd"], local.project_env) != true

  # location variables
  zone      = lookup(local.env_file, "zone", "europe-west1-b")
  zone_id   = lookup(local.env_file, "zone_id", replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-([a-z])/", "$1$2$3$4"))
  region    = lookup(local.env_file, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  region_id = lookup(local.env_file, "region_id", replace(local.region, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])/", "$1$2$3"))

  multiregion = lookup(
    local.env_file, "multiregion",
    regex("^europe-", local.region) == "europe-" ? "eu" : (regex("^us-", local.region) == "us-" ? "us" : null)
  )
}

# -- templating configurations
locals {
  # template vars
  common_template_vars = {
    project        = local.project
    project_env    = local.project_env
    app_name_short = local.app_name_short,
    multiregion    = local.multiregion,
    region         = local.region,
    region_id      = local.region_id,
    zone           = local.zone,
    zone_id        = local.zone_id,
  }
  user_defined_template_vars = fileexists("resources/variables.json") ? (
    jsondecode(
      templatefile("resources/variables.json", local.common_template_vars)
    )
  ) : {}


  template_vars = merge(local.common_template_vars, local.user_defined_template_vars)

  # roles based on rendered template configs
  roles_per_member = merge([
    for filepath in fileset(path.module, "resources/**/*.yaml") : {
      for member, conf in yamldecode(
        templatefile(filepath, local.template_vars) # empty files raise errors
      ) :
      member => conf
    }
  ]...)

  roles_at_project_level = merge([
    for member, conf in local.roles_per_member : {
      for role in try(coalesce(lookup(conf, "project", null), []), []) : # handle empty fields
      "${member}.${role}" => {
        member = member
        role   = role
      }
    }
  ]...)
  roles_per_resource_level = {
    for level in ["buckets", "datasets", "tables", "pubsub_topics", "secrets"] :
    level => merge(flatten([
      for member, conf in local.roles_per_member : [
        for resource, roles in try(coalesce(lookup(conf, level, null), {}), {}) : # handle empty fields
        {
          for role in roles :
          "${member}.${resource}.${role}" => {
            member   = member
            resource = resource # Expected format for tables: "<dataset_id>.<table_id>"
            role     = role
          }
        }
      ]
    ])...)
  }
}

output "user_defined_template_vars" {
  value = local.user_defined_template_vars # to help debug
}
