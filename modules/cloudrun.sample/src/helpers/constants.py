"""Generic constants."""
import os
import re


# -- API information
MODULE_NAME = os.environ["MODULE_NAME"]
MODULE_NAME_SHORT = os.environ["MODULE_NAME_SHORT"]

PROJECT = os.environ["PROJECT"]
PROJECT_ENV = os.environ["PROJECT_ENV"]
PROJECT_NUMBER = os.environ.get("PROJECT_NUMBER")

# API designation
API_NAME = "APP_NAME-API_NAME"
API_VERSION = "0.5"
API_VERSION_PATH = "v1"
API_TITLE = "API_TITLE"
API_DESCRIPTION = "API_DESCRIPTION"

# Module configuration
IDENTITY = os.environ["IDENTITY"]
SERVICE_URL = os.environ["SERVICE_URL"]

TIMEOUT = int(os.environ["TIMEOUT"])

# (optional) Apigee configuration if the module is deployed as proxy
APIGEE_SA = os.environ.get("APIGEE_SA")
APIGEE_ACCESS_SECRET_ID = os.environ.get("APIGEE_ACCESS_SECRET_ID")


# -- Specific env vars for module
# ...


# -- Patterns
ENDS_BY_ENV_PATTERN = re.compile(r"^.+_(dv|qa|np|pd)$")  # example
