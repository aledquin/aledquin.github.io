#!/depot/Python/Python-3.8.0/bin/python
import pytest
from unittest import mock

# import os
import pathlib
import sys
import argparse

bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + "/../../lib/python/Util")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../../../../../sharedlib/python/Util")
# Add path to script directory.
sys.path.append(bindir + "/../../bin/")

import gen_runExtract as gen_rE
import CommonHeader as CH


@pytest.fixture(autouse=True)
def setup():
    args = parse_cmd_args([])
    CH.init(args, [], [])


def parse_cmd_args(tst):
    parser = argparse.ArgumentParser(description="Test parser")
    parser.add_argument(
        "-v", metavar="<#>", type=int, default=0, help="verbosity"
    )
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")
    args = parser.parse_args(tst)
    return args


def test_check_netlist():
    with mock.patch("os.path.isdir", return_value=False):
        with pytest.raises(SystemExit, match="1"):
            gen_rE.check_netlist("test")


def test_check_output():
    with mock.patch("os.path.isdir", return_value=False):
        with pytest.raises(SystemExit, match="1"):
            gen_rE.check_output("test")


def test_check_GR():
    with mock.patch("os.path.isdir", return_value=False):
        with pytest.raises(SystemExit, match="1"):
            gen_rE.check_GR("test")
    with mock.patch("P4.P4.disconnect"):
        with pytest.raises(SystemExit, match="1") as mock_disconnect:
            file_path = "/not/a/p4/path"
            gen_rE.check_GR(file_path)
            gen_rE.check_GR("//depot")
            mock_disconnect.assert_called()


def test_check_p4_files():
    test_data = ["no such file(s).\n"]
    answer = gen_rE.check_p4_files(test_data)
    expected = False
    assert answer == expected


def test_get_GR():
    with mock.patch("Misc.read_file", return_value=["data"]):
        answer = gen_rE.get_GR(bindir + "/../data/gen_runExtract/")
        expected = ["data"]
        assert answer.design == expected
        assert answer.timing == expected


def test_print_GR():
    with mock.patch("gen_runExtract.p4_file", return_value="new/path"):
        answer = gen_rE.print_GR("")
        expected = ("new/path", "new/path")
        assert answer == expected
    pass


def test_p4_file():
    with mock.patch("Misc.run_system_cmd", return_value="new/path"):
        with mock.patch("os.path.abspath", return_value="new/path"):
            answer = gen_rE.p4_file("", "", "")
            expected = "new/path"
            assert answer == expected


def test_replace_var():
    design = ["testing PROJECT_NETLIST_PATH", "DEFAULT_MAILDIST"]
    timing = ["testing DEFAULT_MAILDIST", "PROJECT_NETLIST_PATH"]
    test_GR = gen_rE.runExtract(design, timing)
    answer = gen_rE.replace_var(test_GR, "netlist", "mail")
    expected = (["testing netlist", "mail"], ["testing mail", "netlist"])
    assert answer.design == expected[0]
    assert answer.timing == expected[1]


def test_export_files():
    test_data = gen_rE.runExtract([""], [""])
    with mock.patch("builtins.open", mock.mock_open()) as mock_open:
        gen_rE.export_runExtract(test_data, "", "")
        mock_open.assert_called()


class mock_p4():
    def __init__(self) -> None:
        self.client = ""


def test_submit_to_p4():
    p4 = mock_p4()
    with mock.patch(
        "gen_runExtract.da_p4_add_to_changelist", return_value=CH.NULL_VAL
    ):
        with pytest.raises(SystemExit, match="1"):
            gen_rE.submit_to_p4(p4, "", "", "", False)


def test_p4_connect():
    with mock.patch(
        "gen_runExtract.da_p4_create_instance", return_value=CH.NULL_VAL
    ):
        with pytest.raises(SystemExit, match="1"):
            gen_rE.p4_connect()


def test_rm_temp_files():
    args = parse_cmd_args([])
    CH.init(args, [], [])
    with mock.patch("os.path.isfile", return_value=True):
        with mock.patch("os.unlink") as mock_unlink:
            gen_rE.rm_temp_files()
            mock_unlink.assert_called()


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
