# ======================================================================================== #
#    ___       _                _
#   |   \ __ _| |_ __ _ ___ ___| |_ ___
#   | |) / _` |  _/ _` (_-</ -_)  _(_-<
#   |___/\__,_|\__\__,_/__/\___|\__/__/
#
# ======================================================================================== #

locals {
  tech_lead_group = "gcp-btdp-fr-gbl-lead@loreal.com"
  itg_security_sa = "system@itg-btdpsecurity-gbl-ww-pd.iam.gserviceaccount.com"
  developer_group = "gcp-btdp-fr-gbl-dv@loreal.com"

  default_owners_by_env = {
    "dv" = ["group:${local.tech_lead_group}", "serviceAccount:${local.itg_security_sa}", "group:${local.developer_group}"],
    "qa" = ["group:${local.tech_lead_group}", "serviceAccount:${local.itg_security_sa}", "group:${local.developer_group}"],
    "np" = ["serviceAccount:${local.itg_security_sa}"],
    "pd" = ["serviceAccount:${local.itg_security_sa}"],
  }
  default_owners  = lookup(local.default_owners_by_env, local.project_env, [])
  default_editors = []
  default_viewers = []

  tpl_datasets = fileset("${local.configuration_folder}/datasets/", "*.yaml")
  config_datasets = [
    for dataset in local.tpl_datasets : {
      file_name = trimsuffix(dataset, ".yaml")
      config = yamldecode(
        templatefile(
          "${local.configuration_folder}/datasets/${dataset}",
          local.template_vars
        )
      )
    }
  ]

  # Read config from yaml file and fill missing values with default one
  datasets_output = [
    for dataset_info in local.config_datasets : {
      project           = lookup(dataset_info.config, "project", local.project)
      dataset_file_name = dataset_info.file_name
      dataset_id = join("", [
        "${local.app_name_short}_ds_${lookup(dataset_info.config, "confidentiality", "c3")}",
        "_${dataset_info.file_name}",
        "_${lookup(dataset_info.config, "location", local.multiregion)}_${local.project_env}"
      ])
      location                    = lookup(dataset_info.config, "location", local.multiregion)
      confidentiality             = dataset_info.config.confidentiality
      description                 = dataset_info.config.description
      friendly_name               = dataset_info.config.friendly_name
      delete_contents_on_destroy  = lookup(dataset_info.config, "delete_contents_on_destroy", "false")
      deletion_protection         = lookup(dataset_info.config, "deletion_protection", true)
      default_table_expiration_ms = length(regexall("(tmp)$", dataset_info.file_name)) == 0 ? null : lookup(dataset_info.config, "default_table_expiration_ms", "432000000")
      permissions                 = lookup(dataset_info.config, "permissions", [])
      max_time_travel_hours       = tostring(lookup(dataset_info.config, "max_time_travel_hours", "168"))
    }
  ]

  #convert the values into map format
  dataset_map = ({
    for dataset in local.datasets_output :
    dataset.dataset_file_name => merge(
      dataset,
      { reference = "${dataset.project}.${dataset.dataset_id}" }
    )
  })


  # Get permissions from dataset config file
  permissions_output = [
    for dataset_output in local.datasets_output : {
      for key in ["project", "dataset_id", "description", "permissions"] :
      key => dataset_output[key]
    }
  ]

  #convert the values into map format
  permissions_map = ({
    for permission in local.permissions_output :
    permission.dataset_id => permission
  })

  dataset_permissions_access = flatten([
    for dataset_id, dataset in local.permissions_map :
    concat(
      [
        for owner in concat(local.default_owners, try(dataset.permissions[local.project_env]["owners"], [])) : {
          dataset_id     = dataset_id
          role           = "dataOwner"
          account_type   = length(split(":", owner)) > 1 ? split(":", owner)[0] : "special"
          account_member = length(split(":", owner)) > 1 ? split(":", owner)[1] : owner
          project        = lookup(dataset, "project", local.project)
        }
      ],
      [
        for editor in concat(local.default_editors, try(dataset.permissions[local.project_env]["editors"], [])) : {
          dataset_id     = dataset_id
          role           = "dataEditor"
          account_type   = length(split(":", editor)) > 1 ? split(":", editor)[0] : "special"
          account_member = length(split(":", editor)) > 1 ? split(":", editor)[1] : editor
          project        = lookup(dataset, "project", local.project)
        }
      ],
      [
        for viewer in concat(local.default_viewers, try(dataset.permissions[local.project_env]["viewers"], [])) : {
          dataset_id     = dataset_id
          role           = "dataViewer"
          account_type   = length(split(":", viewer)) > 1 ? split(":", viewer)[0] : "special"
          account_member = length(split(":", viewer)) > 1 ? split(":", viewer)[1] : viewer
          project        = lookup(dataset, "project", local.project)
        }
      ]
    )
  ])
}

resource "google_bigquery_dataset" "datasets" {
  for_each      = local.dataset_map
  project       = each.value.project
  dataset_id    = each.value.dataset_id
  friendly_name = each.value.friendly_name
  description   = each.value.description
  location      = upper(each.value.location)

  delete_contents_on_destroy = each.value.delete_contents_on_destroy
  labels = {
    env = local.project_env
  }
  default_table_expiration_ms = each.value.default_table_expiration_ms
  max_time_travel_hours       = each.value.max_time_travel_hours

  # MIGRATION PROCESS:
  # IN CASE OF A MIGRATION OF THE PROJECT WITH ALREADY EXISTING DATASETS, PLEASE FOLLOW THESE STEPS
  # 1- COMMENT THE LIFECYCLE BLOCK BELOW AND UNCOMMENT THE ACCESS BLOCK
  # 2- DEPLOY THE IAC : THIS MIGRATES EXISTING DATASETS RESOURCES TO THE USAGE OF
  #    google_bigquery_dataset_access INSTEAD OF _iam_binding
  # 3- DEPLOY ON ALL ENVS INCLUDING PD
  # 4- UNCOMMENT THE LIFECYCLE BLOCK AND DELETE THE ACCESS BLOCK
  # 5- REDEPLOY THE IAC ON ALL ENVS INCLUDING PD
  # 6- END OF PROCEDURE
  #
  # (IGNORE THESE STEPS IF YOU DON'T HAVE DATASETS TO MIGRATE)
  lifecycle {
    ignore_changes = [
      # so google_bigquery_dataset and google_bigquery_dataset_access don't fight
      # over which accesses should be on the dataset.
      # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_access
      access
    ]
  }

  # in order to workaround a bug in Terraform
  # https://github.com/hashicorp/terraform-provider-google/issues/7486
  # about dataset access migration
  # we add a new access block here which will erase all the pre-existing
  # access directives coming from previous IAM bindings.
  # This block is basically useless and will be removed in a future release
  # after the completion of datasets migration towards google_bigquery_dataset_access
  # access {
  #   role          = "OWNER"
  #   user_by_email = "sebastien.morand@loreal.com"
  # }
}


resource "google_bigquery_dataset_access" "ds_access" {
  for_each = {
    for mapping in local.dataset_permissions_access : "${mapping.dataset_id}_${mapping.role}_${mapping.account_member}" => mapping
  }
  project        = each.value.project
  dataset_id     = each.value.dataset_id
  role           = "roles/bigquery.${each.value.role}"
  user_by_email  = contains(["user", "serviceAccount"], each.value.account_type) ? each.value.account_member : null
  group_by_email = each.value.account_type == "group" ? each.value.account_member : null
  special_group  = each.value.account_type == "special" ? each.value.account_member : null
  depends_on     = [google_bigquery_dataset.datasets]
}

output "bq_datasets" {
  value = google_bigquery_dataset.datasets
}
