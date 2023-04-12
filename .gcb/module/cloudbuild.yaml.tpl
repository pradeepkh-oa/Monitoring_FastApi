# ======================================================================================== #
#                         ___ _             _ _         _ _    _
#                        / __| |___ _  _ __| | |__ _  _(_) |__| |
#                       | (__| / _ \ || / _` | '_ \ || | | / _` |
#                        \___|_\___/\_,_\__,_|_.__/\_,_|_|_\__,_|
#
# ======================================================================================== #

# -- substitutions variables to be used
substitutions:
  _ENV:
  _TARGET:
  _APP_NAME_SHORT:
  _PROJECT_ENV:
  _GENERIC_BUILD_VERSION: py3.10-tf1.3.7-slim

options:
  dynamic_substitutions: true

# -- GCB user-specified SA management
serviceAccount: 'projects/$PROJECT_ID/serviceAccounts/${_APP_NAME_SHORT}-sa-cloudbuild-${_PROJECT_ENV}@$PROJECT_ID.iam.gserviceaccount.com'
logsBucket: 'gs://cloudbuild-gcs-eu-$PROJECT_ID/logs'

# -- build steps
steps:
  - id: 'Module %MODULE_NAME%: running target "%TARGET%"'
    name: gcr.io/itg-btdpshared-gbl-ww-pd/generic-build:${_GENERIC_BUILD_VERSION}
    entrypoint: make
    dir: modules/%MODULE_NAME%
    args: [
        'ENV=${_ENV}',
        '-f',
        '../../module.mk',
        '${_TARGET}'
      ]
