# ======================================================================================== #
#                    _                     __  __      _        __ _ _
#                   /_\  __ __ ___ ______ |  \/  |__ _| |_____ / _(_) |___
#                  / _ \/ _/ _/ -_|_-<_-< | |\/| / _` | / / -_)  _| | / -_)
#                 /_/ \_\__\__\___/__/__/ |_|  |_\__,_|_\_\___|_| |_|_\___|
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
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/common-variables.mk


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
help              Displays the current message
all               Initializes the application (APis enabling, bucket creation, etc.)
clean             Cleans all the files created by the setup process
iac-prepare       Prepares the terraform infrastructure by create the variable files
iac-plan          Produces the terraform plan to visualize what will be changed in the
                  infrastructure
iac-deploy        Proceeds to the application of the terraform infrastructure
iac-plan-destroy  Produces the terraform plan destroy to visualize what will be destroyed
                  in the infrastructure
iac-destroy       Proceeds to the destruction of the terraform infrastructure
                  (the iac-plan-destroy should be called beforehand).
                  It is only available for sbx and dv environments.
iac-clean         Cleans the intermediary terraform files to restart the process
reinit            Remove untracked files from the current git repository
endef
export HERE_HELP

help:
	@echo "-- Welcome to the access setup help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""

# ---------------------------------------------------------------------------------------- #
# This target will perform the access setup of the current repository.
# ---------------------------------------------------------------------------------------- #
all: iac-clean iac-deploy

.PHONY: clean
clean: iac-clean


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT    = .terraform/terraform.tfstate
TF_VARS    = terraform.tfvars
TF_PLAN    = tfplan
TF_DESTROY = tfdestroy
TF_STATE   = $(wildcard *.tfstate .terraform/*.tfstate)
TF_FILES   = $(wildcard *.tf)
TF_ALLOWED = dv sbx

TF_CONFIG_FILES = $(shell find . -type f \( -name '*.json' -o -name '*.yaml' \) | cut -c 3-)


# -- this target will clean the local terraform infrastructure
.PHONY: iac-clean
iac-clean:
	@echo "[$@] :: cleaning the infrastructure intermediary files"
	@rm -fr $(TF_PLAN) $(TF_VARS) $(TF_DESTROY);
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
			-backend-config=prefix=terraform-state/access \
			-input=false; \
	else \
		echo "[iac-init] :: terraform already initialized"; \
	fi;

# -- internal definition for easing changes
define HERE_TF_VARS
app_name          = "$(APP_NAME)"
project           = "$(PROJECT)"
project_env       = "$(PROJECT_ENV)"
env_file          = "$(ENV_FILE)"
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
.PHONY: iac-plan
iac-plan: iac-clean $(TF_PLAN) # provided for convenience
$(TF_PLAN): $(TF_VARS) $(TF_FILES) $(TF_CONFIG_FILES)
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


# Allow terraform destroy for sandbox and dv environments only (here the filter will be empty)
ifneq (,$(filter $(ENV), $(TF_ALLOWED)))

iac-plan-destroy: $(TF_DESTROY) # provided for convenience
$(TF_DESTROY): $(TF_VARS) $(TF_FILES) $(TF_CONFIG_FILES)
	@echo "[iac-plan-destroy] :: planning the iac destruction in $(PROJECT) ($(PROJECT_ENV))";
	@set -euo pipefail; \
	terraform plan \
		-destroy \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_DESTROY));
	@echo "[iac-plan-destroy] :: planning the iac destruction for $(APP_NAME) DONE.";

# -- this target wil only trigger the iac destruction
.PHONY: iac-destroy
iac-destroy: iac-clean $(TF_DESTROY)
	@echo "[$@] :: destroying the infrastructure for $(APP_NAME) in env $(ENV)"
	@terraform apply "$(TF_DESTROY)"
	@echo "[$@] :: infrastructure destroyed for $(APP_NAME) in env $(ENV)"

else

iac-plan-destroy:
	$(error Terraform destruction NOT ALLOWED on env = $(ENV))

iac-destroy:
	$(error Terraform destruction NOT ALLOWED on env = $(ENV))

endif # TF destroy

# -- this target re-initializes the git working tree removing untracked and ignored files
.PHONY: reinit
reinit:
	@git clean -f $(shell pwd)
	@git clean -fX $(shell pwd)
