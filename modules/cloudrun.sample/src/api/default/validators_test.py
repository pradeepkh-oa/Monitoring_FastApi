"""validators UT."""
# pylint: disable=invalid-name  # function names
import pytest

from helpers.exceptions import BadRequest
from .validators import validate_consistency_with_payload, DefaultValidator


# -- fixtures
@pytest.fixture(name="validator")
def fix_default_validator():
    """Build the default validator filled with dummy dependencies."""
    return DefaultValidator({"taboo"})


# -- test functions
# validate_consistency_with_payload
@pytest.mark.parametrize(
    "value, value_in_body",
    [
        ("world", "world"),
        ("earth", "earth"),
        ("earth", None),
    ],
)
def test_validate_consistency_with_payload_ok(value, value_in_body):
    """Validate the function does not raise any error in nominal case."""
    # WHEN / THEN
    validate_consistency_with_payload(value, value_in_body)


@pytest.mark.parametrize(
    "value, value_in_body",
    [
        ("world", "NOT_WORLD"),
        ("toto", "tata"),
    ],
)
def test_validate_consistency_with_payload_error(value, value_in_body):
    """Validate that BadRequest is raised when values are different."""
    # WHEN / THEN
    with pytest.raises(BadRequest):
        validate_consistency_with_payload(value, value_in_body)


# DefaultValidator
@pytest.mark.parametrize(
    "names",
    [
        ("world",),
        ("world", "earth"),
    ],
)
def test_validate_names_ok(validator, names):
    """Validate the method does not raise any error in nominal case."""
    # WHEN / THEN
    validator.validate_names(*names)


@pytest.mark.parametrize(
    "names",
    [
        ("worldtaboo",),
        ("world", "eartabooth"),
    ],
)
def test_validate_names_error(validator, names):
    """Validate that BadRequest is raised when names contain any forbidden word."""
    # WHEN / THEN
    with pytest.raises(BadRequest):
        validator.validate_names(*names)
