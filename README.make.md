# README — Make


## Table of Contents

* [Purpose](#purpose)
* [Composition](#composition)
* [Prerequisites](#prerequisites)
* [A. `Makefile`](#a-makefile)
  + [1. Features](#1-features)
  + [2. Usage](#2-usage)
    - [a. Building the infrastructure](#a-building-the-infrastructure)
  - [b. Deploying the infrastructure](#b-deploying-the-infrastructure)
* [B. Aliases](#e-aliases)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## Purpose

This README file aims to describe the way the Makefiles must be used within the
BTDP repository.


## Composition

The system is composed of 2 files:
* Makefile
* module.mk

Each file has a specific purpose.

## Prerequisites

Some elements are needed for the makefiles to properly operate like binaries, libraries
and so on:

* python3.10
* make
* jq
* bash
* gcloud
* terraform

among them.

## A. `Makefile`

This makefile aims to build the top infrastructure of the project (the core elements of
the project).

### 1. Features

This makefile aims to manage the building of the whole base infrastructure.
With this makefile you can perform the following actions with their respective targets.

For the core elements:

  Target        | Action
----------------|-----------------
  `iac-init`    | Initializes the terraform infrastructure
  `iac-prepare` | Prepares the terraform infrastructure by create the variable files
  `iac-plan`    | Produces the terraform plan to visualize what will be changed in the infrastructure
  `iac-deploy`  | Proceeds to the application of the terraform infrastructure
  `iac-clean`   | Cleans the intermediary terraform files to restart the process


For the platform elements:

  Target           | Action
-------------------|-----------------
  `iac-deploy-all` | Applies the complete terraform infrastructure

### 2. Usage

In this section we will illustrate how to use this makefile and its targets to achieve
particular tasks.

#### a. Building the infrastructure

To achieve this task one will need the targets named after `iac-<something>`.

* `iac-init`:
  it will initialize the terraform by creating the `.terraform` hidden directory
  and the local `terraform.tfstate` used to retrieve the mentioned target.
  Thus this file must be remove _via_ the target `iac-clean`.

#### b. Deploying the infrastructure

To achieve this task one will need the targets `deploy`.

_Usage_:
```shell
ENV=XX \
  make -f Makefile deploy
```

This target should be the one use the most often since it handle all the clean and endure a safe state of the infrastructure as code deployment.

## B. Aliases

To ease the usage of the makefiles, some useful aliases can be used for your daily work.


```shell
alias makem='make -f .Makefile'
```
