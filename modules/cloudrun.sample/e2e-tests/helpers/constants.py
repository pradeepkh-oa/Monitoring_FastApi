"""Constants."""
import os


# -- Context provided by module.mk
# Context
APP_NAME = os.environ["MODULE_NAME"]
APP_NAME_SHORT = os.environ["MODULE_NAME_SHORT"]

MODULE_NAME = os.environ["MODULE_NAME"]
MODULE_NAME_SHORT = os.environ["MODULE_NAME_SHORT"]

PROJECT = os.environ["PROJECT"]
PROJECT_ENV = os.environ["PROJECT_ENV"]
PROJECT_NUMBER = os.environ.get("PROJECT_NUMBER")


# -- Module information provided by test_env.sh
# API
SERVICE_URL = os.environ["SERVICE_URL"]
IDENTITY = os.environ["IDENTITY"]
