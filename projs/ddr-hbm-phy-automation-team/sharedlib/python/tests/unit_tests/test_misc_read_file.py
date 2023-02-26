#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for Misc.py's read_file() function.
"""
import pytest
from pathlib import Path
import os
import sys
import stat

REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))

import Misc
import CommonHeader


class CommonHeaderArgs:
    """Helper used for initializing CommonHeader"""

    d = 0
    v = 0
    __author__ = "unittest"
    __version__ = "1.00"


def setup_module(_) -> None:
    """Setup CommonHeader before tests."""
    CommonHeader.init(CommonHeaderArgs, CommonHeaderArgs.__author__, CommonHeaderArgs.__version__)


class TestMiscReadFile:
    """Tests for Misc.read_file()"""

    def test_happy_path(self) -> None:
        """Test happy path for reading a regular file."""
        test_input = f"{REPO_TOP}/sharedlib/python/tests/data/sample.txt"
        expected_output = [
            "1. You can read this file!",
            "2. Third line is blank",
        ]
        assert list(Misc.read_file(test_input)) == expected_output

    def test_file_does_not_exist(self) -> None:
        """Test reading a file that doesn't exist."""
        test_input = f"{REPO_TOP}/file_does_not_exist.test"
        expected_output = []
        assert list(Misc.read_file(test_input)) == expected_output

    def test_read_directory(self):
        """Test reading a directory (should not be possible)."""
        test_input = f"{REPO_TOP}/sharedlib/"
        expected_output = []
        assert list(Misc.read_file(test_input)) == expected_output

    def test_no_file_permissions(self):
        """Test reading a file without OS read permissions."""
        test_input = f"/tmp/no_permission_{os.getpid()}"
        Path(test_input).touch(mode=0o000, exist_ok=True)
        expected_output = []
        assert list(Misc.read_file(test_input)) == expected_output
        os.chmod(test_input, stat.S_IWUSR)
        os.remove(test_input)


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
