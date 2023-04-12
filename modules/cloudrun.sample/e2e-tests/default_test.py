"""Test the default API of module."""

import pytest


from helpers.connectors import Connectors
from helpers.constants import SERVICE_URL

BASE_URL = f"{SERVICE_URL}/v1/say-hello"

# N.B. The tests below are only provided as examples.
# They may not be needed as-is for a real module if they intersect with
# what unit tests have already validated.


# -- test functions
# /say-hello
@pytest.mark.parametrize("name", [None, "John"])
def test_e2e_get_ok(connectors: Connectors, name):
    """Test that the route works as expected."""
    # GIVEN
    expected_name = (name if name else "World").upper()
    # WHEN
    response = connectors.requester.request(
        "GET", url=BASE_URL + (f"?{name=!s}" if name else "")
    )
    # THEN
    assert response.json()["data"]["message"] == f"Hello {expected_name}!"


@pytest.mark.parametrize("name", ["John"])
def test_e2e_post_ok(connectors: Connectors, name):
    """Test that the route works as expected."""
    # WHEN
    response = connectors.requester.request("POST", url=BASE_URL, json={"name": name})
    # THEN
    assert response.json()["data"]["message"] == f"Hello {name.upper()}!"


# /say-hello/{name}
@pytest.mark.parametrize("name", ["John"])
def test_e2e_get_name_ok(connectors: Connectors, name):
    """Test that the route works as expected."""
    # WHEN
    response = connectors.requester.request("GET", url=f"{BASE_URL}/name/{name}")
    # THEN
    assert response.json()["data"]["message"] == f"Hello {name.upper()}!"


@pytest.mark.parametrize("name", ["John"])
def test_e2e_post_name_ok(connectors: Connectors, name):
    """Test that the route works as expected."""
    # WHEN
    response = connectors.requester.request(
        "POST", url=f"{BASE_URL}/name/{name}", json={"name": name}
    )
    # THEN
    assert response.json()["data"]["message"] == f"Hello {name.upper()}!"
