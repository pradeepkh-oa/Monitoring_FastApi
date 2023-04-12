data "google_project" "env_projects" {
  provider   = google-beta
  for_each   = toset([for key, val in local.triggers_env : key])
  project_id = local.triggers_env_conf[each.key].project
}
