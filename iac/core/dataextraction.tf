# ======================================================================================== #
#    ___       _          ___     _               _   _
#   |   \ __ _| |_ __ _  | __|_ _| |_ _ _ __ _ __| |_(_)___ _ _
#   | |) / _` |  _/ _` | | _|\ \ /  _| '_/ _` / _|  _| / _ \ ' \
#   |___/\__,_|\__\__,_| |___/_\_\\__|_| \__,_\__|\__|_\___/_||_|
#
# ======================================================================================== #
locals {
  # import configurations
  dataextraction_folder = "${local.configuration_folder}/dataextraction"
  extraction_configurations = {
    for filepath in fileset(local.dataextraction_folder, "configurations/*.yaml") :
    filepath => merge(
      yamldecode(
        templatefile(
          "${local.dataextraction_folder}/${filepath}",
          local.template_vars
        )
      ),
    { id = "${trimsuffix(basename(filepath), ".yaml")}-${local.project_env}" })
  }
}

# -- REST API provider to publish configs to BTDP Data Extraction API
provider "restapi" {
  alias = "dataextraction"
  uri   = local.apis_base_url.dataextraction
  headers = {
    "Authorization" : "Bearer ${local.is_sbx ? "<none>" : data.google_service_account_access_token.cloudbuild_sa[0].access_token}"
  }
  write_returns_object = true
}

# -- provided configurations for data extraction
resource "restapi_object" "dataextraction_configuration" {
  provider = restapi.dataextraction
  for_each = {
    for filepath, config in local.extraction_configurations :
    # add the id to the for_each key to ensure that changing id
    # will delete and re-create the configuration
    "configurations/${config.id}/${filepath}" => config
    if local.is_sbx != true # NOTHING deployed on sandbox
  }
  path = "/v1/configurations"
  data = jsonencode(each.value)
}

output "dataextraction" {
  value = {
    configurations = restapi_object.dataextraction_configuration
  }
}
