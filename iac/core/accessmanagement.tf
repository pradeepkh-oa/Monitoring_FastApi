# ======================================================================================== #
#      _                     __  __                                       _
#     /_\  __ __ ___ ______ |  \/  |__ _ _ _  __ _ __ _ ___ _ __  ___ _ _| |_
#    / _ \/ _/ _/ -_|_-<_-< | |\/| / _` | ' \/ _` / _` / -_) '  \/ -_) ' \  _|
#   /_/ \_\__\__\___/__/__/ |_|  |_\__,_|_||_\__,_\__, \___|_|_|_\___|_||_\__|
#                                                 |___/
# ======================================================================================== #
locals {
  # import configurations
  accessmanagement_folder = "${local.configuration_folder}/accessmanagement"

  subscription_configurations = {
    for filepath in fileset(local.accessmanagement_folder, "subscriptions/*.yaml") :
    filepath => yamldecode(
      templatefile(
        "${local.accessmanagement_folder}/${filepath}",
        merge(
          local.template_vars,
          # Allow referencing other resources based on configurations
          {
            datasets = local.dataset_map
            views    = local.view_map
            tables   = local.tables
            mviews   = local.mview_map
          }
        )
      )
    )
  }

  dls_subscription_configurations = {
    for filepath in fileset(local.accessmanagement_folder, "dls_subscriptions/*.yaml") :
    filepath => yamldecode(
      templatefile(
        "${local.accessmanagement_folder}/${filepath}",
        merge(
          local.template_vars,
          # Allow referencing other resources based on configurations
          { datasets = google_bigquery_dataset.datasets }
        )
      )
    )
  }
}

# -- REST API provider for Access Management API endpoints
provider "restapi" {
  alias = "accessmanagement"
  uri   = local.apis_base_url.accessmanagement
  headers = {
    Authorization = "Bearer ${local.is_sbx ? "<none>" : data.google_service_account_access_token.cloudbuild_sa[0].access_token}"
  }
  write_returns_object = true
}

# -- AM permissions on project

# -- provided configurations for (RLS) subscriptions
resource "restapi_object" "accessmanagement_subscriptions" {
  provider = restapi.accessmanagement

  for_each = {
    for filepath, config in local.subscription_configurations :
    # To ensure that changing rule_id will delete and re-create the subscription
    "rules/${config.rule_id}/${filepath}" => config
    if local.is_sbx != true # NOTHING deployed on sandbox
  }
  path         = "/v1/rules/${each.value.rule_id}/subscriptions"
  data         = jsonencode(each.value.payload)
  id_attribute = "data/id"

  depends_on = [
    google_bigquery_table.tables,
    google_bigquery_table.views_level_0,
    google_bigquery_table.views_level_1,
    google_bigquery_table.materialized_views
  ]
}


# -- provided configurations for DLS subscriptions
resource "google_bigquery_dataset_access" "dls_group_access" {
  for_each = merge([
    for filepath, config in local.dls_subscription_configurations : {
      for dataset in config.datasets :
      "${filepath}_${dataset}" => {
        group      = config.payload.group
        dataset_id = length(split(".", dataset)) > 1 ? split(".", dataset)[1] : dataset
        project    = length(split(".", dataset)) > 1 ? split(".", dataset)[0] : local.project
      }
    }
  ]...)
  project        = each.value.project
  dataset_id     = each.value.dataset_id
  role           = "READER"
  group_by_email = each.value.group
}


resource "restapi_object" "accessmanagement_dls_subscriptions" {
  provider = restapi.accessmanagement

  for_each = {
    for filepath, config in local.dls_subscription_configurations :
    # To ensure that changing rule_id will delete and re-create the subscription
    "rules/${config.rule_id}/${filepath}" => config
    if local.is_sbx != true # NOTHING deployed on sandbox
  }
  path         = "/v1/rules/${each.value.rule_id}/dls_subscriptions"
  data         = jsonencode(each.value.payload)
  id_attribute = "data/id"

  depends_on = [google_bigquery_dataset_access.dls_group_access] # ensure it worked first
}


# -- outputs
output "accessmanagement" {
  value = {
    subscriptions = {
      for k, obj in restapi_object.accessmanagement_subscriptions : k => jsondecode(obj.api_response)["data"]
    }
    dls_subscriptions = {
      for k, obj in restapi_object.accessmanagement_dls_subscriptions : k => jsondecode(obj.api_response)["data"]
    }
  }
}
