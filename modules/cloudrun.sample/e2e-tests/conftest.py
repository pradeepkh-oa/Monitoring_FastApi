"""Global PyTest configuration for e2e-tests of module."""

import pytest

from helpers.connectors import Connectors


# -- Global fixtures run once by session
@pytest.fixture(name="connectors", scope="session")
def fix_connectors() -> Connectors:
    """Build the needed connectors to be accessible by all tests."""
    return Connectors()
