# ======================================================================================== #
#           ___             _   _               __  __      _        __ _ _
#          | __|  _ _ _  __| |_(_)___ _ _  ___ |  \/  |__ _| |_____ / _(_) |___
#          | _| || | ' \/ _|  _| / _ \ ' \(_-< | |\/| / _` | / / -_)  _| | / -_)
#          |_| \_,_|_||_\__|\__|_\___/_||_/__/ |_|  |_\__,_|_\_\___|_| |_|_\___|
#
# ======================================================================================== #

# ---------------------------------------------------------------------------------------- #
# -- Description --
#
# This functions aims to execute a SQL file on the cloud SQL database using
# the sql runner module.
#
# Parameters:
#  in:
#   $(1) : the file to execute through sql runner
#   $(2) : project on which the sql runner module is deployed
#   $(3) : the folder in the bucket where to copy the files
#   $(4) : the file outputting the resulting payload of the call
#
# Example:
#    $(call execute_sql_file,sample.sql,itg-btdpback-gbl-ww-dv,sql,output.json)
#
# ---------------------------------------------------------------------------------------

define execute_sql_file
	sql_file=$(1); \
	if ! [ -f $${sql_file} ]; then \
		echo "no file provided"; \
		exit 1; \
	fi; \
	gsutil -m cp $${sql_file} gs://$(DEPLOY_BUCKET)/$(3)/; \
	sql_file=$$(basename $(1)); \
	unset GOOGLE_APPLICATION_CREDENTIALS; \
	TOKEN=$$(\
		gcloud auth print-identity-token \
			--impersonate-service-account=btdp-sa-sqlrunner-$(PROJECT_ENV)@$(2).iam.gserviceaccount.com \
		); \
	URI=$$(\
		gcloud run services \
			describe btdp-gcr-sqlrunner-$(REGION_ID)-$(PROJECT_ENV) \
			--project=$(2) \
			--region=$(REGION) \
			--platform=managed \
			--format=json \
			--format="value(status.url)" \
		)/v1/sql; \
	RES=$$(\
		curl -s -X POST \
			-H "Content-Type: application/json" \
			-H "Authorization: Bearer $${TOKEN}" \
			"$${URI}" \
			-d '{"sql": "gs://$(DEPLOY_BUCKET)/$(3)/'$${sql_file}'"}' \
			-w "%{http_code}\n" \
			-o $(4) \
	); \
	echo "HTTP $${RES}"; \
	if (( $${RES} != 200 )); then \
		curl -s -X POST \
			-H "Content-Type: application/json" \
			-H "Authorization: Bearer $${TOKEN}" \
			"$${URI}" \
			-d '{"sql": "gs://$(DEPLOY_BUCKET)/$(3)/'$${sql_file}'"}'; \
		echo "[$@] :: An error occurred while executing the SQL queries using SQL Runner"; \
		exit 1; \
	fi;
endef


# ---------------------------------------------------------------------------------------- #
# -- Description --
#
# This functions aims to push dags in the composer environment. It proceeds by performing
# the following steps:
#   1. execute the SQL dag config file identified by variable DAG_SQL_CONFIG with
#      module SQL Runner
#   2. extract the JSON configuration from the result payload
#   3. retrieve composer bucket name
#   4. copy the configuration to the bucket
#
# Parameters:
#  in:
#   $(1) : the file to execute through sql runner
#   $(2) : project on which the sql runner module is deployed
#   $(3) : the file outputting the resulting payload of the call
#   $(4) : the name of the file to output the result of the query execution
#
# Example:
#    $(call push_dags,dag_config.sql,itg-btdpback-gbl-ww-dv,output.json,dags_config.json)
#
# ---------------------------------------------------------------------------------------

define push_dags
	dag_sql_config=$(1); \
	back_project=$(2); \
	dag_json_output=$(3); \
	dag_json_config=$(4); \
	$(call execute_sql_file,$${dag_sql_config},$${back_project},dags,$${dag_json_output}) \
	jq -r '.results[0].config' $${dag_json_output} > $${dag_json_config}; \
	DAG_GCS_PREFIX=$$(\
		gcloud composer environments \
			describe btdp-composer-main-$(REGION_ID)-$(PROJECT_ENV) \
			--project $${back_project} \
			--location $(REGION) \
			--format=json \
			| jq -r .config.dagGcsPrefix \
		); \
	echo "[$@] :: ready to copy dag config to $${DAG_GCS_PREFIX}"; \
	gsutil cp $${dag_json_config} $${DAG_GCS_PREFIX}; \
	rm -f $(dag_json_config) $(dag_json_output);
endef
