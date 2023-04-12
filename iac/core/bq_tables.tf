# ======================================================================================== #
#    _____     _    _
#   |_   _|_ _| |__| |___ ___
#     | |/ _` | '_ \ / -_|_-<
#     |_|\__,_|_.__/_\___/__/
#
# ======================================================================================== #

locals {
  tpl_tables = fileset("${local.configuration_folder}/tables/", "*.yaml")
  config_tables = [
    for table in local.tpl_tables :
    yamldecode(
      templatefile(
        "${local.configuration_folder}/tables/${table}",
        merge(
          local.template_vars,
          {
            datasets = local.dataset_map
          }
        )
      )
    )
  ]

  # Read config from tables yaml file and create only if dataset exist
  tables = {
    for table in local.config_tables : "${table.table_id}_v${table.version}" => {
      reference = join(".", [
        local.dataset_map[table.dataset_id].project,
        local.dataset_map[table.dataset_id].dataset_id,
        "${table.table_id}_v${table.version}"
      ])
      dataset_id                  = local.dataset_map[table.dataset_id].dataset_id
      project                     = local.dataset_map[table.dataset_id].project
      range_partitioning          = lookup(table, "range_partitioning", null)
      clustering                  = lookup(table, "clustering", null)
      description                 = table.description
      schema                      = lookup(table, "schema", null)
      external_data_configuration = lookup(table, "external_data_configuration", null)
      table_id                    = "${table.table_id}_v${table.version}"
      time_partitioning           = lookup(table, "time_partitioning", null)
      version                     = table.version
      deletion_protection         = lookup(table, "deletion_protection", true)
    }
  }
}

resource "google_bigquery_table" "tables" {
  for_each            = local.tables
  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.table_id
  schema              = each.value.schema != null ? jsonencode(each.value.schema) : null
  clustering          = each.value.clustering
  description         = each.value.description
  deletion_protection = each.value.deletion_protection

  dynamic "range_partitioning" {
    for_each = each.value.range_partitioning != null ? [1] : []
    content {
      field = each.value.range_partitioning.field
      range {
        start    = each.value.range_partitioning.start
        end      = each.value.range_partitioning.end
        interval = each.value.range_partitioning.interval
      }
    }
  }

  dynamic "time_partitioning" {
    for_each = each.value.time_partitioning != null ? [1] : []
    content {
      type                     = each.value.time_partitioning.type
      field                    = each.value.time_partitioning.field
      require_partition_filter = lookup(each.value.time_partitioning, "require_partition_filter", null)
    }
  }

  dynamic "external_data_configuration" {
    for_each = each.value.external_data_configuration != null ? [1] : []
    content {
      autodetect    = false
      source_format = each.value.external_data_configuration.source_format
      dynamic "google_sheets_options" {
        for_each = lookup(each.value.external_data_configuration, "google_sheets_options", null) != null ? [1] : []
        content {
          range             = lookup(each.value.external_data_configuration.google_sheets_options, "range", null)
          skip_leading_rows = lookup(each.value.external_data_configuration.google_sheets_options, "skip_leading_rows", 0)
        }
      }
      source_uris = try(
        each.value.external_data_configuration["source_uris"][local.project_env],
        lookup(each.value.external_data_configuration, "source_uris", null)
      )
      schema = jsonencode(each.value.external_data_configuration.schema)
    }
  }
  depends_on = [google_bigquery_dataset.datasets]
}

output "bq_tables" {
  value = google_bigquery_table.tables
}
