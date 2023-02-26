#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for sharedlib/python/Util/Misc.py
NOTE: Uses pytest instead of unittest
      Mocking is still done with unittest.mock
"""
import os
import pytest
from unittest import mock
from pathlib import Path
import sys
from datetime import datetime

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


class MockDatetime(datetime):
    """
    Mock replacement for datetime. Python built-ins cannot be easily mocked.
    See TestMisc.test_get_the_date for example usage.
    https://williambert.online/2011/07/how-to-unit-testing-in-django-with-mocking-and-patching/
    """
    def __new__(cls, *args, **kwargs):
        return datetime.__new__(datetime, *args, **kwargs)


class TestMisc:
    """Tests for Misc.py"""

    def test_get_max_val(self) -> None:
        """Test aliased function get_max_val()"""
        assert Misc.get_max_val == max
        assert Misc.get_max_val([1, 2, 3]) == max([1, 2, 3])

    def test_get_min_val(self) -> None:
        """Test aliased function get_min_val()"""
        assert Misc.get_min_val == min
        assert Misc.get_min_val([1, 2, 3]) == min([1, 2, 3])

    def test_get_script_bin_dir(self) -> None:
        """Test helper function for finding the currently executed script's bin directory."""
        # TODO, what if test is executed via runner or pytest on command-line?
        expected_path = Path(__file__).resolve().parent
        assert Misc._find_script_bin_dir() == Path(expected_path)

    def test_get_release_version(self) -> None:
        """Test getting the current toolset's release version string."""
        bin_dir = Path(__file__).resolve().parent / "../../../../ddr-ckt-rel/dev/main/bin"
        expected_version_file = bin_dir / ".version"
        expected_version = expected_version_file.read_text().strip()
        assert Misc.get_release_version(bin_dir) == expected_version

    def test_get_the_date(self) -> None:
        """Test getting the current time as a list of strings."""
        MockDatetime.now = classmethod(lambda cls: datetime(year=2022, month=1, day=1, hour=12, minute=30, second=15))
        with mock.patch("Misc.datetime", MockDatetime):
            assert Misc.get_the_date() == ["Sat", "Jan", "01", "12:30:15", "2022"]

    def test_parse_project_spec(self) -> None:
        """Test parsing project specs"""
        project_string = "lpddr54/d890-lpddr54-tsmc5ff-12/rel1.00_cktpcs"
        family, project, release = Misc.parse_project_spec(project_string)
        assert family == "lpddr54"
        assert project == "d890-lpddr54-tsmc5ff-12"
        assert release == "rel1.00_cktpcs"

        with pytest.raises(ValueError, match="Invalid project string"):
            Misc.parse_project_spec("not/a/valid/proj/string")
        with pytest.raises(ValueError, match="Invalid project string"):
            Misc.parse_project_spec("not/valid")

    def test_validate_legal_release(self) -> None:
        """Test the legal release schema validation function."""
        sample_legal_release = REPO_TOP / "admin/samples/legalRelease.yml"
        # No errors should come up
        Misc.read_legal_release(sample_legal_release, validate=True)
        sample_legal_release = REPO_TOP / "admin/samples/legalRelease.txt"
        Misc.read_legal_release(sample_legal_release, validate=True)

    def test_first_available_file(self) -> None:
        """Test the first available file function."""

        result = Misc.first_available_file([
            REPO_TOP / "admin/samples/legalRelease.yml",
            REPO_TOP / "admin/samples/legalRelease.txt",
        ])
        assert result == REPO_TOP / "admin/samples/legalRelease.yml"

        with mock.patch.dict(os.environ, {"DDR_DA_SKIP_YAML_FIRSTAVAILABLEFILE": "TRUE"}, clear=True):
            result = Misc.first_available_file([
                REPO_TOP / "admin/samples/legalRelease.yml",
                REPO_TOP / "admin/samples/legalRelease.txt",
            ])
            assert result == REPO_TOP / "admin/samples/legalRelease.txt"

        with pytest.raises(FileNotFoundError, match="No files exist in list:"):
            Misc.first_available_file([
                Path("/does/not/exist/ever.txt"),
                "/also/does/not/exist",
            ])


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
