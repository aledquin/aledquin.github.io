#!/depot/Python/Python-3.8.0/bin/python

import configparser
import os
import pathlib
import sys
import glob

import pytest

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to script.
sys.path.append(bindir + "/../../bin")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../../lib/python/Util")
# ---------------------------------- #

import Misc
import lifetime_analysis

_data = bindir + "/../data/lifetime_analysis"
_script = bindir + "/../bin/lifetime_analysis.py"


@pytest.fixture(autouse=True)
def setup_teardown():
    yield
    for fname in os.listdir(_data):
        if fname.startswith('test_d') and fname.endswith(('.png', '.csv')):
            os.unlink(os.path.join(_data, fname))
    if os.path.isfile(_data + "/edited_config.ini"):
        os.unlink(_data + "/edited_config.ini")


@pytest.fixture(autouse=True, scope="session")
def args_():
    # temp storage for argv since tests change it for cmd line parsing
    temp_argv = sys.argv[1:]
    yield
    sys.argv[1:] = temp_argv


def edit_config(config_file):
    """Need to dynamically change the file paths in the config"""
    config = configparser.ConfigParser()
    config.read(config_file)

    for project in config.sections():
        csvresult = config[project]["csvresult"]
        constrf = config[project]["constrf"]
        config[project]["csvresult"] = os.path.abspath(os.path.join(_data, csvresult))
        config[project]["constrf"] = os.path.abspath(os.path.join(_data, constrf))
        config[project]["output"] = os.path.abspath(_data)

    # NOTE: Misc.write_file() ruins config file format, must use 'with open(...)'
    with open((_data + "/edited_config.ini"), 'w') as configfile:
        config.write(configfile)


def run_test(config):
    config_path = os.path.join(_data, config)
    edit_config(config_path)
    config_path = os.path.join(_data, "edited_config.ini")
    sys.argv[1:] = ["-c", config_path]
    args = lifetime_analysis.parse_args()
    lifetime_analysis.main(args)


def test_lifetime_analysis_pclk():
    """test 1: d932 0p75 PCLK"""
    config_file = "config_d932_pclk.ini"
    run_test(config_file)

    # PCLK
    kgrPng = len(glob.glob(_data + "/pclk/0p75/d932*.png"))
    testPng = len(glob.glob(_data + "/test_d9320p75*.png"))
    assert testPng == kgrPng

    compare = "diff " + _data + "/test_d9320p75pclk-40.csv " + _data + "/pclk/0p75/d9320p75pclk-40.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0
    compare = "diff " + _data + "/test_d9320p75pclk125.csv " + _data + "/pclk/0p75/d9320p75pclk125.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0
    compare = "diff " + _data + "/test_d9320p75txclk-40.csv " + _data + "/pclk/0p75/d9320p75txclk-40.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0
    compare = "diff " + _data + "/test_d9320p75txclk125.csv " + _data + "/pclk/0p75/d9320p75txclk125.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0


def test_lifetime_analysis_rx():
    """test 2: d932 0p75 RX"""
    config_file = "config_d932_rx.ini"
    run_test(config_file)

    # RX
    kgrPng = len(glob.glob(_data + "/rxclk/0p75/d932*.png"))
    testPng = len(glob.glob(_data + "/test_d932rx0p75*.png"))
    assert testPng == kgrPng

    compare = "diff " + _data + "/test_d932rx0p75rxflop-40.csv " + _data + "/rxclk/0p75/d932rx0p75rxflop-40.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0
    compare = "diff " + _data + "/test_d932rx0p75rxflop125.csv " + _data + "/rxclk/0p75/d932rx0p75rxflop125.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0
    compare = "diff " + _data + "/test_d932rx0p75rxoutdi-40.csv " + _data + "/rxclk/0p75/d932rx0p75rxoutdi-40.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0
    compare = "diff " + _data + "/test_d932rx0p75rxoutdi125.csv " + _data + "/rxclk/0p75/d932rx0p75rxoutdi125.csv"
    diff_exitcode = Misc.run_system_cmd(compare, 0)[2]
    assert diff_exitcode == 0


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
