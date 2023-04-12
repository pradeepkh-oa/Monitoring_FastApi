# README — `configuration/configinterface`

## Purpose

This directory contains template files for **YAML** configurations through the BTDP Config Interface API.
Currently, only configurations for Flows and State-machine actions are fully supported.

But other needed configurations can be added as well in raw format, pending their integration.

## Directory structure

```
├── flows/                        Contains templates to define flows.
├── state-machine-flows-actions/  Contains templates to define State-machine actions, combining flows.
└── ...                           Other raw configuration templates (if needed)
```

An example is provided for each supported templates `.yaml.sample` to showcase available parameters.
Templates are fetch recursively to allow sub-folders if needed.

**IMPORTANT**: In the folder `flows/`, the name of the files are used for the flow_id.</br>They must match the Naming Conventions defined in Confluence,
but shall not include the project_env as suffix: it is added automatically.

## Functioning concept

Configuration template files are used to create `restapi_object` that emulate Terraform resources by calling the
BTDP Config Interface API instead through Apigee.

Any common references (app_name, ...) in the template files will be replaced by its value while it is being parsed. An
additional file `../variables.json` allows to create user-defined references to limit repetitions.

If a configuration is not supported yet, it needs to be added as raw. Then, the method types or route patterns may need
to be manually configured as well.<br/>In that case, please refer to both documentation from:

- the BTDP module `02-config-interface` module,
- and, the terraform provider [restapi](https://registry.terraform.io/providers/Mastercard/restapi/latest/docs)
  (allowing to emulate a resource with a REST API).

## Requirements

### When deployed in CI/CD triggers

To push configurations and create associated resources, one must first verify that the user-defined cloud-build service
accounts for each ENV of this project have been correctly added to the GCB group:
`IT-GLOBAL-GCP-BTDP_DATASRV_CLOUDBUILD-PD`

If other service accounts need access to the API, they must be added to a more specific group:
`IT-GLOBAL-GCP-BTDP_DATASRV_CONFIGINTERFACE-PD`

### When deployed manually (sandbox)

Currently, no configurations can be deployed on sandboxes. Tests can be done directly on `dv` environment.
