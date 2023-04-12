# README - Setup Access

## Purpose

This module allows to grant roles on project to external members. Roles can be either granted globally at project level,
or more accurately at resource level (preferred).

Related configurations are located in _resources/roles_. Templating is used to replace common variables like
`${app_name_short}`, `${project_env}` and `${project}` based on active environment.

## Content

```
.
├── resources/                       Contains the YAML configuration templates for external access.
│   ├── external_access.yaml.sample    Contains a full example to provide external access on project at each level.
│   ├── external_access.yaml           Contains per default needed roles for flows actions on project. To complete.
│   ├── ...                            Other YAML configurations added for project. Files are searched recursively and merged.
│   └── variables.json                 Contains the user-defined template variables.
├── Makefile                         Contains the make targets to test and deploy this module.
├── README.md                        This README.
├── locals.tf                        Contains the local terraform variables.
├── outputs.tf                       Contains the terraform outputs to provide feedbacks after deployment.
├── provider.tf                      Contains the terraform code to initialize the provider and default project.
├── roles.tf                         Contains the terraform code to authorized members with the roles provided in YAML configurations.
└── variables.tf                     Contains the terraform variables injected by Makefile.
```

## Usage

The access management can be defined through the use of a `Makefile`. To determine the current variables and get
acquainted with all available targets, the Makefile help can be displayed with the following command:

```shell
ENV=sbx make
```

It can be deployed with the following command:

```shell
ENV=sbx make iac-deploy
```

But, before running the deploy target, it is advised to:

- run the target `iac-clean` every time you change the value of `ENV` variable so that it cleans the previously
  generated `terraform.tfvars`

- run the target `iac-plan` to visualize the changes you are about to make (if any)

## How to enhance

### Configurations

More configurations can be added within _resources/_. YAML files will be search recursively and merged together to
support subfolders and user-defined file names.<br/>However, this means that if a member is referenced several times,
only the last found configuration will be taken into account to provide access.

Provided emails of members must include their types as prefix. For instance, `group:<GROUP_ID>@loreal.com` or
`serviceAccount:<SA_ID>@<SA_PROJECT>.iam.gserviceaccount.com`

A complete [example](resources/roles/external_access.yaml.sample) of the different levels at which roles can be given
with current implementation can be found alongside default configuration for _configinterface_.

### Templating

Templating can be extended by defining some additional variables within `variables.json`. They can rely on usual local
variables from active environment like `${project}`, `${project_env}`, `${app_name_short}` and others.
