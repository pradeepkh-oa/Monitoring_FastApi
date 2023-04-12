# ======================================================================================== #
#    _   _               ___       __ _             _   ___             _   _
#   | | | |___ ___ _ _  |   \ ___ / _(_)_ _  ___ __| | | __|  _ _ _  __| |_(_)___ _ _  ___
#   | |_| (_-</ -_) '_| | |) / -_)  _| | ' \/ -_) _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
#    \___//__/\___|_|   |___/\___|_| |_|_||_\___\__,_| |_| \_,_|_||_\__|\__|_\___/_||_/__/
#
# ======================================================================================== #

locals {
  udf_directory = "${local.configuration_folder}/sql-scripts/udf"
  udf_files     = fileset(local.udf_directory, "*.yaml")

  udf_configurations = {
    for udf_file in local.udf_files :
    trimsuffix(udf_file, ".yaml") => yamldecode(
      templatefile(
        "${local.udf_directory}/${udf_file}",
        merge(
          local.template_vars,
          {
            datasets = local.dataset_map
            tables   = local.tables
          }
        )
      )
    )
  }

  udf_map = ({
    for udf in local.udf_configurations :
    udf.routine_id => merge(
      udf,
      { reference = "${local.project}.${udf.dataset_id}.${udf.routine_id}" }
    )
  })
}

resource "google_bigquery_routine" "user_defined_function" {
  provider        = google-beta
  for_each        = local.udf_configurations
  dataset_id      = local.dataset_map[each.value.dataset_id].dataset_id
  routine_id      = each.value.routine_id
  routine_type    = "SCALAR_FUNCTION"
  description     = lookup(each.value, "description", null)
  language        = each.value.language
  definition_body = each.value.definition_body

  dynamic "arguments" {
    for_each = lookup(each.value, "arguments", [])

    content {
      name          = arguments.value.name
      argument_kind = lookup(arguments.value, "argument_kind", null)
      data_type     = arguments.value.data_type
    }
  }

  return_type = each.value.return_type

  depends_on = [google_bigquery_table.views_level_1]
}

output "bq_udf" {
  value = google_bigquery_routine.user_defined_function
}
