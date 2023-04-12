# ======================================================================================== #
#     ___           __ _        ___     _            __
#    / __|___ _ _  / _(_)__ _  |_ _|_ _| |_ ___ _ _ / _|__ _ __ ___
#   | (__/ _ \ ' \|  _| / _` |  | || ' \  _/ -_) '_|  _/ _` / _/ -_)
#    \___\___/_||_|_| |_\__, | |___|_||_\__\___|_| |_| \__,_\__\___|
#                       |___/
# ======================================================================================== #
# -- Define Rest API objects to publish configs to BTDP config-interface
# Bucket notifications can be found in buckets.tf. They are kept separate
# as they are not really a configuration for the users to create.

# INITIALIZATION

# -- REST API provider for Configuration Interface API endpoints
provider "restapi" {
  alias = "configinterface"
  uri   = local.apis_base_url.configinterface
  headers = {
    "Authorization" = "Bearer ${local.is_sbx ? "<none>" : data.google_service_account_access_token.cloudbuild_sa[0].access_token}"
  }
  write_returns_object = true
}
