# ======================================================================================== #
#    ___ _                  _   ___                    _
#   / __| |_ ___ _ _ ___ __| | | _ \_ _ ___  __ ___ __| |_  _ _ _ ___ ___
#   \__ \  _/ _ \ '_/ -_) _` | |  _/ '_/ _ \/ _/ -_) _` | || | '_/ -_|_-<
#   |___/\__\___/_| \___\__,_| |_| |_| \___/\__\___\__,_|\_,_|_| \___/__/
#
# ======================================================================================== #

locals {
  sprocs_directory = "${local.configuration_folder}/sql-scripts/sprocs"
  sproc_files      = fileset(local.sprocs_directory, "*.yaml")
  sproc_sql_files  = fileset(local.sprocs_directory, "*.sql")

  sproc_configurations = {
    for sproc_file in local.sproc_files :
    trimsuffix(sproc_file, ".yaml") => yamldecode(
      templatefile(
        "${local.sprocs_directory}/${sproc_file}",
        merge(local.template_vars, {
          datasets = local.dataset_map
          views    = local.view_map
          tables   = local.tables
          mviews   = local.mview_map
        })
      )
    )
  }

  sproc_sql = {
    for sproc_file in local.sproc_sql_files :
    trimsuffix(sproc_file, ".sql") => templatefile(
      "${local.sprocs_directory}/${sproc_file}",
      merge(local.template_vars, {
        datasets = local.dataset_map
        views    = local.view_map
        tables   = local.tables
        mviews   = local.mview_map
      })
    )
  }

  sproc_map = {
    for sproc, content in local.sproc_configurations :
    sproc => {
      reference  = "${lookup(content, "project", local.project)}.${local.dataset_map[content.dataset_id].dataset_id}.${content.routine_id}"
      project    = lookup(content, "project", local.project)
      dataset_id = local.dataset_map[content.dataset_id].dataset_id
      routine_id = content.routine_id
    }
  }
}

resource "google_bigquery_routine" "stored_procedure" {
  provider        = google-beta
  for_each        = local.sproc_configurations
  dataset_id      = local.dataset_map[each.value.dataset_id].dataset_id
  routine_id      = each.value.routine_id
  routine_type    = "PROCEDURE"
  description     = lookup(each.value, "description", null)
  language        = lookup(each.value, "language", "SQL")
  definition_body = lookup(each.value, "definition_body", lookup(local.sproc_sql, each.key, "") == "" ? "" : "BEGIN\n${lookup(local.sproc_sql, each.key, "")}\nEND")

  dynamic "arguments" {
    for_each = lookup(each.value, "arguments", [])

    content {
      name          = arguments.value.name
      argument_kind = lookup(arguments.value, "argument_kind", null)
      data_type     = arguments.value.data_type
      mode          = lookup(arguments.value, "mode", null)
    }
  }

  depends_on = [
    google_bigquery_dataset.datasets,
    google_bigquery_table.tables,
    google_bigquery_routine.user_defined_function
  ]

}

output "bq_sprocs" {
  value = google_bigquery_routine.stored_procedure
}
