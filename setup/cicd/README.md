# README — CICD

## Purpose

This README aims to describe the CICD setup for the repository.


## What is CI CD

CICD (Continous Integration Continuous Development) is a method to automate the stages of software development.
These stages are 'build', 'test' and 'deploy'.
The main goal is to automate the deployment of the code pushed in the repository be any Data engineers; in each environment from the Quality Acceptance (QA), then Pre-Production (NP), and finally to Production (pd).
The technologies used are Google Cloud Build (GCB), Terraform and Makefile.


#### Google Cloud Build

GCB is a Google Cloud Platform (GCP) service, that executes builds (triggers) on GCP infrastructure. It's triggered by the GitHub repositories using a native plugin to link GitHub with GCB.
The configuration of the builds depend on an inline configuration defined in each triggers and defined in the current dedicated Terraform configuration.

#### Terraform

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers, in our very use case, the provider is Google Cloud Platform.
The infrastructure is defined as a code, the IaC (Infrastructure as code). The programming language is HCL (HashiCorp Configuration Language).
Terraform is used to generate the GCP triggers in every environements.


#### Make

Make is a build automation tool, for software development purposes. It allows the execution of tasks from source code, by reading files called ```Makefiles```.
Targets are the steps of the building process, they are defined in the Makefile files, telling Make how to execute each of them, and in which specific order.

## Requirements

In order the initialization of project to work some manual steps have to be followed before running this tool.

#### Cloud Build enabler

Go to the following page: https://console.cloud.google.com/cloud-build/settings/service-account
Enable toe Cloud Build for all services to ensure a proper installation and run of cloud build.

#### Cloud Source Repository link

Go to the following page: https://console.cloud.google.com/cloud-build/triggers
Ensure the repository of the project is connected to the project. It MUST be done for
every project (every environments) where the CICD must be deployed.

## Directory structure

This directory is a Terraform module that manages the CICD for the repository.

```
.
├── Makefile                              Makefile contains a target to create the trigger that manage the CICD.
├── README.md                             Contains the documentation about the CICD tool chain setup.
├── locals.tf                             Contains the local terraform variables.
├── md5.tf                                Contains the terraform code to create and inject the MD5 file to control the safety of the Makefile in the CICD toolchain.
├── projects.tf                           Contains the terraform code to load data from every project participating to the CICD toolchain.
├── provider.tf                           Contains the terraform code to initialize the provider and default project.
├── roles.tf                              Contains the terraform code to setup the main permissions on the project.
├── triggers.tf                           Contains the terraform code to create the triggers according to the configuration.
└── variables.tf                          Contains the Makefile injected terraform variables.
```


## CICD Workflow

action in GitHub | actions in Cloudbuild
-----------------|----------------------
__Pull Request from feature branch to *develop*__ | starts builds to performs tasks such as Static Analysis and Unit tests.
__Merge feature branch to *develop*__ | starts builds to performs tasks into the *qa* environment (use case and/or btdp). If successful, starts builds into the *np* environments.
__Merge *develop* to *master*__ | starts builds to perform tasks into the *pd* environment.

> nota: for testing purpose, there are also triggers for the `dv` environment. They can be invoked manually from the Cloud Build console by clicking the RUN button.

> nota: The merge on develop branch triggers the QA and if everything works fine, it will by default also triggers the NP builds.

## CICD IAM policy

Tasks in CloudBuild are executed by the CloudBuild Service Account.
In order to perform those tasks, IAM roles must be granted to the Service Account.

The list of roles is set in the ```locals.tf``` file.

> warning: only management and Lead developers can accept added roles.

## Modify the CICD setup

The CICD setup is managed by terraform and the configuration in terraform. The configuration can be overridden by the cicd.json environments file.
The cicd.json environments file can contains the following variables:
* zone: The GCP zone (https://cloud.google.com/compute/docs/regions-zones). Default is europe-west1-b.
* region: The GCP region (https://cloud.google.com/compute/docs/regions-zones). The Default is calculated from the previous zone.
* multiregion: The GCP multi region. It can be "eu" or "us". It's calculated from the previous region.
* triggers_env: The trigger environment configuration. It's a map of the environment and the trigger configuration for each one. A trigger configuration is defined by the name of the branch the triggers occurs and the two options "disabled" (if set to true, the triggers can only be triggered manually) and "next" (if set to something the branch in the "next" option will be triggered automatically at the end of the current CI/CD. The pr option indicates if a trigger is to be created for pull requests targetting this environment and branch.

The default configuration look like this:
```
{
    "zone": "europe-west1-b",
    "region": "europe-west1",
    "multiregion": "eu",
    "triggers_env": {
        "dv": {
            "branch": "develop",
            "disabled": true,
            "next": null
        },
        "qa": {
            "branch": "develop",
            "disabled": false,
            "next": "np",
            "pr": true
        },
        "np": {
            "branch": "preprod",
            "disabled": true,
            "next": null
        },
        "pd": {
            "branch": "master",
            "disabled": false,
            "next": null,
            "pr": true
        }
    }
}
```

Each trigger is created on the project corresponding to env. So it's expected the environements declared exist. By default, it's expected the dv.json, qa.json, np.json, pd.json are existing in the environments configuration folder with at least the project set. This project will be used to create all the specified triggers.

## Usage of Makefile

* Makefile: contains a target to create the main trigger.

In the current setup/cicd folder, just run:

```shell
make all
```

You can also trigger the cicd from the top root folder of the project by doing:
```shell
make cicd
```
