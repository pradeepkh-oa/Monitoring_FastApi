"""service UT."""
# pylint: disable=invalid-name  # function names
from dataclasses import dataclass
from unittest.mock import create_autospec, patch

import pytest

from helpers.exceptions import InternalError
from .service import DefaultService, AuthorizedSession


@dataclass
class MockString:
    """Mock string to test interaction."""

    def lower(self):
        """Mock <string>.lower method."""
        return "lower_value"

    def upper(self):
        """Mock <string>.upper method."""
        return "UPPER_VALUE"


# -- fixtures
@pytest.fixture(autouse=True)  # active for namele file
def mock_sleep():
    """Mock time.sleep to avoid waiting in tests."""
    with patch("api.default.service.time.sleep"):
        yield


@pytest.fixture(name="service")
def fix_service():  # pylint: disable=unused-argument
    """Instantiate service filled with mocked dependencies."""
    return DefaultService(
        requester=create_autospec(AuthorizedSession),
    )


# -- test functions
# .upper
@pytest.mark.parametrize(
    "string, expected_output",
    [
        ("toto", "TOTO"),
        ("ninetta", "NINETTA"),
        (MockString(), "UPPER_VALUE"),
    ],
)
def test_upper_ok(service, string, expected_output):
    """Test that the function works as expected."""
    # WHEN
    output = service.upper(string=string)
    # THEN
    assert output == expected_output


# N.B. alternative test for upper ok
@patch("api.default.service.time.sleep")  # locally active
def test_upper_ok2(mock_sleep2, service):  # pylint: disable=unused-argument
    """Test that the function use expected methods."""
    # GIVEN
    mock_mock_string = create_autospec(MockString)
    mock_mock_string.upper.return_value = "VALUE"
    # WHEN / THEN
    assert service.upper(string=mock_mock_string) == "VALUE"
    mock_mock_string.upper.assert_called_once_with()
    mock_mock_string.lower.assert_not_called()


def test_upper_error_when_bad_input(service):
    """Test that the function fails with expected error when receiving bad input."""
    # WHEN / THEN
    with pytest.raises(InternalError):
        service.upper(476)
