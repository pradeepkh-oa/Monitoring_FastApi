# ======================================================================================== #
#    _____                  __                __   __        _      _    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   \ \ / /_ _ _ _(_)__ _| |__| |___ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   \ V / _` | '_| / _` | '_ \ / -_|_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   \_/\__,_|_| |_\__,_|_.__/_\___/__/
#
# ======================================================================================== #
variable "app_name" {
  type = string
}

variable "module_name" {
  type = string
}

variable "project" {
  type = string
}

variable "project_env" {
  type = string
}

variable "deploy_bucket" {
  type = string
}

variable "env_file" {
  type = string
}

variable "cloudrun_url_suffix" {
  type = string
}

variable "revision" {
  type = string
}
