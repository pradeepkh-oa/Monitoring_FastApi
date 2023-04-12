# README - How to interact with modules


## Purpose

This document aims to give the basic information test or deploy modules from a local environment.

The detailed documentation can be found on the dedicated [Confluence page](https://confluence.e-loreal.com/display/BTDP/5.8+Build+or+deploy+with+Makefiles)


## Table of Contents

- [Resources](#resources)
- [Sample modules](#sample-modules)
- [Modules](#modules)
  - [How to test](#how-to-test)
  - [How to build and run locally](#how-to-build-and-run-locally)
  - [How to deploy](#how-to-deploy)
  - [How to interact with the deployed services](#how-to-interact-with-the-deployed-services)
  - [How to run end-to-end tests](#how-to-run-end-to-end-tests)


## Resources

To create ASCII headers for terraform files: http://patorjk.com/software/taag/#p=display&c=bash&f=Small&t=Type%20Something

To quickly validate Jinja templates: http://jinja.quantprogramming.com/

To choose configurations for schedulers: https://crontab.guru/

## Sample modules

Sample modules are modules whose name ends with `.sample`.
They can be seen as examples to help build each module type, or even templates.

Per default, they are ignored by the Makefiles CLI and the CI/CD to avoid being deployed
by mistake by a use-case (if not removed).

The simplest way to test them is to build a symlink to reference the module folder.
```bash
cd modules;
ln -s cloudfunction-v2.sample function-v2;
cd -;
```

The symlink will emulate the module folder with a new module name
that won't be ignored.
Then it can be tested as usual using the symlink name. In the example above, it will be `function-v2`.

> N.B. Beware of not committing this symlink.
> After your tests, you can remove it to avoid mistakes: `rm -i modules/function-v2;`

### Existing samples

| Sample modules   | How to                                                             |
| ---------------- | ------------------------------------------------------------------ |
| cloudfunction-v2 | deploy a Google Function v2. Relying on Cloud Run for its backend. |
| cloudfunction    | deploy a Google Function v1.                                       |
| cloudrun         | deploy a Flask-RestX API on Google Cloud Run.                      |


## Modules

### How to test

From the module directory :
  ```bash
  ENV=XX \
    make -f ../../module.mk test
  ```

**Nota**: For more information on the Makefile, please read the README.make.md.

### How to build and run locally

First you need to move to your module folder: `cd modules/MY_MODULE`

Then, you will need to follow several steps:

0. activate the module environment to ensure the function's requirements are available in your session:
  ```bash
  source .venv/bin/activate
  ```

  If not done already, You may need to run the tests to install the requirements and build `.venv`
  ```bash
  ENV=XX \
    make -f ../../module.mk test
  ```

1. build the module. This is particularly needed when it depends on a Dockerfile.
  ```bash
  ENV=XX \
    make -f ../../module.mk build-app
  ```

2. run the module locally.
  ```bash
  ENV=XX \
  make -f ../../module.mk local-test
  ```

  It will either run the server locally within a Docker container, or using a Google package
  like `functions_framework`.
  For Google Cloud Function, some environment variables can be set manually:
  ```
    GCF_PORT=8081 \
    GCF_SRC=src/main.py \
    GCF_NAME=hello
  ```

1. using another terminal, send HTTP requests to `http://localhost:$PORT/`.
  Hereafter is an example:

  ```bash
  PORT=8080;
  # using json payload
  curl \
    -H "Content-Type: application/json"
    -X POST "https://localhost:$PORT/" \
    -d '{"name": "John"}';

  # or, using url parameters
  curl \
    -H "Content-Type: application/json" \
    -X GET "https://localhost:$PORT/?name=John";
  ```


### How to deploy

For this you will need several steps:

1. build and upload to GCS the function source code

From the module directory :
  ```bash
  ENV=XX \
    make -f ../../module.mk clean build
  ```

2. deploy the function

From the module directory :
  ```bash
  ENV=XX \
    make -f ../../module.mk deploy
  ```

### How to interact with the deployed services


#### Examples based on the sample modules

The following sample modules are provided to deploy dummy APIs on Google Platform:
- cloudfunction.sample    (Cloud Function v1)
- cloudfunction-v2.sample (Cloud Function v2)
- cloudrun.sample         (Cloud Run, with API based on Flask-RestX)

They can be interacted with as follow:

```bash
# using json payload
curl \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json" \
  -X POST "$BASE_URL/$VERSION/$URL_PATH" \
  -d '{"name": "Jane"}';

# or, using url parameters
curl \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -X GET "$BASE_URL/$VERSION/$URL_PATH?name=Jane";
```

With,

- for the Cloud Function v1 sample:
```bash
APP_NAME_SHORT="dataservices"
TYPE="gcf"
MODULE_NAME_SHORT="functionv1"

PROJECT_ENV="dv"
PROJECT="itg-dataservices-gbl-ww-$PROJECT_ENV"

BASE_URL="https://europe-west1-$PROJECT.cloudfunctions.net/$APP_NAME_SHORT-$TYPE-$MODULE_NAME_SHORT-ew1-$PROJECT_ENV"
VERSION=
URL_PATH=
```

- for the Cloud Function v2 sample:
```bash
APP_NAME_SHORT="dataservices"
TYPE="gcf"
MODULE_NAME_SHORT="functionv2"

PROJECT_ENV="dv"
CLOUDRUN_URL_SUFFIX="iihivfdo4a-ew"

BASE_URL="https://$APP_NAME_SHORT-$TYPE-$MODULE_NAME_SHORT-ew1-$PROJECT_ENV-$CLOUDRUN_URL_SUFFIX.a.run.app"
VERSION=
URL_PATH=
```

This is because Cloud Functions v2 actually rely on Cloud Run underneath.

- for the Cloud Run sample:
```bash
APP_NAME_SHORT="dataservices"
TYPE="gcr"
MODULE_NAME_SHORT="run"

PROJECT_ENV="dv"
CLOUDRUN_URL_SUFFIX="iihivfdo4a-ew"

BASE_URL="https://$APP_NAME_SHORT-$TYPE-$MODULE_NAME_SHORT-ew1-$PROJECT_ENV-$CLOUDRUN_URL_SUFFIX.a.run.app"
VERSION=v1
URL_PATH=say-hello
```

`APP_NAME_SHORT`, `PROJECT_ENV`, `PROJECT`, `CLOUDRUN_URL_SUFFIX`, and `MODULE_NAME_SHORT` may need
to be adapted to match your local configurations.


> **Troubleshooting**</br>
> Ensure you use `https` and not `http` when calling the service.


### How to run end-to-end tests

End-to-end tests are system-level tests to validate a module or several modules working together.

The current implementation relies on PyTest files located in a separate folder `e2e-tests` within the module directory.
If provided for a module, they are run in integration specific environment(s) after the module has been fully deployed.
Per default, `qa` is the only integration environment.

The implementation is similar to unit tests. Except end-to-end tests should interact with the deployed module
and validate its functionalities.
Thus, they are expected to use actual clients and to access, even create, GCP resources.

To create end-to-end tests to validate several modules, a dedicated module must be created.
It will contain only these tests, and can deploy its own triggers to perform validations on demand,
or after any change on the associated modules.

From the module directory:
  ```bash
  ENV=XX \
    make -f ../../module.mk e2e-test
  ```

#### Recommendations

##### Deploy the module first

End-to-end tests can be run individually on `dv` to validate a pull request before merge; but they require the module to be fully deployed first.
Else the previous version of the module will be tested, instead of its latest.

That is the reason why they are run at the end of the module deploy triggers.

##### Use unique ids to avoid collisions between tests

Same as unit tests, every e2e test function should be independent to avoid potential collisions.

In particular, resources should contain unique ids when specific to a given test. Unless they are global inputs that are shared between several tests.

This guarantees as well that test functions can be run individually, or in parallel.

##### Clean up after tests

End-to-end tests should clean up the created resources or configurations before exiting.
To avoid polluting the integration env, or generating unneeded storage costs.

##### Provide explicit locations in Clients

End-to-end tests can be run locally. That means that the active gcloud configuration is used per default.

Thus, to avoid creating resources at unexpected locations, the project and other related location parameters
should be provided explicitely when instantiating Google clients.

E.g. `bigquery.Client(project=PROJECT, location=MULTIREGION)` instead of `bigquery.Client()`

##### Fill _test_env.sh_ accurately if used

End-to-end tests are provided the same environment variables as unit tests.
These variables are defined successively by $(HERE_BASE_TEST_ENV) in _module.mk_, then by the _test_env.sh_ file.

Thus, if used, the values in _test_env.sh_ should be accurate since tests might attempt to access, or create, actual resources.
Else, the needed environment variables must be re-declared in e2e-tests.


##### Provide extra dependencies in a separate requirements file

It could happen that some dependencies are needed to perform end-to-end tests (or unit tests), but should not be installed in the module distributions.

To that end, any `requirements-*.txt` will be installed in the local virtual environment.
But, per default, only the `requirements.txt` will be taken into account when deploying the module.
