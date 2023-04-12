# ======================================================================================== #
#    _____                  __                  ___       _             _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    / _ \ _  _| |_ _ __ _  _| |_ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | (_) | || |  _| '_ \ || |  _(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|  \___/ \_,_|\__| .__/\_,_|\__/__/
#                                                            |_|
# ======================================================================================== #
# To provide feedbacks after deployment

output "utc_timestamp" {
  description = "Etc/UTC timestamp of last deployment"
  value       = timestamp()
}

output "identity" {
  value = google_service_account.default.email
}

output "service_name" {
  value = google_cloudfunctions2_function.default.name
}

output "service_url" {
  value = google_cloudfunctions2_function.default.service_config[0].uri
}

output "deployed_revision" {
  value = "gs://${local.deploy_bucket}/terraform-state/${local.module_name}/gcf-src_${local.revision}.zip"
}
