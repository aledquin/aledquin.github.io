#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for Misc.py's read_legal_release() function.
"""
import pytest
from pathlib import Path
import sys
REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))

import Misc
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


class TestMiscLegalReleaseParse:
    """Tests for Misc.read_legal_release()"""

    Messaging.create_logger("/dev/null")

    def test_deprecated_tcl_parse(self) -> None:
        """Test reading an old-style TCL file"""
        test_input = f"{REPO_TOP}/ddr-ckt-rel/dev/main/tests/data/alphaHLDepotSeed/lpddr5x.d930-lpddr5x-tsmc5ff12.rel1.00_cktpcs.legalRelease.txt"
        expected_output = {
            "rel": "3.00a",
            "p4_release_root": "products/lpddr5x_ddr5_phy/lp5x/project/d930-lpddr5x-tsmc5ff12",
        }
        assert Misc.read_legal_release(test_input) == expected_output

    def test_compare_tcl_to_yml(self) -> None:
        """Make sure TCL and YAML parse is equivalent"""
        tcl_input = f"{REPO_TOP}/admin/samples/legalRelease.txt"
        yml_input = f"{REPO_TOP}/admin/samples/legalRelease.yml"
        parsed_tcl = Misc.read_legal_release(tcl_input)
        parsed_yml = Misc.read_legal_release(yml_input)

        assert parsed_tcl["rel"] == parsed_yml["rel"]
        assert parsed_tcl["p4_release_root"] == parsed_yml["p4_release_root"]

    def test_load_invalid_yaml(self, tmp_path) -> None:
        """Test reading invalid YAML."""
        invalid_yaml = tmp_path / "invalid.yml"
        invalid_yaml.write_text("not: valid: yaml []")

        with pytest.raises(Exception, match='invalid.yml", line 1'):
            Misc.read_legal_release(invalid_yaml)

    def test_loading_missing_file(self) -> None:
        """Test reading a missing file."""
        with pytest.raises(FileNotFoundError, match="Could not find legal"):
            Misc.read_legal_release("path/does/not/exist")

    def test_failed_schema_validation(self, tmp_path, capfd) -> None:
        """Test a failed schema validation error"""
        invalid_yaml = tmp_path / "invalid.yml"
        invalid_yaml.write_text("rel: [1, 2, 3]")  # rel should be a string

        with pytest.raises(SystemExit, match="1"):
            Misc.read_legal_release(invalid_yaml, validate=True)
        out, _ = capfd.readouterr()

        expected_partial_message = (
            "Failed validating 'type' in schema['properties']['rel']:\n"
            "    {'description': 'Release number. Example: 2.30a', 'type': 'string'}\n\n"
            "On instance['rel']:\n"
            "    [1, 2, 3]"
        )
        assert expected_partial_message in out


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__, "--capture", "no"] + sys.argv[1:])
    sys.exit(ret_code)
