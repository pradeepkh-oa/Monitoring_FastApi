# ======================================================================================== #
#    ___         _       _
#   | _ )_  _ __| |_____| |_ ___
#   | _ \ || / _| / / -_)  _(_-<
#   |___/\_,_\__|_\_\___|\__/__/
#
# ======================================================================================== #

locals {
  buckets_folder = "${local.configuration_folder}/buckets"

  bucket_raw_configs = {
    for bucket_file in fileset(local.buckets_folder, "*.yaml") :
    trimsuffix(bucket_file, ".yaml") => yamldecode(
      templatefile(
        "${local.buckets_folder}/${bucket_file}",
        local.template_vars
      )
    )
  }
  bucket_configs = {
    for bucket_tag, conf in local.bucket_raw_configs :
    bucket_tag => {
      location           = lookup(conf, "location", "EU")
      expiration_in_days = lookup(conf, "expiration_in_days", null)
      notification       = lookup(conf, "notification", null)
    }
  }

  # Create a map of bucket with elements to stay consistent with the other resources
  bucket_map = ({
    for bucket_tag, bucket in local.bucket_configs :
    bucket_tag => merge(
      bucket,
      { reference = "${local.app_name_short}-gcs-${bucket_tag}-${lower(bucket.location)}-${local.project_env}" }
    )
  })

  bucket_notification_configs = local.is_sbx ? {} : {
    for bucket_tag, conf in local.bucket_configs :
    bucket_tag => {
      topic_name         = conf.notification["topic_name"]
      topic_project      = lookup(conf.notification, "topic_project", local.project)
      object_name_prefix = lookup(conf.notification, "object_name_prefix", null)
    }
    if lookup(conf, "notification", null) != null
  }
}


resource "google_storage_bucket" "buckets" {
  for_each = local.bucket_configs
  project  = local.project
  name     = "${local.app_name_short}-gcs-${each.key}-${lower(each.value.location)}-${local.project_env}"
  location = each.value.location

  uniform_bucket_level_access = true
  force_destroy               = true # destroy when removed even if not empty

  dynamic "lifecycle_rule" {
    for_each = each.value.expiration_in_days == null ? [] : [each.value.expiration_in_days]
    content {
      condition {
        age = each.value.expiration_in_days
      }
      action {
        type = "Delete"
      }
    }
  }
}

resource "google_storage_notification" "notifications" {
  for_each           = local.bucket_notification_configs
  bucket             = google_storage_bucket.buckets[each.key].name
  topic              = "projects/${each.value.topic_project}/topics/${each.value.topic_name}"
  payload_format     = "JSON_API_V1"
  object_name_prefix = each.value.object_name_prefix

  depends_on = [google_storage_bucket.buckets]
}

output "buckets" {
  value = google_storage_bucket.buckets
}
