#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for perc_seeding.py
"""
import pytest
from pathlib import Path
import sys

REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "ddr-ckt-rel/dev/main/bin"))
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))


import CommonHeader
import Messaging


class CommonHeaderArgs:
    """Helper used for initializing CommonHeader"""

    d = 0
    v = 0
    __author__ = "unittest"
    __version__ = "1.00"


def setup_module(_) -> None:
    """Setup CommonHeader before tests."""
    CommonHeader.init(
        CommonHeaderArgs, CommonHeaderArgs.__author__, CommonHeaderArgs.__version__
    )


class TestPercSeeding:
    """Tests for perc_seeding.py"""

    Messaging.create_logger("/dev/null")

    def test_submit_to_p4(self) -> None:
        """Test if all the files have been created successfully"""


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__, "--capture", "no"] + sys.argv[1:])
    sys.exit(ret_code)
