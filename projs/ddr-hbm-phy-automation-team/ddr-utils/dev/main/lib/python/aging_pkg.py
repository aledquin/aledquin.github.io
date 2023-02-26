#!/depot/Python/Python-3.8.0/bin/python

"""
Package used by the scripts in the aging flow:
    Aging_DCD_output_pclk.py
    Aging_DCD_output_rx.py
    lifetime_analysis.py
    mpw_append.py
    ocv.py
"""

import os
import pathlib

import sys
from typing import List

import pandas as pd

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + "/../lib/Util")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../lib/python/Util")
# ---------------------------------- #

from CommonHeader import LOW, MEDIUM
from Messaging import iprint, fatal_error, dprint


def check_config_exists(config_path: str) -> None:
    """Checks if config file exists."""
    if not os.path.isfile(config_path):
        fatal_error(
            (f"Config file does not exist. '{config_path}'. Exiting...")
        )
    else:
        dprint(LOW, f"{config_path} exists. Passed...")


def check_corners(data_f: List[pd.DataFrame]) -> None:
    """Checks for empty dataframes in the tx/p/di/fclk dataframe lists."""
    for x in range(len(data_f)):
        if data_f[x].empty:
            fatal_error("Missing corner data. Exiting...")


def check_high_low(high: str, low: str) -> None:
    """Checks for typos in high_b/nb and low_b/nb."""
    if (high == "NA") or (high.endswith("v125")):
        dprint(LOW, f"{high}. Passed...")
    else:
        fatal_error(f"'{high}' does not end with 'v125'. Exiting...")

    if (low == "NA") or (low.endswith("vn40")):
        dprint(LOW, f"{low}. Passed...")
    else:
        fatal_error(f"'{low}' does not end with 'vn40'. Exiting...")


def orientation(orient: str, df: pd.DataFrame) -> pd.DataFrame:
    """Filters dataframe by orientation."""
    if orient.lower() == "ns":
        iprint("Orientation: NS")
        df = df.loc[df["macro"].str.endswith("ns")]
        df = df.reset_index(drop=True)
    elif orient.lower() == "ew":
        iprint("Orientation: EW")
        df = df.loc[df["macro"].str.endswith("ew")]
        df = df.reset_index(drop=True)
    else:
        iprint("No orientation defined!")
    return df


def columnArrOut(dataframe: pd.DataFrame, matches: str) -> List[str]:
    """Filters dataframe column names and appends them to a list."""
    array_output = []
    for columnName, columnData in dataframe.items():
        if all(x in columnName for x in matches):
            array_output.append(columnName)
    dprint(MEDIUM, f"Filtered column names: {array_output}")
    return array_output


# nolint utils__script_usage_statistics
# nolint main
