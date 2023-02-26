#!/depot/Python/Python-3.8.0/bin/python
"""
Name    : lifetime_analysis.py
Author  : Angelina Chan
Date    : Jan 10, 2023
Purpose : Generates PCLK or RXCLK lifetime plots
"""

import logging
from typing import List
import pandas as pd
import matplotlib.pyplot as plt
import math
import pathlib
import sys
import os
import argparse
import configparser
import atexit

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + "/../lib/Util")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../lib/python/Util")
# Add path to Aging package directory.
sys.path.append(bindir + "/../lib/python")
# ---------------------------------- #

from Misc import utils__script_usage_statistics, get_release_version
from CommonHeader import LOW, MEDIUM, HIGH
from Messaging import iprint, eprint, hprint, fatal_error, nprint
from Messaging import dprint
from Messaging import create_logger, footer, header
import CommonHeader

import aging_pkg

__author__ = "Angelina Chan"
__tool_name__ = "lifetime_analysis"


def parse_args() -> argparse.ArgumentParser:

    # Always include -v, and -d
    parser = argparse.ArgumentParser(
        description="Script for pclk and rxclk lifetime analysis plots."
    )
    parser.add_argument(
        "-v", metavar="<#>", type=int, default=0, help="verbosity"
    )
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")

    # -------------------------------------
    parser.add_argument(
        "-c",
        "--cfile",
        metavar="<PATH>",
        help="REQUIRED. Config file path",
        required=True,
    )
    # -------------------------------------
    args = parser.parse_args()
    return args


#######################################
# main code for lifetime calculation
#######################################
def main(args: argparse.ArgumentParser):
    aging_pkg.check_config_exists(args.cfile)
    data_list = parse_config(args)
    for data in data_list:
        nprint(f"[{data.section} - {data.projectname}]")
        if not os.path.isfile(data.csvresult):
            fatal_error(f"File not found, '{data.csvresult}'. Exiting...")
        check_dir(data.output)
        df = pd.read_csv(data.csvresult, skiprows=6)

        lifetime(data, df, data.matches_2plot, data.eolhi)
        lifetime(data, df, data.matches_2plot, data.eollo)
        lifetime(data, df, data.matches_1plot, data.eolhi)
        lifetime(data, df, data.matches_1plot, data.eollo)


# Class to store parameters from config file
class lifetimeData:
    """Class to store parameters from config file"""

    def __init__(
        self,
        section: str,
        projectname: str,
        eolhi: int,
        eollo: int,
        ap2temp: int,
        emtemp: int,
        csvresult: str,
        automotive: int,
        contarage: int,
        ap2age: int,
        minpw: int,
        step: int,
        constrf: str,
        constrs: str,
        eollorow: int,
        eolhirow: int,
        key1: str,
        key2: str,
        key3: str,
        output: str,
    ):
        self.section = section
        self.projectname = projectname
        self.eolhi = eolhi
        self.eollo = eollo
        self.ap2temp = ap2temp
        self.emtemp = emtemp
        self.csvresult = csvresult
        self.automotive = automotive
        self.contarage = contarage
        self.ap2age = ap2age
        self.minpw = minpw
        self.step = step
        self.constrf = constrf
        self.constrs = constrs
        self.eollorow = eollorow
        self.eolhirow = eolhirow

        self.key1 = key1
        self.key2 = key2
        self.key3 = key3

        self.output = output
        if "pclk" in section.lower():
            self.matches_1plot = "txclk_dqs_pn"
            self.matches_2plot = "lcdl_in_pn"
        elif "rx" in section.lower():
            self.matches_1plot = "rxclk_dqrxflop_pn"
            self.matches_2plot = "rxclk_outdi_pn"
        else:
            fatal_error("No RX or PCLK in config sections.")

        if automotive == 0:
            self.bstarage = contarage
            self.key2temp = emtemp
        else:
            self.bstarage = ap2age
            self.key2temp = ap2temp

        self.keys = []
        self.listed = []


def lifetime(data: lifetimeData, df: pd.DataFrame, matches: str, tfresh: int):
    dprint(LOW, f"matches: {matches}")
    array_plot = aging_pkg.columnArrOut(df, [matches])
    if array_plot == []:
        eprint(f"No matching array found for {str(matches)}")
        fatal_error("Exiting lifetime analysis!")
        return

    data.keys[:] = []
    data.listed[:] = []
    coloutpw = len(array_plot)

    results = readinputconstr(data, int(tfresh), matches)
    pw = findpwmin(results[0], data, results[2], results[1], coloutpw)
    dprint(MEDIUM, f"Pulse Width: {pw[0]}")
    stringout = matches + str(pw[0]) + "_pw"
    matches_outcal = [stringout]
    array_outcal = aging_pkg.columnArrOut(df, matches_outcal)
    outcaldataFrameArr = [
        "mos",
        "vdd",
        "tfresh",
        "tstress",
        "toggle",
        "age_time_in_years",
    ] + array_outcal
    outc_df = df.filter(items=outcaldataFrameArr, axis=1)

    if int(tfresh) == data.eollo:
        outc_df = outc_df[outc_df.tfresh == data.eollo]
    elif int(tfresh) == data.eolhi:
        outc_df = outc_df[outc_df.tfresh == data.eolhi]

    ga = (
        outc_df.groupby(["tfresh", "toggle", "vdd", "mos", "tstress"])
        .apply(lambda x: x.sort_values(["age_time_in_years"], ascending=False))
        .reset_index(drop=True)
    )

    gb = ga.groupby(["tfresh", "toggle", "vdd", "mos", "tstress"])

    df_key = pd.DataFrame(columns=("tfresh", "toggle", "vdd", "mos", "tstress"))
    df_meas = pd.DataFrame(
        columns=(
            "age_out_years(y)",
            "sim_age(y)",
            "sim_age_margin(ps)",
            "bstar_margin(ps)",
        )
    )
    group_id = -1
    for key, item in gb:
        group_id = group_id + 1
        a_group = gb.get_group(key)
        dprint(MEDIUM, f"key: {key}")
        result = findage(a_group, pw[1], pw[2], data.bstarage)
        df_key.loc[group_id] = key
        df_meas.loc[group_id] = result
    df_outage = pd.concat([df_key, df_meas], axis=1)
    gc = df_outage.groupby(["toggle", "tstress"])
    # find_keys(0, 85, gc, df_outage)  # key 1
    # find_keys(2, key2temp, gc, df_outage)  # key 2
    # find_keys(3, eollo, gc, df_outage)  # key 3
    tg, ts = parse_key(data, data.key1)
    dprint(MEDIUM, f"{data.key1}")
    dprint(MEDIUM, f"KEY1: {tg}, {ts}")
    find_keys(data, tg, ts, gc, df_outage)  # key 1
    tg, ts = parse_key(data, data.key2)
    dprint(MEDIUM, f"{data.key2}")
    dprint(MEDIUM, f"KEY2: {tg}, {ts}")
    find_keys(data, tg, ts, gc, df_outage)  # key 2
    tg, ts = parse_key(data, data.key3)
    dprint(MEDIUM, f"{data.key3}")
    dprint(MEDIUM, f"KEY3: {tg}, {ts}")
    find_keys(data, tg, ts, gc, df_outage)  # key 3

    dout = pd.DataFrame(df_outage)
    dprint(HIGH, f"Output dataframe:\n{dout}")
    export_csv(data, dout, matches, tfresh)

    lifetime_plot(data, matches, tfresh)


# Source files to load workbook (Boost report & Non-Boost report)
# ------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------
def findpwmin(tarin, data: lifetimeData, period, dislack, colpwout):
    """Function to find minimum pulse width from the timing constraint file"""
    found = False
    pwout = round(period / 2 - dislack)
    for x in range(colpwout):
        pw = data.minpw + x * data.step
        dprint(HIGH, f"Pulse Width: {pw}, Tarin: {tarin}")
        if pw >= tarin:
            if x == 0:
                pwindex = x
            else:
                pwindex = x - 1
            pwdis = round(tarin - (data.minpw + pwindex * data.step), 2)
            pwresult = [pwindex, pwdis, pwout]
            found = True
            break
    if not found:
        pw = data.minpw + (colpwout - 1) * data.step
        eprint(
            "Minimum pulse width from the timing constraint file NOT FOUND\n"
            f"'minpw + x * step' is less than 'Minimum PW at input': "
            f"{pw} < {tarin}"
        )
        fatal_error(
            "Please check:\nThe timing constraint file - Minimum PW at input"
            "\nThe config file - minpw and step"
        )
    return pwresult


def dataOut(df, dataframe, rowmatch):
    array_output = []
    array_output = dataframe.loc[
        (df["mos"] == rowmatch[0])
        & (dataframe["tfresh"] == rowmatch[1])
        & (dataframe["tstress"] == rowmatch[2])
        & (dataframe["toggle"] == rowmatch[3])
    ]
    return array_output


def linear(y1, y0, x1, x0, xt):
    """Input array with two values and find the interception
    of the target value between the two points"""
    m = (y1 - y0) / (x1 - x0)
    dprint(LOW, f"Slope: {m}")
    yt = (xt - x0) * m + y0
    return yt


def findage(df, pwdis, tarout, bstarage):
    """Find age"""
    df = df.drop(df.columns[[0, 1, 2, 3, 4]], axis=1)
    df = df.reset_index(drop=True)
    df = df.rename(columns={df.columns[0]: "age", df.columns[1]: "pout"})

    df = df.drop(df[df.pout == "error"].index)
    df = df.reset_index(drop=True)
    dprint(HIGH, f"findage dataframe:\n{df}")
    rowcount = len(df.index)
    maxage = df.at[0, "age"]
    index = -1
    ydis = -999
    bmargin = -999

    bmargin = bstar_margin(df, bstarage, pwdis, tarout)

    for row in df.itertuples():  # loop to find age

        index = index + 1

        if str(df.at[index, "pout"]) != "error":
            ydis = convert4(row.pout) + pwdis - tarout

        simage = df.at[index, "age"]
        if ydis > 0:
            if rowcount == 1:
                hprint("only passes fresh")
                ageout = simage
                break
            if simage == maxage:
                ageout = simage
            else:
                index1 = index
                index0 = index - 1
                age0 = df.at[index0, "age"]
                pout0 = convert4(df.at[index0, "pout"]) + pwdis
                age1 = df.at[index1, "age"]
                pout1 = convert4(df.at[index1, "pout"]) + pwdis
                ageout = linear(age0, age1, pout0, pout1, tarout)
            if math.isinf(ageout):
                ageout = simage
            if simage == maxage and abs(ageout) > simage:
                ageout = simage
            break
        elif ydis == 0:
            ageout = simage
            hprint("ydis==0")
            break
        elif ydis < 0 and simage == 0:
            # set age = -1 if it fails fresh
            ageout = -1
            hprint("doesn't pass fresh setting ageout=-1")
    ageout = round(ageout, 2)

    ydis = round(ydis, 2)
    bmargin = round(bmargin, 2)
    ageresult = [ageout, simage, ydis, bmargin]
    return ageresult


def bstar_margin(df, bstarage, pwdis, tarout):
    """Function to find bstar margin"""
    bindex = -1
    bmargin = -999
    ydis = -999
    for row in df.itertuples():  # loop to find bstar margin
        bindex = bindex + 1

        if str(df.at[bindex, "pout"]) != "error":
            ydis = convert4(row.pout) + pwdis - tarout

        simage = df.at[bindex, "age"]
        dprint(LOW, f"Simage: {simage}\tBstarage: {bstarage}")
        if simage == bstarage:
            bmargin = ydis

    return bmargin


def convert4(num):
    """Converting the number to ps, round to 4 decimal places"""
    ps = float(num) * (10**12)
    rou4 = round(ps, 4)
    return rou4


def convert(num):
    """Converting the number to ps, no rounding"""
    ps = float(num) * (10**12)
    rou = round(ps)
    return rou


def readinputconstr(data: lifetimeData, tfresh, matches):
    """Read the input timing constraint file and find the tarin,
    dislack and period"""
    dj = pd.read_excel(data.constrf, data.constrs, usecols="F,H,K,P,R,U")
    dprint(MEDIUM, f"DJ\n{dj}")
    dprint(LOW, f"Tfresh: {tfresh}")
    if tfresh == data.eollo:
        dprint(LOW, "Tfresh: EOLLO")
        data40 = dj.iloc[int(data.eollorow) - 2]
        if matches == data.matches_1plot:
            tarin = data40[5]
            dislack = data40[4]
        elif matches == data.matches_2plot:
            tarin = data40[2]
            dislack = data40[1]
        period = data40[0]
    elif tfresh == data.eolhi:
        dprint(LOW, "Tfresh: EOLHI")
        data125 = dj.iloc[int(data.eolhirow) - 2]

        if matches == data.matches_1plot:
            tarin = data125[5]
            dislack = data125[4]
        elif matches == data.matches_2plot:
            tarin = data125[2]
            dislack = data125[1]
        period = data125[0]
    else:
        eprint(
            "Incorrect input. "
            "Please check the config and input timing constraint file."
        )
    return [tarin, dislack, period]


def find_keys(data, tog, ts, gdata, df_age):
    """Find the keys used for plotting the lifetime analysis"""
    dprint(LOW, f"Toggle, tstress: {tog}, {ts}")
    for key, item in gdata:
        dprint(HIGH, f": {key}")
        c_group = gdata.get_group(key)
        dprint(MEDIUM, f"Equal? {key == (tog, ts)}")
        if key == (tog, ts):
            min_index1 = c_group["age_out_years(y)"].idxmin()

            df_min0 = df_age.iloc[min_index1, 0]
            df_min1 = df_age.iloc[min_index1, 3]
            df_min2 = df_age.iloc[min_index1, 5]
            df_min3 = df_age.iloc[min_index1, 8]
            data.listed.append(df_min1)
            data.listed.append(df_min0)
            data.listed.append(ts)
            data.listed.append(tog)
            result0 = (
                "EOL="
                + str(df_min0)
                + "C "
                + " "
                + str(df_min1)
                + " "
                + "age="
                + str(df_min2)
                + "yrs "
                + "bstar margin="
                + str(df_min3)
                + "ps"
            )
            data.keys.append(result0)
    dprint(LOW, f"KEYS: {data.keys}")


def export_csv(data, dout, matches, tfresh):
    """Export the csv file containing the lifetime data"""
    if "pclk" in data.section.lower():
        name1 = "txclk"
        name2 = "pclk"
    else:
        name1 = "rxflop"
        name2 = "rxoutdi"
    if matches == data.matches_1plot:
        csvname = str(data.projectname) + name1 + str(tfresh) + ".csv"
        path = os.path.join(data.output, csvname)
        nprint(f"Saving:\t{csvname} to {os.path.abspath(data.output)}")
        dout.to_csv(path, index=False)
    elif matches == data.matches_2plot:
        csvname = str(data.projectname) + name2 + str(tfresh) + ".csv"
        path = os.path.join(data.output, csvname)
        nprint(f"Saving:\t{csvname} to {os.path.abspath(data.output)}")
        dout.to_csv(path, index=False)


def lifetime_plot(data: lifetimeData, matches, tfresh):
    """Generates the lifetime analysis plots"""
    dataf = data.csvresult
    dprint(LOW, "Plotting...")
    count = 0
    lis_index = 0
    dprint(MEDIUM, f"Keys: {data.keys}")
    for key in data.keys:
        dprint(MEDIUM, f"Key: {key}")
        plotparam = [
            data.listed[count],
            data.listed[count + 1],
            data.listed[count + 2],
            data.listed[count + 3],
        ]
        count = count + 4

        in_list = []
        df = pd.read_csv(dataf, skiprows=6)
        array_outplot = aging_pkg.columnArrOut(df, [matches])
        outplotdataFrameArr = [
            "mos",
            "tfresh",
            "tstress",
            "toggle",
            "age_time_in_years",
        ] + array_outplot
        out_df = df.filter(items=outplotdataFrameArr, axis=1)
        outplotdata = dataOut(df, out_df, plotparam)

        colplot = len(outplotdata.columns) - 5
        rowplot = len(outplotdata.index)

        dn = pd.read_csv(dataf)

        dict = {}  # Dictionary that has all the input pulse widths to plot

        for i in range(colplot):
            cell_value_class = dn.iloc[2][i]
            cell_value_id = dn.iloc[3][i]
            cell_value_id = convert(cell_value_id)
            in_list.append(cell_value_id)  # list of all the input pulse width
            dict[cell_value_class] = cell_value_id

        proper_all = []  # lists of all output widths for different ages
        in_list_all = []  # lists of all input widths for different ages
        for i in range(rowplot):
            # In each iteration, add an empty list to the MAIN list
            proper_all.append([])
            in_list_all.append([])
            in_list_all[i] = in_list

        # FINDING LISTS OF OUTPUT PULSE WIDTHS FOR ALL AGES

        for i in range(rowplot):
            temp = outplotdata.iloc[i]

            third = temp[(rowplot + 1):]

            for item in third:
                if item != "error" and not pd.isnull(item):
                    dprint(HIGH, f"ITEM: {item}")
                    dprint(HIGH, f"ITEM: {type(item)}")
                    new = convert(item)
                    proper_all[i].append(new)

        for i in range(rowplot):  # finding indices of all error elements
            length = (colplot - 1) - len(proper_all[i])
            in_list_all[i] = in_list[length + 1:]  # removing error elements

        inconstr = readinputconstr(data, tfresh, matches)
        tarin = round(inconstr[0], 2)
        dislack = inconstr[1]
        period = inconstr[2]
        pwplot = findpwmin(tarin, data, period, dislack, colplot)
        pwout = pwplot[2]
        plotmin = data.minpw - 10
        plotmax = data.minpw + 30 * data.step + 20
        plt.xlim(plotmin, plotmax)
        plt.ylim(0, plotmax)
        plt.axvline(
            x=tarin,
            label="Min pulse width in = " + str(tarin),
            color="aquamarine",
        )
        plt.hlines(
            y=pwout,
            xmin=tarin,
            xmax=110,
            label="Min pulse width out = " + str(pwout),
            color="y",
        )

        for i in range(rowplot):  # finding indices of all error elements

            plt.scatter(in_list_all[i], proper_all[i])
            plt.plot(
                in_list_all[i],
                proper_all[i],
                label="Age = " + str(df.at[i, "age_time_in_years"]),
            )

        plt.legend(loc="lower right", prop={"size": 8})
        # plt.figtext()
        plt.xlabel("Input Pulse Width (ps)")
        plt.ylabel("Output Pulse Width (ps)")

        EOL = "EOL " + str(data.listed[lis_index + 1])
        tstress = "tstress " + str(data.listed[lis_index + 2])
        toggle = "toggle " + str(data.listed[lis_index + 3])
        name = matches + "_" + EOL + "_" + tstress + "_" + toggle

        plt.title(str(key))
        file = str(data.projectname) + str(name) + ".png"
        path = os.path.join(data.output, file)
        nprint(f"Saving:\t{file} to {os.path.abspath(data.output)}")
        plt.savefig(path, dpi=200)
        plt.close()

        lis_index = lis_index + 4

        name = " "


def check_dir(path):
    """Check if the directory exists"""
    if not os.path.isdir(path):
        fatal_error(f'Directory "{path}" not found. Exiting...')
    else:
        dprint(LOW, f'Directory "{path}" found')


def parse_key(data: lifetimeData, key: str):
    """Extracts toggle and tstress from the config string"""
    toggle = key.split(",")[0]
    tstress = key.split(",")[1]
    if toggle.lower() == "emtemp":
        toggle = data.key2temp
    elif toggle.lower() == "ap2temp":
        toggle = data.ap2temp
    else:
        try:
            toggle = int(toggle)
        except ValueError:
            fatal_error(f"Toggle, {toggle}, is not emtemp or an integer")

    if tstress.lower() == "eollo":
        tstress = data.eollo
    elif tstress.lower() == "eolhi":
        tstress = data.eolhi
    else:
        try:
            tstress = int(tstress)
        except ValueError:
            fatal_error(f"Tstress, {tstress}, is not eollo/eolhi or an integer")
    return toggle, tstress


def parse_config(args: argparse.ArgumentParser) -> List[lifetimeData]:
    """Parses the config file"""
    """
    # ======================================================================
    # Project information (Sample config):
    # ======================================================================
    [D900 - PCLK]
    projectname = d900  # project name
    eolhi = 125  # define EOL for high temp
    eollo = -40  # define EOL for low temp
    ap2temp = 105  # define ap2 temp
    emtemp = 105  # define em temp
    csvresult = d900pclk.csv  # aging simulation results
    automotive = 0  # define whether if the project is automotive or non-automotive
    contarage = 10  # define passing age for non-automotive project
    ap2age = 1  # define passing age for automotive project
    minpw = 75  # minimum simulated input pulse width for input pulse train
    step = 2  # step size for input pulse train
    constrf = dislack/d900DISLACK.xlsx  # Timing constraint file
    constrs = d900DI  # Tab/worksheet for timing constraint
    eollorow = 12  # constraint row for EOL low temp
    eolhirow = 11  # constraint row for EOL hi temp
    key1 = 0,85  # which toggle to plot at which tstress (toggle, tstress)
    key2 = 2,105
    key3 = 3,-40
    output = .  # output directory path for the plot and csv files
    # ======================================================================
    """
    data_list = []
    config = configparser.ConfigParser()
    config.read(args.cfile)
    for section in config.sections():
        projectname = config[section]["projectname"]
        eolhi = int(config[section]["eolhi"])
        eollo = int(config[section]["eollo"])
        ap2temp = int(config[section]["ap2temp"])
        emtemp = int(config[section]["emtemp"])
        csvresult = config[section]["csvresult"]
        automotive = int(config[section]["automotive"])
        contarage = int(config[section]["contarage"])
        ap2age = int(config[section]["ap2age"])
        minpw = int(config[section]["minpw"])
        step = int(config[section]["step"])
        constrf = config[section]["constrf"]
        constrs = config[section]["constrs"]
        eollorow = int(config[section]["eollorow"])
        eolhirow = int(config[section]["eolhirow"])
        key1 = config[section]["key1"]
        key2 = config[section]["key2"]
        key3 = config[section]["key3"]
        output = config[section]["output"]
        data = lifetimeData(
            section,
            projectname,
            eolhi,
            eollo,
            ap2temp,
            emtemp,
            csvresult,
            automotive,
            contarage,
            ap2age,
            minpw,
            step,
            constrf,
            constrs,
            eollorow,
            eolhirow,
            key1,
            key2,
            key3,
            output,
        )
        data_list.append(data)
    return data_list


if __name__ == "__main__":
    args = parse_args()
    RealScript = os.path.basename(__file__)
    file = os.getcwd() + "/" + os.path.basename(__file__) + ".log"
    logger = create_logger(file)  # Create log file
    # Disable matplotlib.font_manager logging
    # Logging is set to DEBUG and font_manager clutters debug level logging
    logging.getLogger("matplotlib.font_manager").disabled = True
    # Register exit function
    atexit.register(footer)

    # Initalise shared variables and run main
    version = get_release_version()
    CommonHeader.init(args, __author__, version)

    header()
    main(args)
    iprint(f"Log file: {file}")
    utils__script_usage_statistics(RealScript, version)
