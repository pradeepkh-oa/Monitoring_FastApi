# ======================================================================================== #
#                    ___ ___ ___ ___    __  __      _        __ _ _
#                   / __|_ _/ __|   \  |  \/  |__ _| |_____ / _(_) |___
#                  | (__ | | (__| |) | | |\/| / _` | / / -_)  _| | / -_)
#                   \___|___\___|___/  |_|  |_\__,_|_\_\___|_| |_|_\___|
#
# ======================================================================================== #
# -- < Global configuration > --
# ======================================================================================== #
SHELL := /bin/bash

.DELETE_ON_ERROR:
.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL     := help
CURRENT_MAKEFILE  := $(lastword $(MAKEFILE_LIST))
CURRENT_LOCATION  := $(dir $(abspath ../../$(CURRENT_MAKEFILE)))
ROOT_DIR          := $(CURRENT_LOCATION:%/=%)


# ---------------------------------------------------------------------------------------- #
# -- < Environment fail fast checks > --
# ---------------------------------------------------------------------------------------- #
# enforced value
CICD_ENV_LIST     := cicd ops-cicd
ifeq (,$(filter $(ENV), $(CICD_ENV_LIST)))
ENV               := cicd
endif

# -- load the configuration environment file
ENV_DIR         := $(ROOT_DIR)/environments
ENV_FILE        := $(ENV_DIR)/$(ENV).json
OPS_ENV_LIST    := ops-cicd

ifeq ($(wildcard $(ENV_FILE)),)
$(error ENV $(ENV): env file not found)
endif

# -- compute application variables
ifeq (,$(wildcard $(ROOT_DIR)/.app_name))
$(error application file: $(ROOT_DIR)/.app_name not found)
# -- for the envs not in the list read from .app_name file
else ifeq (,$(filter $(ENV), $(OPS_ENV_LIST)))
APP_NAME        := $(shell cat $(ROOT_DIR)/.app_name)
# -- read value from env file for ops projects
else
APP_NAME        := $(shell jq -r '.app_name' $(ENV_FILE))
endif
APP_NAME_SHORT  := $(shell sed 's/-//g' <<< "$(APP_NAME)")


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
PROJECT              := $(shell jq -r '.project' $(ENV_FILE))
PROJECT_ENV          := $(shell jq -r '.project_env // "pd"' $(ENV_FILE))
INTEGRATION_PROJECT  := $(shell jq -r '.integration_project' $(ENV_FILE))
REPOSITORY_NAME      := $(shell jq -r --arg value $(APP_NAME) '.repository_name // $$value' $(ENV_FILE))

# -- bucket definitions
DEPLOY_BUCKET         := $(shell jq -r '.deploy_bucket' $(ENV_FILE))
INTEGRATION_BUCKET    := $(shell jq -r '.integration_bucket' $(ENV_FILE))

# Files to protect
PROTECTED_FILES := Makefile module.mk custom.mk \
		includes/*.mk \
		environments/cicd.json environments/ops-cicd.json

# compute the list of protected files that are present
REAL_PROTECTED_FILES     := $(addprefix $(ROOT_DIR)/, $(PROTECTED_FILES))
EXISTING_PROTECTED_FILES := $(wildcard $(REAL_PROTECTED_FILES))
USABLE_PROTECTED_FILES   := $(EXISTING_PROTECTED_FILES:$(ROOT_DIR)/%=%)

#
# -- compute module variables
MODULES_DIR      = $(filter %/, $(wildcard ../../modules/*/))
MODULES          = $(filter-out %.sample, $(sort $(MODULES_DIR:../../modules/%/=%)))

# -- display environment variables
$(info $(shell printf "=%.s" $$(seq 100)))
$(info -- $(CURRENT_MAKEFILE): Environment variables)
$(info $(shell printf "=%.s" $$(seq 100)))

$(info ENV                  = $(ENV))
$(info ENV_FILE             = $(ENV_FILE))
$(info APP_NAME             = $(APP_NAME))
$(info APP_NAME_SHORT       = $(APP_NAME_SHORT))
$(info PROJECT              = $(PROJECT))
$(info PROJECT_ENV          = $(PROJECT_ENV))
$(info DEPLOY_BUCKET        = $(DEPLOY_BUCKET))
$(info INTEGRATION_BUCKET   = $(INTEGRATION_BUCKET))
$(info INTEGRATION_PROJECT  = $(INTEGRATION_PROJECT))
$(info REPOSITORY_NAME      = $(REPOSITORY_NAME))
$(info MODULES              = $(MODULES))
$(info PROTECTED_FILES      = $(USABLE_PROTECTED_FILES))

$(info $(shell printf "=%.s" $$(seq 100)))


# ---------------------------------------------------------------------------------------- #
# -- < Targets > --
# ---------------------------------------------------------------------------------------- #
# target .PHONY for defining elements that must always be run
# other targets are locally added to .PHONY
# ---------------------------------------------------------------------------------------- #
.PHONY: help all


# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help            Displays the current message
display-env     Displays the environment variables that will be used
all             Initializes the application (APis enabling, bucket creation, etc.)
create-bucket   Creates the deployment bucket necessary to store infrastructrue states
clean           Cleans all the files created by the setup process
iac-prepare     Prepares the terraform infrastructure by create the variable files
iac-plan        Produces the terraform plan to visualize what will be changed in the
                infrastructure
iac-deploy      Proceeds to the application of the terraform infrastructure
iac-clean       Cleans the intermediary terraform files to restart the process
reinit          Remove untracked files from the current git repository
endef
export HERE_HELP

help:
	@echo "-- Welcome to the cicd setup help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""



# ---------------------------------------------------------------------------------------- #
# This target will perform the complete setup of the current repository.
# ---------------------------------------------------------------------------------------- #
all: create-bucket iac-plan-clean iac-deploy

clean: iac-clean


# -- This target triggers the creation of the necessary buckets
.PHONY: create-bucket
create-bucket:
	@echo "[$@] :: creating buckets..."
	@gsutil ls -p $(PROJECT) gs://$(DEPLOY_BUCKET) 2>/dev/null || \
		gsutil mb -b on -l EU -p $(PROJECT) gs://$(DEPLOY_BUCKET);
	@gsutil versioning set on gs://$(DEPLOY_BUCKET);
	@gsutil ls -p $(INTEGRATION_PROJECT) gs://$(INTEGRATION_BUCKET) 2>/dev/null || \
		gsutil mb -b on -l EU -p $(INTEGRATION_PROJECT) gs://$(INTEGRATION_BUCKET);
	@echo "[$@] :: buckets creation is over."


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT  = .terraform/terraform.tfstate
TF_VARS  = terraform.tfvars
TF_PLAN  = tfplan
TF_STATE = $(wildcard *.tfstate .terraform/*.tfstate)
TF_FILES = $(wildcard *.tf) $(wildcard $(ENV_DIR)/*.json)

# -- this target will clean the local terraform infrastructure
.PHONY: iac-clean
iac-clean:
	@echo "[$@] :: cleaning the infrastructure intermediary files"
	@rm -fr $(TF_PLAN) $(TF_VARS);
	@if [ ! -f .iac-env ] || [ $$(cat .iac-env || echo -n) != $(PROJECT_ENV) ]; then \
		echo "[$@] :: env has changed, removing also .terraform*"; \
		rm -rf .terraform .terraform.lock.hcl; \
	fi;
	@echo "[$@] :: infrastructure cleaning DONE"

# -- this target will initialize the terraform initialization
.PHONY: iac-init
iac-init: $(TF_INIT) # provided for convenience
$(TF_INIT):
	@set -euo pipefail; \
	if [ ! -d .terraform ]; then \
		function remove_me() { if (( $$? != 0 )); then rm -fr .terraform; fi; }; \
		trap remove_me EXIT; \
		echo "[iac-init] :: initializing terraform"; \
		echo "$(PROJECT_ENV)" > .iac-env; \
		terraform init \
			-backend-config=bucket=$(DEPLOY_BUCKET) \
			-backend-config=prefix=terraform-state/cicd \
			-input=false; \
	else \
		echo "[iac-init] :: terraform already initialized"; \
	fi;

# -- internal definition for easing changes
define HERE_TF_VARS
app_name        = "$(APP_NAME)"
deploy_bucket   = "$(DEPLOY_BUCKET)"
env_file        = "$(ENV_FILE)"
modules         = "$(MODULES)"
protected_files = "$(USABLE_PROTECTED_FILES)"
endef
export HERE_TF_VARS

# -- this target will create the terraform.tfvars file
.PHONY: iac-prepare
iac-prepare: $(TF_VARS) # provided for convenience
$(TF_VARS): $(TF_INIT)
	@echo "[iac-prepare] :: generation of $(TF_VARS) file";
	@echo "$$HERE_TF_VARS" > $(TF_VARS);
	@echo "[iac-prepare] :: generation of $(TF_VARS) file DONE.";

# -- this target will create the tfplan file whenever the variables file and any *.tf
# file have changed
.PHONY: iac-plan iac-plan-clean
iac-plan-clean:
	@rm -f tfplan

iac-plan: iac-clean $(TF_PLAN) # provided for convenience
$(TF_PLAN): $(TF_VARS) $(TF_FILES)
	@echo "[iac-plan] :: planning the iac";
	@set -euo pipefail; \
	terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN));
	@echo "[iac-plan] :: planning the iac for $(APP_NAME) DONE.";

# -- this target will only trigger the iac of the current parent
.PHONY: iac-deploy
iac-deploy: iac-clean $(TF_PLAN)
	@echo "[$@] :: applying the infrastructure for $(APP_NAME)"
	@terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN));
	@echo "[$@] :: infrastructure applied on $(APP_NAME)"

# -- this target re-initializes the git working tree removing untracked and ignored files
.PHONY: reinit
reinit:
	@rm -rf .terraform* terraform.tfstate* tfplan
