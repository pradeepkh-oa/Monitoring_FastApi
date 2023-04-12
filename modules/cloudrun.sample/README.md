# README - Sample module for Flask RestX API on Google Cloud Run

## Purpose

This document aims to give information on the current module which is dedicated
to be a base template for building REST APIs using the Flask-RestX framework.

## Content

Within the folder `api/`, structure and tests are provided to showcase common patterns.
None of it should be kept as-is, or taken too literally. They are merely examples to help you get started.

In contrast, some files must be left unchanged or kept in the same overall format:
- `main.py`
- `application.py`
- and, as much as possible, the existing utils in `helpers/` and `wrappers/`.
  They can however be completed, or extended.


## Module description

### Architecture

This module contains the implementation of the configuration API. It is based
on the use of `Flask` library and its extension `Flask-Restx`.

`Flast-Restx` brings flexibility in the implementation of API making them
compatible with Swagger.

The current module template implements the hexagonal architecture a common pattern
for n-tier web applications.

### Components

The main components are:

  | Component name | Comment                           |
  | -------------- | --------------------------------- |
  | controller     | the entrypoint of an API endpoint |
  | services       | the logical of the API endpoint   |


The secondary components are:

  | Component name | Comment                                                                          |
  | -------------- | -------------------------------------------------------------------------------- |
  | validators     | contains controller model validation functions                                   |
  | models         | provides the internal business payload if necessary                              |
  | converters     | provides the functions converting from controller layer to business if necessary |




### How to create a new API endpoint?

To do so one needs to create a factory method which per API endpoint to be built.

The principle is to have a file providing the builder for the endpoint:

```python
def build(api: Api):
    # 1. create the namespace grouping the endpoint URIs
    namespace = api.namespace("/endpoint-path", description="The namespace description")

    model = namespace.model( ... )

    # invocation will be:
    #   http://server:port/blueprint-base-url/endpoint-path
    @namespace.route("")
    class EndpointListResource(Resouce):
        """Class Implementing the root path of the path."""

        # define the various method taking no parameters
        def get(self):
            return "GETCHA"

        def post(self):
            return "POSTCHA"

        # ...

    # invocation will be:
    #   http://server:port/blueprint-base-url/endpoint-path/object_id
    @namespace.route("/<string:object_id>")
    class EndpointResource(Resource):
        """Class Implementing the parameterized endpoint."""

        def get(self, object_id: string):
            return f"GOTCHA{object_string}"

        # ...

```

To use it, one needs to call the build method in the `application.py` file:

```python
from api.domain1 import controller as domain1_controller
from api.domain1.services import Domain1Service
# ...

    # ... code ...

    ### Build the main controllers ###
    blue_prints = []

    # Create API
    blue_print_api, api = make_api(
        api_name=constants.API_NAME,
        api_version=constants.API_VERSION,
        api_version_path=constants.API_VERSION_PATH,
        api_title=constants.API_TITLE,
        api_description=constants.API_DESCRIPTION,
    )

    # Register API error handlers
    register_error_handlers(api, error_reporting.Client())

    # Instantiate services
    domain1_service = Domain1Service()
    # ...

    Domain1Controller.build(api, domain1_service)
    Domain2Controller.build(api, domain2_service)
    # ...
```


### How to manage errors

Exceptions must be managed by added an error handler in the `register_error_handlers`
function.
The catch all exception must be the last to be declared.
