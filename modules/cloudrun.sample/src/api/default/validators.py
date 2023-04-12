"""Default validators."""
from typing import Collection, Set, Union

from google.cloud.firestore import CollectionReference

from helpers.exceptions import BadRequest


def validate_consistency_with_payload(
    value: str, value_in_payload: str = None, name: str = "name"
) -> None:
    """Validate the consistency of values passed in the request.

    `name` is used to identify the associated field in the error message. It might
    differ in payload.

    Example:
    >>> validate_consistency_with_payload(name, payload.get("name"))
    """
    if value_in_payload is None:
        return  # optional

    if value != value_in_payload:
        raise BadRequest(
            f"Incoherent parameter {name}. Optional field values should be consistent"
            f" with the payload, but received: {value!r} != {value_in_payload!r}."
        )


class DefaultValidator:
    """Implement a dummy validator (for demo)."""

    def __init__(
        self,
        forbidden_word_collection: Union[CollectionReference, Collection[str]],
    ):
        """Initialize the instance.

        Args:
            forbidden_word_collection: Contains the list of forbidden words.
        """
        self.forbidden_word_collection = forbidden_word_collection

    @property
    def forbidden_words(self) -> Set[str]:
        """Fetch up-to-date collection of forbidden words."""
        if isinstance(
            self.forbidden_word_collection, CollectionReference
        ):  # pragma: no cover
            return set(
                document.id for document in self.forbidden_word_collection.stream()
            )
        return set(self.forbidden_word_collection)

    def validate_names(self, *names: str) -> None:
        """Validate that the names do not contain any forbidden words."""
        if any(fword in name for name in names for fword in self.forbidden_words):
            raise BadRequest(
                f"Invalid name(s). They should not contain: {self.forbidden_words}"
            )
