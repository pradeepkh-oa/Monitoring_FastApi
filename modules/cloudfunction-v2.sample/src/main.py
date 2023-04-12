#!/usr/bin/env python3
"""Main to define a Python GCF that is HTTP-triggered."""
import json
import logging
import os
from typing import Any, Union

import functions_framework
from flask import Request
from google.cloud import error_reporting

from loreal.flask_commons import setup_logging

from default_api.service import DefaultService

# setup
setup_logging(is_local_runtime=__name__ == "__main__")

VERSION = os.environ.get("K_REVISION", "Local")
LOGGER = logging.getLogger(__name__)


@functions_framework.http
def main(request: Request) -> Union[str, Any]:  # pragma: no cover
    """Process incoming HTTP requests to Cloud function.

    Args:
        request: The request object.
            Cf. https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data

    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`.
        Cf. https://flask.palletsprojects.com/en/1.1.x/api/#flask.make_response
    """
    try:
        request_json = request.get_json(silent=True)
        request_args = request.args

        # Instantiate services
        default_service = DefaultService()

        if request_json and "name" in request_json:
            name = request_json["name"]
        elif request_args and "name" in request_args:
            name = request_args["name"]
        else:
            name = "World"
        return json.dumps(
            {
                "status": "OK",
                "message": f"Hello {default_service.upper(name)}!",
                "version": VERSION,
            }
        )

    except Exception as err:  # pylint: disable=broad-except
        # catch all exceptions and log to prevent cold boot
        # report with error_reporting
        error_reporting.Client().report_exception()
        err_type = f"{err.__class__.__module__}.{err.__class__.__name__}"
        err_message = str(err)
        LOGGER.critical(
            "Internal error: %s -> %s", err_type, err_message, exc_info=True
        )
        return json.dumps(
            {
                "status": "ERROR",
                "message": f"{err_type}: {err_message}",
                "version": VERSION,
            }
        )
