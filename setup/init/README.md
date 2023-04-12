# README — Init

## Purpose

This README aims to describe the Init setup for the current project and the current repository.

The Init enable the main APIs and permissions in order to make the current project usable. It will also ensure the creation of the main service accounts required for services to be fully working.

## Configuration of init.

The init configuration consists mostly in listing the enabled APIs. In this purpose the apis.txt file can be modified adding an API and then init the project again to ensure the enabling of the API.

## Directory structure

This directory is a Terraform module that manages the CICD for the repository.
```
.
├── Makefile                              Makefile contains a target to initialize the project infrastructure with terraform.
├── api.tf                                Contains the terraform code to enable APIs.
├── apis.txt                              Contains the list of APIs (one per line) to enable. Feel free to change according to project needs.
├── cloudbuild.yaml                       Contains the step to generate the cloud run suffix for this project and store in the deploy bucket.
├── gae.tf                                Contains the terraform code to enable Google App Engine in the configured location of the environment files.
├── locals.tf                             Contains the local terraform variables.
├── provider.tf                           Contains the terraform code to initialize the provider and default project.
├── roles.tf                              Contains the terraform code to setup the main permissions on the project.
├── storage.tf                            Contains the terraform code to activate the storage service account and main permissions
└── variables.tf                          Contains the Makefile injected terraform variables.
```

## Usage of Makefile

* Makefile: contains a target to initialize the project infrastructure.

In the current setup/init folder, just run:
```shell
make all
```

You can also trigger the init from the top root folder of the project by doing:
```shell
make init
```
