"""User application making up."""


import logging
from typing import List

import flask
from google.cloud import error_reporting

from loreal.flask_commons import make_api
from loreal.wrappers.sessions import RefreshableOAuth2Session

# Import managers & controllers
from api.default import controller as default_controller
from api.default.service import DefaultService
from api.default.validators import DefaultValidator
from helpers.constants import (
    API_NAME,
    API_VERSION,
    API_VERSION_PATH,
    API_TITLE,
    API_DESCRIPTION,
)

LOGGER = logging.getLogger(__name__)


def make_app() -> List[flask.Blueprint]:  # pragma: no cover
    """Set up API blueprint, controllers, services, providers and ORM.

    Returns:
        The API configured blueprint.
    """
    LOGGER.info("Creating API blueprint.")

    blueprints = []
    # Build the API and the standard blueprint
    blueprint_api, api = make_api(
        api_name=API_NAME,
        api_version=API_VERSION,
        api_version_path=API_VERSION_PATH,
        api_title=API_TITLE,
        api_description=API_DESCRIPTION,
        error_reporting_client=error_reporting.Client(),
    )
    blueprints.append(blueprint_api)

    # Instantiate clients and wrappers
    requester = RefreshableOAuth2Session()

    # Instantiate validators and providers
    default_validator = DefaultValidator(set())

    # Instantiate services
    default_service = DefaultService(
        requester=requester,
    )

    # Build controllers
    default_controller.build(
        api,
        service=default_service,
        validator=default_validator,
    )
    return blueprints
