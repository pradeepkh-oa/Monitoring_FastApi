# ======================================================================================== #
#     ___        _              __   __        _      _    _
#    / __|  _ __| |_ ___ _ __   \ \ / /_ _ _ _(_)__ _| |__| |___ ___
#   | (_| || (_-<  _/ _ \ '  \   \ V / _` | '_| / _` | '_ \ / -_|_-<
#    \___\_,_/__/\__\___/_|_|_|   \_/\__,_|_| |_\__,_|_.__/_\___/__/
#
# ======================================================================================== #
variable "app_name" {
  type = string
}

variable "app_name_short" {
  type = string
}

variable "project" {
  type = string
}

variable "project_env" {
  type = string
}

variable "is_sbx" {
  type = string
}

variable "deploy_bucket" {
  type = string
}

variable "cloudrun_url_suffix" {
  type = string
}

variable "env_file" {
  type = map(any)
}

variable "zone" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "region" {
  type = string
}

variable "region_id" {
  type = string
}

variable "multiregion" {
  type = string
}

variable "workflow_region" {
  type = string
}

variable "workflow_region_id" {
  type = string
}

variable "project_roles" {
  type = list(string)
}

variable "btdpback_project" {
  type = string
}

variable "btdpfront_project" {
  type = string
}

variable "apis_base_url" {
  type = map(string)
}

variable "cloudbuild_sa" {
  type = string
}

variable "core" {
  type = object({})
}
