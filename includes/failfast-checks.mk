# ======================================================================================== #
#                 ___     _ _   ___        _      ___ _           _
#                | __|_ _(_) | | __|_ _ __| |_   / __| |_  ___ __| |__ ___
#                | _/ _` | | | | _/ _` (_-<  _| | (__| ' \/ -_) _| / /(_-<
#                |_|\__,_|_|_| |_|\__,_/__/\__|  \___|_||_\___\__|_\_\/__/
#
# ======================================================================================== #

# -- default value is sbx for sbx.json environment file
ifeq ($(ENV),)
  $(error ENV is not set)
endif

# -- load the configuration environment file
ENV_DIR         := $(ROOT_DIR)/environments
ENV_FILE        := $(ENV_DIR)/$(ENV).json
OPS_ENV_LIST    := ops-np ops-qa
ENV_FORBIDDEN   := cicd

ifeq ($(wildcard $(ENV_FILE)),)
  $(error ENV $(ENV): env file not found)
endif

# -- compute application variables
ifeq (,$(wildcard $(ROOT_DIR)/.app_name))
  $(shell cd $(ROOT_DIR)/environments && ./instantiate-template.sh $(ROOT_DIR))
endif

# -- forbids the use of a cicd.json file to prevent unpredictable behaviour
ifneq (,$(findstring $(ENV), $(ENV_FORBIDDEN)))
  $(error can't use a dedicated cicd ENV value, '$(ENV)' in the current context)

# -- for the envs not in the list read from .app_name file
else ifeq (,$(filter $(ENV), $(OPS_ENV_LIST)))
  APP_NAME      := $(shell cat $(ROOT_DIR)/.app_name)
# -- read value from env file for ops projects
else
  APP_NAME      := $(shell jq -r '.app_name' $(ENV_FILE))
endif
APP_NAME_SHORT  := $(shell sed 's/-//g' <<< "$(APP_NAME)")
