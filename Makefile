# ======================================================================================== #
#                   ___  ___   ___ _____   __  __      _        __ _ _
#                  | _ \/ _ \ / _ \_   _| |  \/  |__ _| |_____ / _(_) |___
#                  |   / (_) | (_) || |   | |\/| / _` | / / -_)  _| | / -_)
#                  |_|_\\___/ \___/ |_|   |_|  |_\__,_|_\_\___|_| |_|_\___|
#
# ======================================================================================== #
# -- < Global configuration > --
# ======================================================================================== #
SHELL := /bin/bash

.DELETE_ON_ERROR:
.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL     := help
CURRENT_MAKEFILE  := $(lastword $(MAKEFILE_LIST))
CURRENT_LOCATION  := $(dir $(abspath $(CURRENT_MAKEFILE)))
ROOT_DIR          := $(CURRENT_LOCATION:%/=%)


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/common-variables.mk


# ---------------------------------------------------------------------------------------- #
# -- < Targets > --
# ---------------------------------------------------------------------------------------- #
# target .PHONY for defining elements that must always be run
# ---------------------------------------------------------------------------------------- #
.PHONY: help all clean iac-deploy test build deploy $(MODULES)


# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help              Displays the current message
init              Runs the all target in setup/init/Makefile
cicd              Runs the all target in setup/cicd/Makefile
all               Runs the all target on every module of the modules subdirectory
test              Runs the application by launching unit tests
build             Builds the application by producing artefacts (archives, docker images, etc.)
clean             Cleans the generated intermediary files
update	          Checks for updates on the project-framework repository
iac-init          Initializes the terraform infrastructure
iac-prepare       Prepares the terraform infrastructure by create the variable files
iac-plan          Produces the terraform plan to visualize what will be changed in the infrastructure
iac-deploy        Proceeds to the application of the terraform infrastructure
iac-clean         Cleans the intermediary terraform files to restart the process
deploy            Pushes the application artefact and deploys it by applying the terraform
reinit            Removes untracked files from the current git repository
pause-schedulers  Pauses all schedulers if IS_SANDBOX = true
endef
export HERE_HELP

help:
	@echo "-- Welcome to the root makefile help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# < init >
# ---------------------------------------------------------------------------------------- #
# -- this target will perform the complete init of a GCP project
.PHONY: init
init:
	@ENV=$(ENV) $(MAKE) -C setup/init -$(MAKEFLAGS) all


# ---------------------------------------------------------------------------------------- #
# < cicd >
# ---------------------------------------------------------------------------------------- #
# -- this target will perform the cicd setup of a GCP project (except Sandbox)
ifeq ($(IS_SANDBOX),false)
.PHONY: cicd
cicd:
	@ENV=cicd $(MAKE) -C setup/cicd -$(MAKEFLAGS) all
endif


# -- internal definition for easing changes
define HERE_CICD
steps:
  - id: CICD deploy
    name: gcr.io/itg-btdpshared-gbl-ww-pd/generic-build
    dir: setup/cicd
    entrypoint: make
    args:
      - ENV=cicd
      - all
endef
export HERE_CICD

.PHONY: gcb-cicd
gcb-cicd:
	tmp_file="cloudbuild-cicd.yaml" \
		&& echo "$$HERE_CICD" > "$${tmp_file}" \
		&& gcloud builds submit \
			--project $(shell cat environments/cicd.json | jq -r '.project') \
			--config "$${tmp_file}" \
		&& rm -f "$${tmp_file}" || rm -f "$${tmp_file}";


# ---------------------------------------------------------------------------------------- #
# -- < All > --
# ---------------------------------------------------------------------------------------- #
.PHONY: all %-all

# -- this target will perform a complete installation of the current repository.
all: $(MODULES)

# -- this targets will trigger a given target for all repository
%-all:
	$* $(foreach mod, $(MODULES), $*-module-$(mod))


# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the cleaning of the current parent
clean: iac-clean custom-clean

# -- this target will trigger the cleaning of the git repository, thus all untracked files
# will be deleted, so beware.
.PHONY: reinit
reinit:
	@git clean -f $(shell pwd)
	@git clean -fX $(shell pwd)


# ---------------------------------------------------------------------------------------- #
# -- < Modules > --
# ---------------------------------------------------------------------------------------- #
.PHONY: $(MODULES) $(MODULE_TARGETS)

# -- this target will trigger the full installation of a given module
$(MODULES):
	@echo "Calling module.mk for $@"
	@$(MAKE) -f ../../module.mk -C modules/$@ -$(MAKEFLAGS) all MODULE_NAME=$@


MODULE_TARGETS = $(addprefix %-module-,$(MODULES)) # %-module-<ANY_EXISTING_MODULE>

# -- this targets will trigger a given target for a given module
$(MODULE_TARGETS):
	@echo "Calling module.mk for $@"
	@MODULE=$$(echo "$@" | sed -E "s/.+-module-(.+)/\1/g"); \
		$(MAKE) -f ../../module.mk -C modules/$$MODULE -$(MAKEFLAGS) $* MODULE_NAME=$$MODULE

# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT  = iac/.terraform/terraform.tfstate
TF_VARS  = iac/terraform.tfvars
TF_PLAN  = iac/tfplan
TF_STATE = $(wildcard iac/*.tfstate iac/.terraform/*.tfstate)
TF_FILES = $(wildcard iac/*.tf)


# -- internal definition for easing changes
define HERE_TF_VARS
app_name          = "$(APP_NAME)"
env_file          = "$(ENV_FILE)"
project           = "$(PROJECT)"
project_env       = "$(PROJECT_ENV)"
deploy_bucket     = "$(DEPLOY_BUCKET)"
endef
export HERE_TF_VARS


# -- this target will initialize the terraform initialization
.PHONY: iac-init
iac-init: $(TF_INIT) # provided for convenience
$(TF_INIT):
	@if [ ! -d iac ]; then \
		echo "[iac-init] :: no infrastructure"; \
	else \
		cd iac; \
		if [ ! -d .terraform ]; then \
			function remove_me() { if (( $$? != 0 )); then rm -fr .terraform; fi; }; \
			trap remove_me EXIT; \
			echo "[iac-init] :: initializing terraform"; \
			echo "$(PROJECT_ENV)" > .iac-env; \
			terraform init \
				-backend-config=bucket=$(DEPLOY_BUCKET) \
				-backend-config=prefix=terraform-state/global \
				-input=false; \
		else \
			echo "[iac-init] :: terraform already initialized"; \
		fi; \
	fi;

# -- this target will create the terraform.tfvars file
.PHONY: iac-prepare
iac-prepare: $(TF_VARS) # provided for convenience
$(TF_VARS): $(TF_INIT)
	@if [ -d iac ]; then \
		echo "[iac-prepare] :: generation of $(TF_VARS) file"; \
		echo "$$HERE_TF_VARS" > $(TF_VARS); \
		echo "[iac-prepare] :: generation of $(TF_VARS) file DONE."; \
	else \
		echo "[iac-prepare] :: no infrastructure"; \
	fi;

# -- this target will create the iac/tfplan file whenever the variables file and any *.tf
# file have changed
.PHONY: iac-plan iac-plan-clean
iac-plan-clean:
	@rm -f iac/tfplan

iac-plan: iac-clean $(TF_PLAN) # provided for convenience
$(TF_PLAN): $(TF_VARS) $(TF_FILES)
	@set -euo pipefail; \
	if [ -d iac ]; then \
		echo "[iac-plan] :: planning the iac in $(PROJECT) ($(PROJECT_ENV))"; \
		cd iac && terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN)); \
		echo "[iac-plan] :: planning the iac for $(APP_NAME) DONE."; \
	else \
		echo "[iac-plan] :: no infrastructure"; \
	fi;


# -- this target will only trigger the iac of the current parent
.PHONY: iac-deploy
iac-deploy: iac-clean $(TF_PLAN)
	@echo "[$@] :: launching the parent iac target on $(APP_NAME)"
	@if [ -d iac ]; then \
		cd iac; \
		terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN)); \
	else \
		echo "[$@] :: no infrastructure"; \
	fi;
	@echo "[$@] :: is finished on $(APP_NAME)"


# -- this target will clean the intermediary iac files
# might need to delete the iac/.terraform/terraform.tfstate file
.PHONY: iac-clean
iac-clean:
	@echo "[$@] :: cleaning Iac intermediary files : '$(TF_PLAN), $(TF_VARS)'"
	@if [ -d iac ]; then \
		rm -fr $(TF_PLAN) $(TF_VARS); \
		if [ ! -f iac/.iac-env ] || [ $$(cat iac/.iac-env || echo -n) != $(PROJECT_ENV) ]; then \
			echo "[$@] :: env has changed, removing also iac/.terraform"; \
			rm -rf iac/.terraform iac/.terraform.lock.hcl; \
		fi; \
	fi;
	@echo "[$@] :: cleaning Iac intermediary files DONE."


# ---------------------------------------------------------------------------------------- #
# -- < Testing > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the testing of the current parent
.PHONY: test
test: # provided for convenience


# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the build of the current parent
.PHONY: build
build: # provided for convenience


# ---------------------------------------------------------------------------------------- #
# -- < Pause schedulers in sbx > --
# ---------------------------------------------------------------------------------------- #
.PHONY: pause-schedulers
ifeq ($(IS_SANDBOX), true)
pause-schedulers:
	@echo "[$@] :: Pause all schedulers of sandbox."
	@gcloud scheduler jobs list --project $(PROJECT) --format="value(ID)" |\
		while read job;\
		do \
			echo "pausing: $$job"; \
			gcloud scheduler jobs pause --project $(PROJECT) $$job; \
		done
	@echo "[$@] :: All schedulers are paused."
else
pause-schedulers:
	@echo "[$@] :: Nothing to do as the project is not a sandbox."
endif


# ---------------------------------------------------------------------------------------- #
# -- < Deploying > --
#
# Targets are used to perform the deployment of both the main parent and its modules.
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the deployment of the current parent
.PHONY: deploy
deploy: iac-deploy custom-deploy pause-schedulers


# ---------------------------------------------------------------------------------------- #
# -- < Include Custom makefile > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/custom.mk


# ---------------------------------------------------------------------------------------- #
# -- < Cloudbuild activation > --
# ---------------------------------------------------------------------------------------- #

# -- cloudbuild authorized targets
GCB_TARGETS       := all help test build deploy sql-deploy iac-plan iac-deploy $(MODULES)
GCB_TEMPLATES_DIR := $(ROOT_DIR)/.gcb/root

# -- includes the gcb makefile after the mandatory variables definition
include $(ROOT_DIR)/includes/cloudbuild.mk

# ---------------------------------------------------------------------------------------- #
# -- < Updater > --
# ---------------------------------------------------------------------------------------- #

update:
	@$(ROOT_DIR)/bin/update
