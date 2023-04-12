#!/usr/bin/env python3
"""Main to define a Flask application for GKE, GCR, or GCF.

Please do not modify this file, or at your own risk.
"""
import os


from loreal.flask_commons import build_app

from application import make_app  # application definition
from helpers.constants import (
    MODULE_NAME,
    APIGEE_SA,
    APIGEE_ACCESS_SECRET_ID,
)

# In pytest, we use a test app instead

if os.environ.get("TEST_ENV", "0") != "1":  # pragma: no cover
    blueprints = make_app()
    is_local_runtime = (__name__ == "__main__") or os.environ.get("GUNICORN_DEBUG")

    app = build_app(
        module_name=MODULE_NAME,
        blueprints=blueprints,
        is_local_runtime=is_local_runtime,
        # Optional, unless the module is deployed to Apigee
        apigee_sa=APIGEE_SA,
        apigee_access_secret_id=APIGEE_ACCESS_SECRET_ID,
    )
    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=8000, debug=False)  # nosec
