# ======================================================================================== #
#     ___ _             _ _         _ _    _   __  __      _        __ _ _
#    / __| |___ _  _ __| | |__ _  _(_) |__| | |  \/  |__ _| |_____ / _(_) |___
#   | (__| / _ \ || / _` | '_ \ || | | / _` | | |\/| / _` | / / -_)  _| | / -_)
#    \___|_\___/\_,_\__,_|_.__/\_,_|_|_\__,_| |_|  |_\__,_|_\_\___|_| |_|_\___|
#
# ======================================================================================== #


# ---------------------------------------------------------------------------------------- #
# -- < function: generate_gcb_file > --
#
# This helper function will render a template file and put the result in the relevant directory.
# It thus creates a cloudbuild.yaml file to execute the desired target in cloudbuild.
#
# Templates files stand in the .gcb/ directory.
#
# in:
#   $1: Template prefix (example: cloudbuild-.yaml)
#   $2: The target to pass (deploy, ...)
#   $3: Module Name (exemple 00-sql-runner)
#
# out:
#   cloudbuild.yaml file in the local directory of the makefile
#
# ---------------------------------------------------------------------------------------- #
define generate_gcb_file
	full_file_path="$(GCB_TEMPLATES_DIR)/$(1).tpl"; \
	echo "generating file: $${full_file_path}"; \
	if ! [[ -f $${full_file_path} ]]; then \
		echo "file does not exist"; \
		full_file_path=$(GCB_TEMPLATES_DIR)/cloudbuild.yaml.tpl; \
	else \
		echo "file exists"; \
	fi; \
	cat "$${full_file_path}" | \
		sed -e "s/%ENV%/$(ENV)/g" \
			-e "s/%TARGET%/$(2)/g" \
			-e "s/%MODULE_NAME%/$(3)/g" \
		> $(ROOT_DIR)/cloudbuild.yaml
endef


# -- the generic gcb target
gcb-%:
	@set -euo pipefail; \
	target=$*; \
	echo "[$@] target is : '$${target}'"; \
	if [[ "$(GCB_TARGETS)" =~ $${target} ]]; \
	then \
		echo "Target '$${target}' is allowed: running in cloudbuild"; \
		$(call generate_gcb_file,cloudbuild-$${target}.yaml,$${target},$(MODULE_RAW_NAME)); \
		gcloud builds submit $(ROOT_DIR) \
			--project=$(PROJECT) \
			--config=$(ROOT_DIR)/cloudbuild.yaml \
			--substitutions=_TARGET=$${target},_ENV=$(ENV),_PROJECT_ENV=$(PROJECT_ENV),_APP_NAME_SHORT=$(APP_NAME_SHORT); \
	else \
		echo "Target '$(*)' is not allowed in gcb: ignoring"; \
	fi \
	&& \
	rm -f $(ROOT_DIR)/cloudbuild.yaml || rm -f $(ROOT_DIR)/cloudbuild.yaml
