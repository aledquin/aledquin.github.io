#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for Misc.py's write_file() function.
"""
import pytest
from pathlib import Path
import sys
import shutil

REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))

import Misc
import CommonHeader


def main() -> None:
    """Empty main for admin/check_code.csh"""
    pass


class CommonHeaderArgs:
    """Helper used for initializing CommonHeader"""

    d = 0
    v = 0
    __author__ = "unittest"
    __version__ = "1.00"


def setup_module(_) -> None:
    """Setup CommonHeader before tests."""
    CommonHeader.init(CommonHeaderArgs, CommonHeaderArgs.__author__, CommonHeaderArgs.__version__)


class TestMiscWriteFile:
    """Tests for Misc.write_file()"""

    ARTIFACTS_DIR = Path("test_misc_write_file_dir")

    def setup_method(self, _) -> None:
        """Delete the artifact dir before every test."""
        if TestMiscWriteFile.ARTIFACTS_DIR.is_dir():
            shutil.rmtree(TestMiscWriteFile.ARTIFACTS_DIR)

    def teardown_method(self, _) -> None:
        """Delete the artifact dir after every test."""
        if TestMiscWriteFile.ARTIFACTS_DIR.is_dir():
            shutil.rmtree(TestMiscWriteFile.ARTIFACTS_DIR)

    def test_happy_path(self) -> None:
        """Test happy path for writing a regular file in a dir that exists."""
        output_file = TestMiscWriteFile.ARTIFACTS_DIR / "test.txt"
        TestMiscWriteFile.ARTIFACTS_DIR.mkdir(exist_ok=True)
        contents = [
            "1. You can write to this file!\n",
            "2. Third line is blank",
        ]
        Misc.write_file(contents, output_file)
        assert list(Misc.read_file(output_file)) == [x.rstrip() for x in contents]

    def test_parent_dir_do_not_exist(self) -> None:
        """Test writing to a file whose parent dirs don't exist."""
        output_file = TestMiscWriteFile.ARTIFACTS_DIR / "this/dir/does/not/exist/test.txt"
        with pytest.raises(Exception, match="Parent directories do not exist"):
            Misc.write_file("test", output_file)

    def test_parent_dir_do_not_exist_mkdir(self):
        """Test writing to a file whose parent dirs don't exist but create the parent dirs."""
        output_file = TestMiscWriteFile.ARTIFACTS_DIR / "does/not/exist/test.txt"
        contents = "foo\nbar"
        Misc.write_file(contents, output_file, mkdir=True)
        assert list(Misc.read_file(output_file)) == contents.splitlines()

    def test_write_to_directory(self) -> None:
        """Test writing to a directory."""
        output_file = TestMiscWriteFile.ARTIFACTS_DIR
        output_file.mkdir(exist_ok=True)
        with pytest.raises(Exception, match=f"Is a directory: '{output_file}'"):
            Misc.write_file("test", output_file)


if __name__ == "__main__":
    ret_code = pytest.main([__file__] + sys.argv[1:])
    Misc.utils__script_usage_statistics(Path(__file__).name, CommonHeaderArgs.__version__)
    sys.exit(ret_code)
