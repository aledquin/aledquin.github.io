#!/depot/Python/Python-3.8.0/bin/python

import argparse
import pathlib
import sys

import pytest
from unittest import mock
import pandas as pd

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to package.
sys.path.append(bindir + "/../../lib/python")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../../lib/python/Util")
# ---------------------------------- #

import CommonHeader as CH
import aging_pkg


@pytest.fixture(autouse=True)
def setup_teardown():
    args = parse_cmd_args([])
    CH.init(args, [], [])


def parse_cmd_args(cmd_args):
    parser = argparse.ArgumentParser(description="Test parser")
    parser.add_argument(
        "-v", metavar="<#>", type=int, default=0, help="verbosity"
    )
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")
    args = parser.parse_args(cmd_args)
    return args


def test_check_config_exists():
    with mock.patch("os.path.isfile", return_value=True):
        aging_pkg.check_config_exists("test")

    with mock.patch("os.path.isfile", return_value=False):
        with pytest.raises(SystemExit) as error:
            aging_pkg.check_config_exists("test")
        assert error.value.code == 1


def test_check_corners():
    macro = ["A", "B", "C", "D"]
    corner = ["A", "B", "C", "D"]
    df1 = pd.DataFrame({"macro": macro, "corner": corner})
    df2 = pd.DataFrame(columns=["macro", "corner"])
    aging_pkg.check_corners([df1])

    with pytest.raises(SystemExit) as error:
        aging_pkg.check_corners([df1, df2])
    assert error.value.code == 1


def test_check_high_low():
    high = "foo v125"
    low = "bar vn40"
    aging_pkg.check_high_low(high, low)

    with pytest.raises(SystemExit) as error:
        high = "foo"
        low = "bar"
        aging_pkg.check_high_low(high, low)
    assert error.value.code == 1


def test_orientation():
    macros = ["foo ns", "bar ew"]
    df = pd.DataFrame({"macro": macros})

    orient = "NS"
    answer = aging_pkg.orientation(orient, df)
    expected = pd.DataFrame({"macro": ["foo ns"]})
    pd.testing.assert_frame_equal(answer, expected)

    orient = "EW"
    answer = aging_pkg.orientation(orient, df)
    expected = pd.DataFrame({"macro": ["bar ew"]})
    pd.testing.assert_frame_equal(answer, expected)


def test_columnArrOut():
    df = pd.DataFrame(columns=["test1", "test2", "foo", "bar"])
    matches = "test"
    aging_pkg.columnArrOut(df, matches)


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
