"""main UT."""
import os

os.environ["TEST_ENV"] = "1"


import main  # pylint: disable=unused-import,wrong-import-position


def test_dummy():
    """Dummy test to ensure at least one UT."""
