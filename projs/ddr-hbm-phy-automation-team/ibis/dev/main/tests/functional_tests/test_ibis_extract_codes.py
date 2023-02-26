#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for ibis_extract_codes.py
"""
import pytest
from pathlib import Path
import sys

REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "ibis/dev/main/bin"))
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))

import CommonHeader
import Messaging
import ibis_extract_codes


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


class TestIbisExtractCodes:
    """Tests for ibis_extract_codes.py"""

    Messaging.create_logger("/dev/null")

    def test_missing_required_args(self):
        """Test running with missing args"""
        with pytest.raises(SystemExit) as exception:
            ibis_extract_codes.main(["-d", "99"])
        assert exception.value.code == 2


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__, "--capture", "no"] + sys.argv[1:])
    sys.exit(ret_code)
