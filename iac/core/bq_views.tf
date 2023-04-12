# ======================================================================================== #
#   __   ___
#   \ \ / (_)_____ __ _____
#    \ V /| / -_) V  V (_-<
#     \_/ |_\___|\_/\_//__/
#
# ======================================================================================== #

locals {
  #look for Views config yaml file
  tpl_views = fileset("${local.configuration_folder}/views/", "*.yaml")
  config_views = [
    for views in local.tpl_views :
    yamldecode(
      templatefile(
        "${local.configuration_folder}/views/${views}",
        merge(
          local.template_vars,
          {
            datasets = local.dataset_map
            tables   = local.tables
            udfs     = local.udf_map
          }
        )
      )
    )
  ]

  #look for materialized views yaml file
  materialized_views = fileset("${local.configuration_folder}/matviews/", "*.yaml")
  config_mviews = [
    for views in local.materialized_views :
    yamldecode(
      templatefile(
        "${local.configuration_folder}/matviews/${views}",
        local.template_vars
      )
    )
  ]

  #Read config from views yaml file and create only if dataset exist
  view_output = [
    for view in local.config_views : {
      dataset_id             = local.dataset_map[view.dataset_id].dataset_id
      view_id                = "${view.view_id}_v${view.version}"
      query                  = view.query
      description            = view.description
      project                = local.dataset_map[view.dataset_id].project
      level                  = view.level
      authorized_on_datasets = coalesce(lookup(view, "authorized_on_datasets", null), [])
    }
  ]
  /* We have defined view level dependency in this code.
    This information is provided in views configuration file through mandatory field "level".

    If there is no dependency on another view, then the level must be 0.
    If there is one dependency on another view, then the level must be 1.
    Currently this framework cannot handle a number of dependecies higher than 1.
  */
  view_map = {
    for view in local.view_output : view.view_id => merge(
      view,
      { reference = "${view.project}.${view.dataset_id}.${view.view_id}" }
    )
  }
  views_level_0 = { for k, v in local.view_map : k => v if v.level == 0 }
  views_level_1 = { for k, v in local.view_map : k => v if v.level == 1 }

  view_dataset_accesses = merge([
    for view in local.view_output : {
      for dataset in view.authorized_on_datasets :
      "${view.view_id}_${dataset}" => {
        project    = local.dataset_map[dataset].project
        dataset_id = local.dataset_map[dataset].dataset_id
        view       = view
      }
    }
  ]...)

  #Read config for materialized view from yaml file and create only if dataset exist.
  mview_output = [
    for mviews in local.config_mviews : {
      dataset_id          = local.dataset_map[mviews.dataset_id].dataset_id
      table_id            = "${mviews.view_id}_v${mviews.version}"
      query               = mviews.query
      description         = mviews.description
      enable_refresh      = mviews.enableRefresh
      refresh_interval_ms = lookup(mviews, "refreshIntervalMs", "3600000")
      project             = local.dataset_map[mviews.dataset_id].project

    }
  ]

  mview_map = {
    for view in local.mview_output : view.table_id => {
      reference  = "${view.project}.${view.dataset_id}.${view.table_id}"
      project    = view.project
      dataset_id = view.dataset_id
      table_id   = view.table_id
    }
  }
}

resource "google_bigquery_table" "materialized_views" {

  for_each = {
    for views in local.mview_output : views.table_id => views
  }

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.table_id
  description         = each.value.description
  deletion_protection = false

  materialized_view {
    query               = each.value.query
    enable_refresh      = each.value.enable_refresh
    refresh_interval_ms = each.value.refresh_interval_ms
  }
  depends_on = [google_bigquery_table.tables]
}

resource "google_bigquery_table" "views_level_0" {

  for_each = local.views_level_0

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.view_id
  description         = each.value.description
  deletion_protection = false

  view {
    query          = each.value.query
    use_legacy_sql = false
  }
  depends_on = [google_bigquery_table.tables]
}

resource "google_bigquery_table" "views_level_1" {

  for_each = local.views_level_1

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.view_id
  description         = each.value.description
  deletion_protection = false

  view {
    query          = each.value.query
    use_legacy_sql = false
  }
  depends_on = [google_bigquery_table.views_level_0]

}

resource "google_bigquery_dataset_access" "view_dataset_accesses" {
  for_each   = local.view_dataset_accesses
  dataset_id = each.value.dataset_id
  project    = each.value.project

  view {
    project_id = each.value.view.project
    dataset_id = each.value.view.dataset_id
    table_id   = each.value.view.view_id
  }
  depends_on = [google_bigquery_table.views_level_1]
}

output "bq_mviews" {
  value = google_bigquery_table.materialized_views
}

output "bq_views" {
  value = merge(
    google_bigquery_table.views_level_0,
    google_bigquery_table.views_level_1
  )
}

output "bq_view_access" {
  value = google_bigquery_dataset_access.view_dataset_accesses
}
