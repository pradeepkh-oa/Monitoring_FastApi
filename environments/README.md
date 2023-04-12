
# README — `Environments`

## Purpose

This README file aims to describe the content of the `environments` directory.

## Directory structure

This directory contains configurations files for the cicd and environment configuration
files for normalized environments and sandboxes.

The existing files are templates that need to be instantiated.

```
.
├── instantiate-template.sh Script to generate effective files *.json performing substitutions
├── apis.json               Contains the base_url_path of btdp APIs through apigee.
├── cicd.json.template      Contains the configuration for the cicd.
├── dv.json.template        Contains the environment variables for the `dv` environment.
├── np.json.template        Contains the environment variables for the `np` environment.
├── pd.json.template        Contains the environment variables for the `pd` environment.
├── qa.json.template        Contains the environment variables for the `qa` environment.
└── sbx.json.template       Contains the environment variables for a sandbox environment.
```

Hereafter is an example of how to generate real instance of the files.

```bash
❯ ./instantiate-template.sh
please enter project name: itg-btdpslt-gbl-ww
please enter app name: btdpslt

entered values are:
- project_name: itg-btdpslt-gbl-ww
- app_name: btdpslt

generating json configuration files...
generation of json configuration files is over.
```

As a result, the `*.json` counterpart will be generated, except for sbx.json.template, with
the provided values for both the `project name` and the `app_name_short`.

> **Nota Bene**:
> the project name is the name of the project **without** the suffix of the environment.




## JSON environment configuration files

Environment configuration files allows the definition of environments variables in different files.
Makefiles will use the file which name matches the `ENV` variable value.
Thus, for `ENV=dv` the file `environments/dv.json` will be used, and so on.

Notice, that some Makefile might refuse the value if it incoherent regarding the context.
For instance, using `ENV=cicd` in folder `seup/init` is illegal.

 ```shell
 ENV=dv make all
 ```

Convention is defined for sandbox configuration file to be `sbx.json`. So the file name directly
states its purpose.

Usage will then be
```shell
ENV=sbx make <target>
```


### A. CICD configuration file

Check the CICD [README](../setup/cicd/README.md#modify-the-cicd-setup) to know how to modify the CICD configuration.


| Key                     | Value         | Description                                                                   |
| ----------------------- | ------------- | ----------------------------------------------------------------------------- |
| "owner"                 | **Mandatory** | The organization of the github project.                                       |
| "repository_name"       | **Mandatory** | The name of the repository of the github project.                             |
| "deploy_bucket"         | **Mandatory** | The name of the bucket where is stored the terraform state of the cicd.       |
| "generic_build_version" | **Mandatory** | The tag of the generic build image. It matches the terraform version          |
| "builders_project"      | **Optional**  | The project of the generic build image.                                       |
| "project"               | **Optional**  | The project where to deploy the cicd. Defaults to `pd` env.                   |
| "integration_project"   | **Optional**  | The project where integration tests are runned. Defaults to `qa` env.         |
| "integration_bucket"    | **Optional**  | The name of the bucket where triggers are orchestrated for integration tests. |


### B. Sandbox environment configuration file

For the sandbox environment you must create a `${SANDBOX_ENV}.json` file.

| Key                  | Value         | Description                                                           |
| -------------------- | ------------- | --------------------------------------------------------------------- |
| "trigram"            | **Mandatory** | Three letters to uniquely identify yourself. Eg., `John Doe` -> `jdo` |
| "sandbox_project_id" | **Mandatory** | The id of your sandbox project in GCP.                                |


### C. Normalized environments configuration files

For the normalized environments `dv`, `qa`, `np`, `pd`, `.json` template files are provided.
You must replace the values or delete the optionnal keys according to the table below.

For any normalized environment, the content of the `.json` environment files can be as minimal as:

```json
{
    "project_env": "<env>",
    "project": "<project>"
}
```

You can also override default values by specifying the following information:

```json
{
    "project_env": "<env>",
    "project": "<project>",
    "zone": "<zone>",
    "zone_id": "<zone_id>",
    "region": "<region>",
    "region_id": "<region_id>",
    "multiregion": "<multiregion>",
}
```

with:

| Key                    | Value         | Default value                               | Description                                                                          |
|--------------------------------|---------------|---------------------------------------------|--------------------------------------------------------------------------------------|
| "project"              | **Mandatory** | none                                        | the project name   |
| "project_env"          | **Optional**  | _file_name_ (without the `.json` extension) | the environment (`dv`, `qa`, `np`, `pd`) or the sandbox environment (e.g `abc`)      |
| "btdpback_project"     | **Optional**  | "itg-btdpback-gbl-ww-<project_env>" |  the back project of the btdp |
| "btdpfront_project"    | **Optional**  | "itg-btdpfront-gbl-ww-<project_env>"       |  the front project of the btdp |
| "zone"                 | **Optional**  | `europe-west1-b`                            | the zone, e.g. `europe-west1-b`   |
| "zone_id"              | **Optional**  | _computed from "zone"_                      | the zone identifier, e.g. `ew1b`  |
| "region"               | **Optional**  | _computed from "zone"_                      | the region, e.g. `europe-west1`   |
| "region_id"            | **Optional**  | _computed from "zone_id"_                   | the region identifier, e.g. `ew1` |
| "multiregion"          | **Optional**  | _computed from "zone"_                      | the multiregion, e.g. `us` or `eu`|

> **Note**:
> Optional keys can be omitted. However, you must ensure that it is handled properly in
> the Terraform configuration using for example `lookup` with a default value.
