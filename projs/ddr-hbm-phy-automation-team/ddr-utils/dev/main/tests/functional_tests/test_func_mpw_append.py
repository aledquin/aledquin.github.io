#!/depot/Python/Python-3.8.0/bin/python

import os
import pathlib
import sys

import pytest

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to script.
sys.path.append(bindir + "/../../bin")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../../lib/python/Util")
# ---------------------------------- #

import Misc
import mpw_append as mpw

_data = bindir + "/../data/mpw_append"
_script = bindir + "/../bin/mpw_append.py"


@pytest.fixture(autouse=True)
def teardown():
    yield
    if os.path.isfile(_data + "/func_test_MPW.csv"):
        os.unlink(_data + "/func_test_MPW.csv")
    if os.path.isfile(_data + "/func_test_MPW.xlsx"):
        os.unlink(_data + "/func_test_MPW.xlsx")


@pytest.fixture(autouse=True, scope="session")
def args_():
    # temp storage for argv since tests change it for cmd line parsing
    temp_argv = sys.argv[1:]
    yield
    sys.argv[1:] = temp_argv


def run_test(cmd):
    sys.argv[1:] = cmd
    args = mpw.parse_args()
    mpw.main(args)


def test_mpw_append():
    """Local file path test"""
    input1 = os.path.abspath(_data + "/test1.csv")
    input2 = os.path.abspath(_data + "/test2.csv")
    cmd_line = ["-i", input1, input2, "-n", "func_test_MPW.csv", "-o", _data, "--overwrite"]
    run_test(cmd_line)

    compare = "diff " + _data + "/func_test_MPW.csv " + _data + "/MPW_KGR.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0


def test_mpw_append_p4():
    """P4 path and excel output test. Due to the nature of P4 files changing, file existence check only"""
    p4_path = "//depot/products/lpddr5x_ddr5_phy/lp5x/project/d930-lpddr5x-tsmc5ff12/ckt/rel/dwc_lpddr5xphy_ato_ew/3.00a/macro/pininfo/"
    cmd_line = ["-i", p4_path, (p4_path + "dwc_lpddr5xphy_ato_ew.csv"), "-n", "func_test_MPW.xlsx", "-o", _data, "--overwrite", "--excel"]
    run_test(cmd_line)

    assert os.path.exists(_data + "/func_test_MPW.xlsx")


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
