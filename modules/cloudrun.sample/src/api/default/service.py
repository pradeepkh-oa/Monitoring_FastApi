"""Implement a standard service."""
import time


from loreal.wrappers.sessions import AuthorizedSession

from helpers.exceptions import InternalError


class DefaultService:
    """Implement a dummy service (for demo)."""

    def __init__(self, requester: AuthorizedSession):
        """Initialize the instance."""
        self.requester = requester  # example

    def upper(self, string: str) -> str:
        """Convert string to uppercase."""
        try:
            time.sleep(10)  # left as an example to be patched 'globally' in test file
            return string.upper()
        except AttributeError as err:
            raise InternalError(
                f"While converting string to uppercase: {err.__class__.__name__}: {err}"
            ) from err
