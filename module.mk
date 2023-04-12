# ======================================================================================== #
#             __  __         _      _       __  __      _        __ _ _
#            |  \/  |___  __| |_  _| |___  |  \/  |__ _| |_____ / _(_) |___
#            | |\/| / _ \/ _` | || | / -_) | |\/| / _` | / / -_)  _| | / -_)
#            |_|  |_\___/\__,_|\_,_|_\___| |_|  |_\__,_|_\_\___|_| |_|_\___|
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
# -- < pre-requisites verification > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/pre-requisite.mk


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/common-variables.mk


# -- compute module variables
MODULE_NAME          ?= $(shell basename $$(pwd))
override MODULE_NAME := $(shell sed -E 's/^([0-9]+[-])?//' <<< "$(MODULE_NAME)")
MODULE_NAME_SHORT    := $(shell sed 's/-//g' <<< "$(MODULE_NAME)")

MODULE_RAW_NAME      := $(filter %$(MODULE_NAME), $(MODULES))

# -- default module type is gcr (for Google Cloud Run)
ifeq (,$(wildcard .module_type))
TYPE                 := gcr
else
TYPE                 := $(shell cat .module_type)
endif

SUPPORTED_MODULE_TYPES := gcr gcf gcb

ifeq ($(filter $(TYPE),$(SUPPORTED_MODULE_TYPES)),)
$(error ERROR: Unknown or unsupported module type '$(TYPE)'. It must belong to: $(SUPPORTED_MODULE_TYPES))
endif

# -- apigee variables
APIS_FILE                := $(ENV_DIR)/apis.json
ifeq ($(wildcard $(APIS_FILE)),)
$(error ERROR: apis.json file not found: $(APIS_FILE))
endif
APIGEE_DEPLOYER_ENDPOINT := $(shell jq -re '.apigeedeployer' $(APIS_FILE))/v1
APIGEE_PAYLOAD           := apigee_deploy_payload.json
APIGEE_RESPONSE_PAYLOAD  := apigee_deploy_response_payload.json
APIGEE_DEPLOY_SA         := $(APP_NAME_SHORT)-sa-cloudbuild-$(PROJECT_ENV)@$(PROJECT).iam.gserviceaccount.com

API_CONF_FILE            := api_conf.json

# -- display environment variables (always printed)
$(info MODULE_RAW_NAME   = $(MODULE_RAW_NAME))
$(info MODULE_NAME       = $(MODULE_NAME))
$(info MODULE_NAME_SHORT = $(MODULE_NAME_SHORT))
$(info TYPE              = $(TYPE))

$(info $(shell printf "=%.s" $$(seq 100)))


# ---------------------------------------------------------------------------------------- #
# -- < Targets > --
# ---------------------------------------------------------------------------------------- #
# target .PHONY for defining elements that must always be run
# ---------------------------------------------------------------------------------------- #
.PHONY: help all clean iac-deploy test build deploy


# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help              Display the current message
all               Build and deploy the module
                  > clean prepare-test build deploy
clean             Clean the generated intermediary files
                  > clean-app iac-clean
prepare-test     (auto) Prepare the Python tests by installing the requirements
build             Build the application by producing artefacts (archives, docker image, etc.)
                  > test hadolint-test build-app
deploy            Push the application artefacts and deploy infrastructure with terraform
                  > deploy-app iac-plan-clean iac-deploy pause-schedulers

clean-app         Clean the intermediary files and application artifacts stored locally
deploy-app        Push the application artefact

test              Test the application by launching Python unit tests
hadolint-test     Verify the integrity of the Dockerfile

iac-clean         Clean the intermediary terraform files stored locally to restart the process.
                  It is done automatically when changing ENV
iac-init          (auto) Initialize the terraform infrastructure
iac-prepare       (auto) Prepare the terraform infrastructure by create the variable files
iac-plan          (auto) Produce the terraform plan to visualize what will be changed in the infrastructure
iac-plan-clean    Remove the previous terraform plan
iac-deploy        Proceed to the application of the terraform infrastructure

deploy-apigee     Push the module API as proxy in Apigee

pause-schedulers  Pause all schedulers if IS_SANDBOX=true
reinit            Remove untracked files from the current git repository


The supported module types are:
------------------------------
gcr               Module to deploy an API on Google Cloud Run. It must contain a Dockerfile
gcf               Module to deploy a Google Function.
gcb               Module to deploy Google Cloud Build triggers that run Python code.
                  E.g. to run e2e-tests that validate several modules working together.
endef
export HERE_HELP

help:
	@echo "-- Welcome to the module makefile help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


all: clean hadolint-test prepare-test build deploy
	@echo "Makefile launched in $(shell basename ${PWD}) for $(MODULE_NAME)"


# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
clean: clean-app iac-clean
	@echo "[$@] :: Cleaning of module $(MODULE_NAME) DONE."


# -- this target will trigger the cleaning of the git repository, thus all untracked files
# will be deleted, so beware.
reinit:
	@git clean -f $(shell pwd)
	@git clean -fX $(shell pwd)


# ---------------------------------------------------------------------------------------- #
# -- < Testing > --
# ---------------------------------------------------------------------------------------- #
PYTHON_SRC         := src
PYTHON_E2E_TESTS   := e2e-tests

SRC_FILES          := $(shell find $(PYTHON_SRC) -type f \
	! -name '*.pyc' -and ! -name '*_test.py' -and ! -name conftest.py \
	2>/dev/null \
)
TEST_FILES         := $(shell find $(PYTHON_SRC) -type f \
	-name '*_test.py' -or -name conftest.py \
	2>/dev/null \
)
E2E_TEST_FILES     := $(shell find $(PYTHON_E2E_TESTS) -type f \
	! -name '*.pyc' \
	2>/dev/null \
)
TEST_ENV           := test_env.sh
VIRTUAL_ENV        := .venv
BUILD_REQUIREMENTS := requirements.txt
TESTS_REQUIREMENTS := requirements-test.txt
LOCAL_REQUIREMENTS := $(shell find . -type f \
	-name 'requirements-*.txt' -and ! -name $(TESTS_REQUIREMENTS) \
)

ifeq ($(wildcard $(BUILD_REQUIREMENTS)),)
$(error ERROR: $(BUILD_REQUIREMENTS) file not found in modules/$(MODULE_RAW_NAME))
endif

PYLINTRC_LOCATION   = ../../.pylintrc
COVERAGERC_LOCATION = ../../.coveragerc

DOCKERFILE          = Dockerfile

PYTHON_LIB_NAME        = loreal
PYTHON_LIB_ARTREG_PATH = europe-west1-python.pkg.dev/itg-btdpshared-gbl-ww-pd/pydft-artreg-pythonrepository-ew1-pd/simple/
PYTHON_LIB_INDEX_URL   = https://oauth2accesstoken:$(shell gcloud auth print-access-token)@$(PYTHON_LIB_ARTREG_PATH)

define HERE_TESTS_REQUIREMENTS
pytest==7.2.1
pytest-cov==4.0.0
bandit==1.7.4
black==23.1.0
pylint==2.16.1
pytest-parallel==0.1.1
pytest-repeat==0.9.1
dependency-check==0.6.0
pydocstyle==6.3.0
mypy==1.1.1
endef
export HERE_TESTS_REQUIREMENTS

# -- this target will produce the test requirements for python
prepare-test: $(TESTS_REQUIREMENTS) $(VIRTUAL_ENV)
$(TESTS_REQUIREMENTS):
	@echo "[prepare-test] :: creating requirements for test"
	@echo "$$HERE_TESTS_REQUIREMENTS" > $@
	@echo "[prepare-test] :: test requirements creation DONE."

# BEWARE: hack using a trap to ensure the virtual env directory will be remove
# if the installation process fails
$(VIRTUAL_ENV): $(TESTS_REQUIREMENTS) $(BUILD_REQUIREMENTS) $(LOCAL_REQUIREMENTS)
	@echo "[prepare-test] :: Checking requirements of module $(MODULE_NAME)"
	@set -euo pipefail; \
		if ( \
			cat $(BUILD_REQUIREMENTS) \
				| sed -E -e 's/#.*//' -e 's/ +$$//' -e '/^$$/d' -e 's/--\w+ .*//' \
				| grep -vqE '[~<=>]='; \
		); then \
			echo '[prepare-test] :: At least one dependency has no version specified in $(BUILD_REQUIREMENTS).'; \
			exit 1; \
		fi;
	@echo "[prepare-test] :: Creating the virtual environment"
	@set -euo pipefail; \
		function remove_me() { if (( $$? != 0 )); then rm -fr $@; fi; }; \
		trap remove_me EXIT; \
		rm -rf $@; \
		$(PYTHON_BIN) -m venv $@; \
		source $@/bin/activate; \
		pip install -r $(TESTS_REQUIREMENTS); \
		if [ ! -z "$(LOCAL_REQUIREMENTS)" ]; then \
			pip install $(addprefix -r ,$(LOCAL_REQUIREMENTS)); \
		fi; \
		pip install --no-cache-dir --extra-index-url $(PYTHON_LIB_INDEX_URL) -r $(BUILD_REQUIREMENTS);
	@echo "[prepare-test] :: virtual environment creation DONE."

# -- this target will trigger the tests
test: prepare-test
	@set -euo pipefail; \
		if [ ! -d $(PYTHON_SRC) ]; then \
			echo "[$@] :: Nothing to do since $(PYTHON_SRC)/ is empty"; \
			exit 0; \
		fi; \
		echo "[$@] :: Testing module $(MODULE_NAME)"; \
		\
		source $(VIRTUAL_ENV)/bin/activate; \
		pylint --reports=n --rcfile=$(PYLINTRC_LOCATION) $(PYTHON_SRC); \
		black --check --diff $(PYTHON_SRC); \
		bandit -r -x '*_test.py' -f screen $(PYTHON_SRC); \
		eval "$$HERE_BASE_TEST_ENV"; \
		DB_HOST=localhost; \
		[ -f $(TEST_ENV) ] && source ./$(TEST_ENV); \
		$(PYTHON_BIN) -m pytest -vv \
			--cov $(PYTHON_SRC) \
			--cov-config=$(COVERAGERC_LOCATION) \
			--cov-report term-missing \
			--cov-fail-under 100 \
			$(PYTHON_SRC); \
		\
		echo "[$@] :: Testing DONE."


e2e-test: prepare-test
	@set -euo pipefail; \
		if [ ! -d $(PYTHON_E2E_TESTS) ]; then \
			echo "[$@] :: Nothing to do since $(PYTHON_E2E_TESTS)/ is empty"; \
			exit 0; \
		fi; \
		echo "[$@] :: Running end-to-end tests for module $(MODULE_NAME)"; \
		\
		source $(VIRTUAL_ENV)/bin/activate; \
		pylint --reports=n --rcfile=$(PYLINTRC_LOCATION) $(PYTHON_E2E_TESTS)/*.py; \
		black --check --diff $(PYTHON_E2E_TESTS); \
		eval "$$HERE_BASE_TEST_ENV"; \
		[ -f $(TEST_ENV) ] && source ./$(TEST_ENV); \
		$(PYTHON_BIN) -m pytest -vv \
			$(PYTHON_E2E_TESTS); \
		\
		echo "[$@] :: End-to-end testing DONE."


ifeq ($(TYPE), gcr)
# -- this target will execute static test on Dockerfile of a module with Hadolint
ifeq ($(wildcard $(DOCKERFILE)),)
  $(error $(DOCKERFILE) file not found)
endif

hadolint-test:
	@echo "[$@] :: Test $(DOCKERFILE) with hadolint for module $(MODULE_NAME)"
	@if ( \
			docker run --rm -i hadolint/hadolint hadolint \
			--ignore DL3008 \
			--ignore DL3025 \
			- < $(DOCKERFILE) \
		); then \
			echo "[$@] :: $(DOCKERFILE) full validation DONE."; \
		else \
			echo "[$@] :: WARNING: Some issues have been found in $(DOCKERFILE). Please address them..."; \
		fi;

else

hadolint-test:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

endif # definition of: hadolint-test


# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #
ifeq ($(TYPE), gcr)

BUILD_REVISION   := revision
GCR_DEPENDENCIES := $(BUILD_REQUIREMENTS) $(SRC_FILES) $(DOCKERFILE)

clean-app:
	@echo "[$@] :: cleaning build app intermediate files:"
	@for file_to_delete in $(VIRTUAL_ENV) \
			$(TESTS_REQUIREMENTS) \
			$(BUILD_REVISION) \
			.coverage \
			.pytest_cache; do \
		echo -e "\t$${file_to_delete}"; \
		rm -rf "$${file_to_delete}"; \
	done
	@echo "[$@] :: cleaning build app intermediate files DONE."

# -- target triggering the build of a Cloud Run docker image
build-app: $(BUILD_REVISION)
$(BUILD_REVISION): $(GCR_DEPENDENCIES)
	@echo "[$@] :: Building the GCR image for module $(MODULE_NAME)"
	@set -euo pipefail; \
		docker build \
			--platform linux/amd64 \
			--tag gcr.io/$(PROJECT)/$(MODULE_NAME):latest \
			--build-arg PROJECT=$(PROJECT) \
			--build-arg PROJECT_ENV=$(PROJECT_ENV) \
			--build-arg PYTHON_LIB_INDEX_URL=$(PYTHON_LIB_INDEX_URL) \
			--iidfile $(BUILD_REVISION) \
			.
	@echo "[$@] :: Building DONE."

scan-app: $(BUILD_REVISION)
	@echo "[$@] :: container vulnerability scanning"
	@set -euo pipefail; \
	SCAN_ID=$$( \
		gcloud beta artifacts docker \
			images scan gcr.io/$(PROJECT)/$(MODULE_NAME):latest \
			--location=europe --format='value(response.scan)' \
		); \
	echo "[$@] :: security count"; \
	gcloud beta artifacts docker images \
		list-vulnerabilities $${SCAN_ID} \
		--location=europe \
		--format='value(vulnerability.effectiveSeverity)' \
		| sort |  uniq -c ; \
	echo "[$@] :: security check"; \
	gcloud beta artifacts docker images \
		list-vulnerabilities $${SCAN_ID} \
		--location=europe \
		--format='value(vulnerability.effectiveSeverity)' | \
		if grep -Fxq CRITICAL; \
		then \
			echo 'Vulnerability check FAILED !' && exit 1; \
		else \
			echo "Vulnerability check SUCCEEDED !"; \
		fi;
	@echo "[$@] :: GCR image for module $(MODULE_NAME) built."


else ifeq ($(TYPE), gcf)

BUILD_REVISION   := revision

GCF_DEPENDENCIES := $(BUILD_REQUIREMENTS) $(SRC_FILES)
GCF_DIST         := dist
GCF_ARCHIVE      := /tmp/$(GCF_DIST)_$(MODULE_NAME).zip

GCF_DIST_FILES   = $(shell find $(GCF_DIST) -type f 2>/dev/null)

PYTHON_LIB_VERSION_REGEX := $(PYTHON_LIB_NAME)([~<=>][^\#]+)?

clean-app:
	@echo "[$@] :: Cleaning GCF archive"
	@rm -rf $(BUILD_REVISION) $(GCF_DIST) $(GCF_ARCHIVE);

# -- target building the GCF distributions whenever changes occur on source files
build-app: $(BUILD_REVISION)
	@echo "[$@] :: Ready to deploy module $(MODULE_NAME)";

# whenever the distributions or archive are altered or missing, re-build from scratch
$(GCF_DIST) $(GCF_DIST_FILES): $(GCF_DEPENDENCIES)
$(GCF_ARCHIVE): $(GCF_DIST) $(GCF_DIST_FILES)

$(BUILD_REVISION): $(GCF_ARCHIVE) $(GCF_DIST) $(GCF_DIST_FILES) $(GCF_DEPENDENCIES)
# Prepare distributions
	@echo "[$@] :: building GCF distributions in $(GCF_DIST)/"
	@rm -rf $(GCF_DIST); mkdir $(GCF_DIST);
## Add source files
	@cd $(PYTHON_SRC); \
		tar -cf - $(SRC_FILES:$(PYTHON_SRC)/%=%) | (cd ../$(GCF_DIST)/; tar -xf -);
## Add requirements. If python lib is not mentionned, copy as-is.
## Else, download its wheel and substitute its entry in requirements.
	@set -euo pipefail; \
		PYTHON_LIB=$$( \
			cat $(BUILD_REQUIREMENTS) | grep -oE --max-count 1 "$(PYTHON_LIB_VERSION_REGEX)" | xargs \
			|| echo -n "" \
		); \
		if [ -z "$$PYTHON_LIB" ]; then \
			cp $(BUILD_REQUIREMENTS) $(GCF_DIST)/requirements.txt; \
			exit 0; \
		fi; \
		\
		echo "[$@] :: downloading wheel for '$$PYTHON_LIB' and substituting it in requirements"; \
		cd $(GCF_DIST); \
		pip download "$$PYTHON_LIB" --no-deps --index-url $(PYTHON_LIB_INDEX_URL); \
		PYTHON_LIB_WHEEL=$$( \
			ls -1 $(PYTHON_LIB_NAME)*.whl | head -1 \
		); \
		cd -; \
		cat $(BUILD_REQUIREMENTS) | sed -E "s/$$PYTHON_LIB/.\/$$PYTHON_LIB_WHEEL/" \
			> $(GCF_DIST)/requirements.txt;
# Build archive
	@echo "[$@] :: building GCF archive at $(GCF_ARCHIVE)"; \
		rm -rf $(GCF_ARCHIVE); \
		cd $(GCF_DIST) && zip -r $(GCF_ARCHIVE) ./*;
# Compute revision
	@find $(GCF_DIST) -type f -exec cat {} \; \
		| md5sum | cut -d ' ' -f 1 \
		> $(BUILD_REVISION);
	@echo "[$@] :: building DONE."

scan-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

else

clean-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

build-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

scan-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

endif # definition of: clean-app, build-app, scan-app


build: test build-app


# ---------------------------------------------------------------------------------------- #
# -- < Local Testing > --
# ---------------------------------------------------------------------------------------- #

define HERE_BASE_TEST_ENV
export APP_NAME=$(APP_NAME)
export APP_NAME_SHORT=$(APP_NAME_SHORT)
export MODULE_NAME=$(MODULE_NAME)
export MODULE_NAME_SHORT=$(MODULE_NAME_SHORT)
export PROJECT=$(PROJECT)
export PROJECT_ENV=$(PROJECT_ENV)
export PROJECT_NUMBER=$(shell \
	gcloud projects describe $(PROJECT) --format=json | jq -r '.projectNumber // ""' \
)
export CLOUDRUN_URL_SUFFIX=$(shell \
	gsutil cat gs://$(DEPLOY_BUCKET)/cloudrun-url-suffix/$(REGION) \
)
endef
export HERE_BASE_TEST_ENV

ifeq ($(TYPE), gcr)
LOCAL_TEST_GCR ?= gunicorn -b :8080 -t 900 -w 3 --reload main:app
RUN_PORT       ?= 8080

# -- target to locally run a GCR application from its docker container
local-test:
	@echo "[$@] :: Running the local GCR $(MODULE_NAME)";
	@sed 's/^export //' <<< "$$HERE_BASE_TEST_ENV" > /tmp/env_$(PROJECT);
	@if [ -f $(TEST_ENV) ]; then \
			sed 's/^export //' $(TEST_ENV) >> /tmp/env_$(PROJECT); \
		fi;
	@if [ -f creds.json ]; then \
			echo 'GOOGLE_CLOUD_PROJECT=$(PROJECT)' >> /tmp/env_$(PROJECT); \
			echo 'GOOGLE_APPLICATION_CREDENTIALS=/creds/creds.json' >> /tmp/env_$(PROJECT); \
		fi;
	@docker run -it \
		-v $(shell pwd):/creds \
		-v $(shell pwd)/$(PYTHON_SRC):/app \
		-e DB_HOST=$(SANDBOX_DB_HOST) \
		-e GUNICORN_DEBUG=1 \
		--env-file /tmp/env_$(PROJECT) \
		-p $(RUN_PORT):8080 \
		-t gcr.io/$(PROJECT)/$(MODULE_NAME):latest \
		$(LOCAL_TEST_GCR)

else ifeq ($(TYPE), gcf)
GCF_PORT ?= 8080
GCF_SRC  ?= $(PYTHON_SRC)/main.py
GCF_NAME ?= main

# -- target to locally run a cloud function using the functions_framework
local-test:
	@echo "[$@] :: running the local GCF $(MODULE_NAME)"
	@functions_framework --source=$(GCF_SRC) --target=$(GCF_NAME) --port=$(GCF_PORT)

else

local-test:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

endif # definition of: local-test


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT  = iac/.terraform/terraform.tfstate
TF_VARS  = iac/terraform.tfvars
TF_PLAN  = iac/tfplan
TF_STATE = $(wildcard iac/*.tfstate iac/.terraform/*.tfstate)
TF_FILES = $(shell [ -d iac ] && find ./iac -type f -name "*.tf")


# -- internal definition for easing changes

define HERE_TF_VARS
app_name          = "$(APP_NAME)"
app_name_short    = "$(APP_NAME_SHORT)"
module_name       = "$(MODULE_NAME)"
module_name_short = "$(MODULE_NAME_SHORT)"
project           = "$(PROJECT)"
project_env       = "$(PROJECT_ENV)"
deploy_bucket     = "$(DEPLOY_BUCKET)"
env_file          = "$(ENV_FILE)"
endef
export HERE_TF_VARS


# -- this target will initialize the terraform initialization
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
				-backend-config=prefix=terraform-state/$(MODULE_NAME) \
				-input=false; \
		else \
			echo "[iac-init] :: terraform already initialized"; \
		fi; \
	fi;


# -- this target will create the terraform.tfvars file
iac-prepare: $(TF_VARS) # provided for convenience
$(TF_VARS): $(BUILD_REVISION) $(TF_INIT)
	@if [ -d iac ]; then \
		echo "[iac-prepare] :: generation of $(TF_VARS) file"; \
		echo "$$HERE_TF_VARS" > $(TF_VARS); \
		case "$(TYPE)" in \
			"gcr") \
				echo 'revision = "$(shell \
						gcloud container images list-tags gcr.io/$(PROJECT)/$(MODULE_NAME) \
						--quiet --filter tags=latest --format="get(digest)" \
					)"' >> $(TF_VARS); \
				echo 'cloudrun_url_suffix = "$(shell \
						gsutil cat gs://$(DEPLOY_BUCKET)/cloudrun-url-suffix/$(REGION) \
					)"' >> $(TF_VARS); \
				;; \
			"gcf" | "gae") \
				echo 'revision = "$(shell \
						gsutil -m cat gs://$(DEPLOY_BUCKET)/terraform-state/$(MODULE_NAME)/gcf-src-hash \
					)"' >> $(TF_VARS); \
				echo 'cloudrun_url_suffix = "$(shell \
						gsutil cat gs://$(DEPLOY_BUCKET)/cloudrun-url-suffix/$(REGION) \
					)"' >> $(TF_VARS); \
				;; \
		esac; \
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
		echo "[iac-plan] :: planning the iac for module $(MODULE_NAME)"; \
		cd iac && terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN)); \
		echo "[iac-plan] :: planning the iac for module $(MODULE_NAME) DONE."; \
	else \
		echo "[iac-plan] :: no infrastructure"; \
	fi;


# -- this target will only trigger the iac of the designated module
iac-deploy: iac-clean $(TF_PLAN)
	@echo "[$@] :: applying iac for module $(MODULE_NAME)"
	@if [ -d iac ]; then \
		cd iac; \
		terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN)); \
	else \
		echo "[$@] :: no infrastructure"; \
	fi;
	@echo "[$@] :: is finished on module $(MODULE_NAME)"

# -- this target will clean the intermediary iac files
# might need to delete the iac/.terraform/terraform.tfstate file
iac-clean:
	@echo "[$@] :: cleaning IaC intermediary files : '$(TF_PLAN), $(TF_VARS)'"
	@if [ -d iac ]; then \
		rm -fr $(TF_PLAN) $(TF_VARS); \
		if [ ! -f iac/.iac-env ] || [ $$(cat iac/.iac-env || echo -n) != $(PROJECT_ENV) ]; then \
			echo "[$@] :: ENV has changed. Removing iac/.terraform* to reinit terraform"; \
			rm -rf iac/.terraform iac/.terraform.lock.hcl; \
		fi; \
	fi;
	@echo "[$@] :: cleaning IaC intermediary files DONE."


# ---------------------------------------------------------------------------------------- #
# -- < Pause schedulers in sbx > --
# ---------------------------------------------------------------------------------------- #
ifeq ($(IS_SANDBOX), true)
pause-schedulers:
	@echo "[$@] :: Pause all schedulers of sandbox."
	@gcloud scheduler jobs list --project $(PROJECT) --format="value(ID)" |\
		while read job;\
		do \
			echo "pausing: $$job"; \
			gcloud scheduler jobs pause --project $(PROJECT) --location europe-west1 $$job; \
		done
	@echo "[$@] :: All schedulers are paused."
else
pause-schedulers:
	@echo "[$@] :: Nothing to do since the project is not a sandbox."
endif


# ---------------------------------------------------------------------------------------- #
# -- < Deploying > --
# ---------------------------------------------------------------------------------------- #
ifeq ($(TYPE), gcr)
deploy-app:
	@echo "[$@] :: Pushing docker image for module $(MODULE_NAME)"
	@docker push gcr.io/$(PROJECT)/$(MODULE_NAME):latest;
	@echo "[$@] :: Push of docker image DONE."

.PHONY: deploy-apigee
# When ready, use --fail-with-body instead of -s, -output and --write-out.in last curl request.
# Not available in the current Ubuntu 2020.04 version (7.68)
deploy-apigee:
	@set -euo pipefail; \
	if ! [[ -f $(API_CONF_FILE) && $(ENV) =~ ^(dv|qa|np|pd)$$ ]]; then \
		echo "[$@] :: Nothing to do"; \
		exit 0; \
	fi; \
	if ! (jq -e '.versions' $(API_CONF_FILE) >/dev/null); then \
		echo "[$@] :: ERROR. No versions declared in $(API_CONF_FILE)"; \
		exit 0; \
	fi; \
	API_VERSIONS=$$(jq -rc .versions                   $(API_CONF_FILE)); \
	IS_FRONT_PROJECT=$$(jq -r .is_front_project        $(API_CONF_FILE)); \
	API_CONF=$$(jq 'del(.is_front_project, .versions)' $(API_CONF_FILE)); \
	\
	echo "[$@] :: Retrieving target info and credentials"; \
	TARGET_PROJECT=$$( \
		[ $$IS_FRONT_PROJECT = true ] && echo $(FRONT_PROJECT) || echo $(PROJECT) \
	); \
	TARGET="$$( \
		gcloud run services describe \
			$(APP_NAME_SHORT)-gcr-$(MODULE_NAME_SHORT)-$(REGION_ID)-$(PROJECT_ENV) \
			--project $${TARGET_PROJECT} \
			--region=$(REGION) \
			--format='value(status.address.url)' \
	)"; \
	PAYLOAD=$$( \
		jq -rc '.target = "'$$TARGET'" | .environment = "$(PROJECT_ENV)"' <<< "$$API_CONF" \
	); \
	TOKEN=$$( \
		curl -s -f -X POST "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/$(APIGEE_DEPLOY_SA):generateIdToken" \
			--header 'Content-Type: application/json' \
			--header "Authorization: Bearer $$(gcloud auth print-access-token)" \
			--data '{"audience": "'$$TARGET'"}' \
		| jq -r '.token' \
	); \
	\
	echo "[$@] :: Deploying API version(s) to Apigee: $$API_VERSIONS"; \
	n=$$(jq 'length' <<< "$$API_VERSIONS"); \
	i=1; \
	for version in $$(jq -rc '.[]' <<< "$$API_VERSIONS"); do \
		API_NAME=$$(jq -r .api_name         <<< "$$API_CONF")-$$version; \
		API_BASEPATH=$$(jq -r .api_basepath <<< "$$API_CONF")/$$version; \
		TARGET_BASEPATH=/$$version; \
		\
		echo "[$@] :: ($$i/$$n) Deploying proxy to Apigee: $$API_NAME"; \
		echo "[$@] :: Retrieving swagger in base64"; \
		APIGEE_PAYLOAD_FILE=$${API_NAME}_$(APIGEE_PAYLOAD); \
		curl -s -f "$${TARGET}$${TARGET_BASEPATH}/swagger.json" \
			--header "Authorization: Bearer $$TOKEN" \
			| base64 | xargs | sed "s/ //g" \
			| jq -R "$$PAYLOAD"' + { "base64_swagger": . }' \
			| jq '.api_name="'$$API_NAME'" | .api_basepath="'$$API_BASEPATH'" | .target_basepath="'$$TARGET_BASEPATH'"' \
			> $$APIGEE_PAYLOAD_FILE; \
		\
		echo "[$@] :: Sending the deploy request"; \
		response_payload_file=$${API_NAME}_$(APIGEE_RESPONSE_PAYLOAD); \
		http_code=$$( \
			curl -s -X POST $(APIGEE_DEPLOYER_ENDPOINT)/publish \
			--header "Authorization: Bearer $$(gcloud auth print-access-token)" \
			--header "Content-Type: application/json" \
			--data @$$APIGEE_PAYLOAD_FILE \
			--raw --output $$response_payload_file \
			--write-out "%{http_code}"; \
		); \
		cat $$response_payload_file | jq 2>/dev/null || (cat $$response_payload_file && echo ""); \
		if [[ $$http_code != 200 ]]; then \
			echo "[$@] :: ERROR. $$http_code - Failed to deploy proxy: $$API_NAME"; \
		else \
			echo "[$@] :: SUCCESS. Proxy deployed to Apigee: $$API_NAME"; \
			rm $$APIGEE_PAYLOAD_FILE $$response_payload_file; \
		fi; \
		i=$$((i+1)) && echo ""; \
	done; \
	echo "[$@] :: API version(s) deployed to Apigee. DONE.";

else ifeq ($(TYPE), gcf)

# -- target pushing the GCF archive to the dedicated location in the deployment bucket
deploy-app:
	@echo "[$@] :: Pushing GCF distributions for module $(MODULE_NAME)"
	@gsutil cp -v $(GCF_ARCHIVE)     gs://$(DEPLOY_BUCKET)/terraform-state/$(MODULE_NAME)/gcf-src_$$(cat $(BUILD_REVISION)).zip; \
	 gsutil cp -v $(BUILD_REVISION)  gs://$(DEPLOY_BUCKET)/terraform-state/$(MODULE_NAME)/gcf-src-hash;
	@echo "[$@] :: push of distributions DONE."

deploy-apigee:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

else

deploy-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

deploy-apigee:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

endif  # definition of: deploy-app, deploy-apigee


deploy: deploy-app iac-plan-clean iac-deploy deploy-apigee pause-schedulers


# ---------------------------------------------------------------------------------------- #
# -- < Cloudbuild activation > --
# ---------------------------------------------------------------------------------------- #

# -- cloudbuild authorized targets
GCB_TARGETS       := all test build deploy iac-plan iac-deploy deploy-apigee e2e-test
GCB_TEMPLATES_DIR := $(ROOT_DIR)/.gcb/module

# -- includes the gcb makefile after the mandatory variables definition
include $(ROOT_DIR)/includes/cloudbuild.mk
