# ---------------------------------------------------------------------------------------- #
# -- < Provide external access at all levels  > --
# ---------------------------------------------------------------------------------------- #
# -- project
resource "google_project_iam_member" "authorized_on_project" {
  for_each = local.roles_at_project_level
  project  = local.project
  member   = each.value.member
  role     = "roles/${each.value.role}"
}

# -- buckets
resource "google_storage_bucket_iam_member" "authorized_on_buckets" {
  for_each = local.roles_per_resource_level["buckets"]
  bucket   = each.value.resource
  member   = each.value.member
  role     = "roles/${each.value.role}"
}

# -- datasets and tables
resource "google_bigquery_dataset_iam_member" "authorized_on_datasets" {
  for_each   = local.roles_per_resource_level["datasets"]
  project    = local.project
  dataset_id = each.value.resource
  member     = each.value.member
  role       = "roles/${each.value.role}"
}

resource "google_bigquery_table_iam_member" "authorized_on_tables" {
  for_each   = local.roles_per_resource_level["tables"]
  project    = local.project
  dataset_id = split(".", each.value.resource)[0]
  table_id   = split(".", each.value.resource)[1]
  member     = each.value.member
  role       = "roles/${each.value.role}"
}

# -- pub/sub topics
resource "google_pubsub_topic_iam_member" "authorized_on_pubsubtopics" {
  for_each = local.roles_per_resource_level["pubsub_topics"]
  project  = local.project
  topic    = each.value.resource
  member   = each.value.member
  role     = "roles/${each.value.role}"
}

# -- secrets
resource "google_secret_manager_secret_iam_member" "authorized_on_secrets" {
  for_each  = local.roles_per_resource_level["secrets"]
  project   = local.project
  secret_id = each.value.resource
  member    = each.value.member
  role      = "roles/${each.value.role}"
}
