"""Default API."""
import logging

from flask_restx import Api, fields, Resource
from flask_restx.reqparse import RequestParser

from loreal.flask_commons import (
    create_error_model,
    create_output_model,
    format_response,
)
from loreal.flask_commons.formatter import JsonObject

from .service import DefaultService
from .validators import validate_consistency_with_payload, DefaultValidator


LOGGER = logging.getLogger(__name__)

FlaskResponse = tuple[JsonObject, int]


def build(api: Api, service: DefaultService, validator: DefaultValidator) -> None:
    """Build API."""
    LOGGER.debug("Create %s controller", __name__)
    namespace = api.namespace(
        "Test API",
        path="/say-hello",
        description="Hello endpoint to test default API",
        validate=True,  # validate input models
    )

    # -- inputs
    # payload
    input_model = namespace.model(
        "InputModel",
        {
            "name": fields.String(
                required=True,
                description="Someone to say hello to.",
                example="toto",
                # enum=<list-of-valid-values>
            ),
        },
        strict=True,  # prevent unwanted fields in input
    )

    # url parameters
    name_parser = RequestParser()
    name_parser.add_argument(
        "name",
        type=str,
        location="args",
        help="If provided, say hello to someone in that location.",
        default=None,
        # choices=<list-of-valid-values>
    )

    # -- output models
    error_model = create_error_model(namespace)

    message_model = namespace.model(
        "MessageModel",
        {
            "message": fields.String(
                required=True,
                description="Message to say hello to people.",
            ),
        },
    )

    message_output_model = create_output_model(
        namespace,
        message_model,
        skip_none=True,  # remove None (or empty dict) fields from response
    )

    @namespace.route("")
    class HelloWorldResource(Resource):  # pylint: disable=unused-variable
        """API dummy Resource to say hello to everyone, unless specified (for demo)."""

        @namespace.doc(
            description="Or to someone if provided.",  # body in swagger description
            params={"name": "If provided, name to say hello to."},
        )
        @namespace.expect(name_parser)  # enforced input model
        @namespace.marshal_with(message_output_model)  # enforced response model
        @namespace.response(500, "Server error", error_model)
        def get(self) -> FlaskResponse:
            """Say hello to the world."""  # SWAGGER description summary
            name = name_parser.parse_args().name or "World"
            LOGGER.debug("controller.get: say hello %s", name)
            # process
            people = service.upper(name)
            return format_response({"message": f"Hello {people}!"}, 200)

        @namespace.expect(input_model)
        @namespace.marshal_with(message_output_model)
        @namespace.response(400, "Bad Request", error_model)
        @namespace.response(500, "Server error", error_model)
        def post(self) -> FlaskResponse:
            """Say hello to the person provided in payload."""
            name = namespace.payload["name"]
            LOGGER.debug("controller.post: say hello to %s", name)
            # validate
            validator.validate_names(name)
            # process
            people = service.upper(name)
            return format_response({"message": f"Hello {people}!"}, 200)

    @namespace.route("/name/<string:name>")
    class HellonameResource(Resource):  # pylint: disable=unused-variable
        """API dummy Resource to say hello to someone in particular (for demo)."""

        @namespace.doc(
            params={"name": "Someone to say hello to."},
        )
        @namespace.marshal_with(message_output_model)
        @namespace.response(500, "Server error", error_model)
        def get(self, name: str) -> FlaskResponse:
            """Say hello to someone."""
            LOGGER.debug("controller.get: say hello to %s", name)
            # validate
            validator.validate_names(name)
            # process
            people = service.upper(name)
            return format_response({"message": f"Hello {people}!"}, 200)

        @namespace.expect(input_model)
        @namespace.marshal_with(message_output_model)
        @namespace.response(400, "Bad Request", error_model)
        @namespace.response(500, "Server error", error_model)
        def post(self, name: str) -> FlaskResponse:
            """Say hello to the person provided in payload."""
            LOGGER.debug("controller.put: say hello to %s", name)
            payload = namespace.payload
            # validate
            validate_consistency_with_payload(name, payload.get("name"))

            validator.validate_names(name)
            # process
            people = service.upper(namespace.payload["name"])
            return format_response({"message": f"Hello {people}!"}, 200)
