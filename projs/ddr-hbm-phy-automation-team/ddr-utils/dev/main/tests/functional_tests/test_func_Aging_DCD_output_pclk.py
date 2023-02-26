#!/depot/Python/Python-3.8.0/bin/python

import configparser
import os
import pathlib
import sys

import pytest
import pandas as pd

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to script.
sys.path.append(bindir + "/../../bin")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../../lib/python/Util")
# ---------------------------------- #

import Misc
import Aging_DCD_output_pclk

_data = bindir + "/../data/Aging_DCD_output"
_script = bindir + "/../bin/Aging_DCD_output_pclk.py"


@pytest.fixture(autouse=True)
def setup_teardown():
    cpy = "cp " + _data + "/TEMPLATE/d932DISLACK.xlsx " + _data
    if os.path.isfile(_data + "/d932DISLACK.xlsx"):
        os.unlink(_data + "/d932DISLACK.xlsx")
    if os.path.isfile(_data + "/TEMPLATE/d932DISLACK.xlsx"):
        Misc.run_system_cmd(cpy, 0)
    yield
    if os.path.isfile(_data + "/d932DISLACK.xlsx"):
        os.unlink(_data + "/d932DISLACK.xlsx")
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
        MPWinput_wb = config[project]["MPWinput_wb"]
        DCDoutput_wb = config[project]["DCDoutput_wb"]
        mc_data_nb = config[project]["mc_data_nb"]
        mc_data_b = config[project]["mc_data_b"]
        config[project]["MPWinput_wb"] = os.path.abspath(os.path.join(_data, MPWinput_wb))
        config[project]["DCDoutput_wb"] = os.path.abspath(os.path.join(_data, DCDoutput_wb))
        config[project]["mc_data_nb"] = os.path.abspath(os.path.join(_data, mc_data_nb))
        config[project]["mc_data_b"] = os.path.abspath(os.path.join(_data, mc_data_b))

    # NOTE: Misc.write_file() ruins config file format, must use 'with open(...)'
    with open((_data + "/edited_config.ini"), 'w') as configfile:
        config.write(configfile)


def run_test(config):
    config_path = os.path.join(_data, config)
    edit_config(config_path)
    config_path = os.path.join(_data, "edited_config.ini")
    sys.argv[1:] = ["-c", config_path]
    args = Aging_DCD_output_pclk.parse_args()
    Aging_DCD_output_pclk.main(args)


def test_Aging_DCD_output_pclk():
    """test 1: d932"""
    config_file = "config_d932_pclk.ini"
    run_test(config_file)

    dfPclk = pd.read_excel(_data + "/d932DISLACK.xlsx", sheet_name=0)
    kgrPclk = pd.read_excel(_data + "/d932DISLACK_KGR.xlsx", sheet_name=0)
    equal = dfPclk.equals(kgrPclk)
    assert equal


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
