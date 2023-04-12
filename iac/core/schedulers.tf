# ======================================================================================== #
#    ___     _           _      _
#   / __| __| |_  ___ __| |_  _| |___ _ _ ___
#   \__ \/ _| ' \/ -_) _` | || | / -_) '_(_-<
#   |___/\__|_||_\___\__,_|\_,_|_\___|_| /__/
#
# ======================================================================================== #

locals {
  scheduler_variables = {
    app_name_short     = local.app_name_short,
    region_id          = local.region_id,
    project_env        = local.project_env,
    workflow_region    = local.workflow_region,
    workflow_region_id = local.workflow_region_id,
    front_project      = local.project
  }

  tpl_schedulers_main = fileset("${local.configuration_folder}/triggers/schedulers/", "*.yaml")
  schedulers_main = {
    for file in local.tpl_schedulers_main :
    trimsuffix(file, ".yaml") => yamldecode(
      templatefile(
        "${local.configuration_folder}/triggers/schedulers/${file}",
        merge(
          local.template_vars,
          {
            workflows = local.workflows_map
          }
        )
      )
    )
  }
  schedulers = local.schedulers_main
}

resource "google_cloud_scheduler_job" "schedulers" {
  for_each = local.schedulers

  name             = "${local.app_name_short}-sch-${each.key}-${local.region_id}-${local.project_env}"
  project          = try(each.value.project_id, local.project)
  region           = try(each.value.region, local.region)
  schedule         = try(each.value.schedule, null)
  description      = try(each.value.description, null)
  time_zone        = try(each.value.time_zone, null)
  attempt_deadline = try(each.value.attempt_deadline, null)

  dynamic "retry_config" {
    for_each = try(each.value.retry_config, null) != null ? [1] : []
    content {
      retry_count          = try(each.value.retry_config.retry_count, null)
      max_retry_duration   = try(each.value.retry_config.max_retry_duration, null)
      min_backoff_duration = try(each.value.retry_config.min_backoff_duration, null)
      max_backoff_duration = try(each.value.retry_config.max_backoff_duration, null)
      max_doublings        = try(each.value.retry_config.max_doublings, null)
    }
  }

  dynamic "pubsub_target" {
    for_each = try(each.value.pubsub_target, null) != null ? [1] : []
    content {
      topic_name = each.value.pubsub_target.topic_name
      data       = try(base64encode(try(each.value.pubsub_target.data, null)), null)
      attributes = try(each.value.pubsub_target.attributes, null)
    }
  }

  dynamic "http_target" {
    for_each = try(each.value.http_target, null) != null ? [1] : []
    content {
      uri         = each.value.http_target.uri
      http_method = try(each.value.http_target.http_method, null)
      body        = try(base64encode(try(each.value.http_target.body, null)), null)
      headers     = try(each.value.http_target.headers, null)

      dynamic "oauth_token" {
        for_each = try(each.value.http_target.oauth_token, null) != null ? [1] : []
        content {
          service_account_email = each.value.http_target.oauth_token.service_account_email
          scope                 = try(each.value.http_target.oauth_token.scope, null)
        }
      }

      dynamic "oidc_token" {
        for_each = try(each.value.http_target.oidc_token, null) != null ? [1] : []
        content {
          service_account_email = each.value.http_target.oidc_token.service_account_email
          audience              = try(each.value.http_target.oidc_token.audience, null)
        }
      }
    }
  }
  depends_on = [
    data.google_service_account.workflows_sa
  ]
}

output "schedulers" {
  value = google_cloud_scheduler_job.schedulers
}
