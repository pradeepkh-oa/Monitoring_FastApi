locals {
  /**
   * The list of roles to give to the cloud workflow service account.
   */
  workflows_sa_roles = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/logging.logWriter",
    "roles/pubsub.publisher",
    "roles/run.invoker",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectAdmin",
    "roles/workflows.invoker"
  ])
}

/**
 * Creates the current project cloud workflows service account.
 */
resource "google_service_account" "workflows_sa" {
  project      = local.project
  account_id   = "${local.app_name_short}-sa-workflows-${local.project_env}"
  display_name = "Service Account for workflow template"
  description  = "Service Account for workflow template"
}

output "workflows_service_account" {
  value = google_service_account.workflows_sa.email
}

/**
 * Permission on itself
 */
resource "google_service_account_iam_member" "workflow_permissions_on_itself" {
  service_account_id = google_service_account.workflows_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.workflows_sa.email}"
}

/**
 * Gives necessary rights to the current project cloud workflows service account.
 */
resource "google_project_iam_member" "workflow_permissions" {
  for_each = local.workflows_sa_roles
  project  = local.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.workflows_sa.email}"
}
