# ======================================================================================== #
#                     ___      _ _     __  __      _        __ _ _
#                    |_ _|_ _ (_) |_  |  \/  |__ _| |_____ / _(_) |___
#                     | || ' \| |  _| | |\/| / _` | / / -_)  _| | / -_)
#                    |___|_||_|_|\__| |_|  |_\__,_|_\_\___|_| |_|_\___|
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
include $(ROOT_DIR)/includes/failfast-checks.mk


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
# -- load variables from ENV
PROJECT         := $(shell jq -r '.project'                               $(ENV_FILE))
PROJECT_ENV     := $(shell jq -r --arg env $(ENV) '.project_env // $$env' $(ENV_FILE))
IS_SANDBOX      := $(shell jq -r '.is_sandbox // false'                   $(ENV_FILE))

# -- bucket definitions
DEPLOY_BUCKET   := $(APP_NAME_SHORT)-gcs-deploy-eu-$(PROJECT_ENV)

# -- location variables
ZONE            := $(shell jq -r '.zone   // "europe-west1-b"'                  $(ENV_FILE))
REGION          := $(shell jq -r '.region // ("$(ZONE)" | sub("-[a-z]$$"; ""))' $(ENV_FILE))

# -- access token to activate properly some APIs
ACCESS_TOKEN    := $(shell gcloud auth print-access-token --project $(PROJECT))


# ---------------------------------------------------------------------------------------- #
# -- < Feedback > --
# ---------------------------------------------------------------------------------------- #
# -- display environment variables
$(info $(shell printf "=%.s" $$(seq 100)))
$(info -- $(CURRENT_MAKEFILE): Environment variables)
$(info $(shell printf "=%.s" $$(seq 100)))

$(info ENV               = $(ENV))
$(info ENV_FILE          = $(ENV_FILE))
$(info APP_NAME          = $(APP_NAME))
$(info APP_NAME_SHORT    = $(APP_NAME_SHORT))
$(info PROJECT           = $(PROJECT))
$(info PROJECT_ENV       = $(PROJECT_ENV))
$(info ZONE              = $(ZONE))
$(info REGION            = $(REGION))
$(info DEPLOY_BUCKET     = $(DEPLOY_BUCKET))

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
all             Initializes the application (APis enabling, bucket creation, etc.)
create-bucket   Creates the deployment bucket necessary to store infrastructrue states
create-suffix   Creates the url suffix for Cloud Run (unique for a GCP project)
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
	@echo "-- Welcome to the initialization setup help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# This target will perform the complete setup of the current repository.
# ---------------------------------------------------------------------------------------- #
all: create-bucket iac-plan-clean iac-deploy create-suffix

.PHONY: clean
clean: iac-clean


# -- This target triggers the creation of the necessary buckets
.PHONY: create-bucket
create-bucket:
	@echo "[$@] :: creating bucket..."
	@gsutil ls -p $(PROJECT) gs://$(DEPLOY_BUCKET) 2>/dev/null || \
		gsutil mb -b on -l EU -p $(PROJECT) gs://$(DEPLOY_BUCKET);
	@gsutil versioning set on gs://$(DEPLOY_BUCKET);
	@echo "[$@] :: bucket creation is over."

# -- This target triggers the creation of the URL SUFFIX for Modules
.PHONY: create-suffix
create-suffix:
	@echo "[$@] :: creating suffix..."
	@gsutil -q stat gs://$(DEPLOY_BUCKET)/cloudrun-url-suffix/$(REGION) || \
		gcloud builds submit \
		--project $(PROJECT) \
		--config cloudbuild.yaml \
		--substitutions=_PROJECT=$(PROJECT),_DEPLOY_BUCKET=$(DEPLOY_BUCKET),_REGION=$(REGION) \
		--suppress-logs
	@echo "[$@] :: suffix creation is over."


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT  = .terraform/terraform.tfstate
TF_VARS  = terraform.tfvars
TF_PLAN  = tfplan
TF_STATE = $(wildcard *.tfstate .terraform/*.tfstate)
TF_FILES = $(wildcard *.tf)

.PHONY: iac-clean-state
iac-clean-state:
	@echo "[$@] :: cleaning the infrastructure state before plan or deploy"
	@if ! (terraform state list | grep "google_app_engine_application.app" >/dev/null); \
		then \
			echo "[$@] :: import App Engine into state if missing..."; \
			terraform import google_app_engine_application.app $(PROJECT) || true; \
		fi;
	@echo "[$@] :: state cleaning DONE."

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
			-backend-config=prefix=terraform-state/init \
			-input=false; \
	else \
		echo "[iac-init] :: terraform already initialized"; \
	fi;

# -- internal definition for easing changes
define HERE_TF_VARS
app_name       = "$(APP_NAME)"
project        = "$(PROJECT)"
project_env    = "$(PROJECT_ENV)"
access_token   = "$(ACCESS_TOKEN)"
region         = "$(REGION)"
env_file       = "$(ENV_FILE)"
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
$(TF_PLAN): $(TF_VARS) $(TF_FILES) iac-clean-state
	@echo "[iac-plan] :: planning the iac in $(PROJECT) ($(PROJECT_ENV))";
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
