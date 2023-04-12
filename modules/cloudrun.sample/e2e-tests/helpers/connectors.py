"""Managers, clients and related methods to interact with the API or services."""


from loreal.wrappers.sessions import RefreshableOIDCSession

from .constants import IDENTITY, SERVICE_URL


class Connectors:
    """Bundle class to containing needed managers, clients or methods.

    To interact with module and validate its features.
    """

    def __init__(self):
        """Build instance."""
        self.requester = RefreshableOIDCSession(SERVICE_URL, identity=IDENTITY)
