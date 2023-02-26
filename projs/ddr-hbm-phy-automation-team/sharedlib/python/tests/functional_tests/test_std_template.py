#!/depot/Python/Python-3.10/bin/python
"""
Example tests for test_std_template.py
"""
import pytest
from pathlib import Path
import sys
import os

REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))
sys.path.append(str(REPO_TOP / "python/bin"))

import CommonHeader
import Messaging
import std_template


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


class TestStdTemplate:
    """Tests for std_template.py"""

    Messaging.create_logger("/dev/null")

    def test_help_message(self, capfd):
        """Test the message printed after running with --help"""
        with pytest.raises(SystemExit) as exception:
            std_template.main(["-h"])
        assert exception.value.code == 0

        out, err = capfd.readouterr()
        assert "<DOCUMENT PURPOSE AND USAGE OF THIS SCRIPT>" in out
        assert "-h, --help" in out
        assert err == ""

    @pytest.mark.skipif("GITLAB_CI" in os.environ, reason="Skipping test from GitLab Pipeline")
    def test_main_return_value(self):
        """
        Make sure main() returns None.
        This test is also an example for skipping a test from the GitLab Pipeline.
        Add the decorator on the line before the test declaration (def test_<name>)
        """
        assert std_template.main() is None


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
