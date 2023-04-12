"""Common configuration for API tests.

Please do not modify this file, or at your own risk.
"""
from unittest.mock import create_autospec
from typing import Generator

import pytest
from flask import Flask
from flask_restx import Api

from google.cloud import error_reporting

from loreal.flask_commons import make_api

from helpers.constants import (
    MODULE_NAME,
    API_NAME,
    API_VERSION,
    API_TITLE,
    API_DESCRIPTION,
)


# -- fixtures
@pytest.fixture(name="app")
def app_fixture() -> Generator[Flask]:
    """Set up testing Flask app."""
    flask_app = Flask(MODULE_NAME + "_test")
    flask_app.testing = True
    flask_app.config["RESTX_ERROR_404_HELP"] = False
    flask_app.config["ERROR_INCLUDE_MESSAGE"] = False

    yield flask_app


@pytest.fixture(name="api")
def api_fixture(app: Flask) -> Generator[Api]:
    """Set up api and blueprint."""
    blueprint_api, api = make_api(
        api_name=API_NAME,
        api_version=API_VERSION,
        api_version_path="",  # ignored for tests
        api_title=API_TITLE,
        api_description=API_DESCRIPTION,
        error_reporting_client=create_autospec(error_reporting.Client),
    )

    app.register_blueprint(blueprint_api)
    yield api
