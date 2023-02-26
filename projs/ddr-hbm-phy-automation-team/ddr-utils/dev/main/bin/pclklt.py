#!/depot/Python/Python-3.8.0/bin/python

from __future__ import division, print_function
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
sys.path.append(bindir + "/../../../../sharedlib/python/Util")
# ---------------------------------- #

from Misc import utils__script_usage_statistics
from CommonHeader import LOW, HIGH
from Messaging import iprint, eprint, hprint, fatal_error, nprint
from Messaging import dprint
from Messaging import create_logger, footer, header
import CommonHeader

__author__ = ""
__version__ = "2022ww12"

utils__script_usage_statistics("pclklt", __version__)


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description="description here")
    parser.add_argument("-v", metavar="<#>", type=int, default=0, help="verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")

    # -------------------------------------
    parser.add_argument("-c", "--cfile", help="REQUIRED. Config file path", required=True)
    # -------------------------------------
    args = parser.parse_args()
    return args


#######################################
# main code for lifetime calculation
#######################################


def main(constrf, constrs, df, matches, tfresh, eollorow, eolhirow):
    array_plot = columnArrOut(df, [matches])
    if array_plot == []:
        eprint(f"No matching array found for {str(matches)}")
        fatal_error("Exiting lifetime analysis!")
        return

    keys[:] = []
    listed[:] = []
    coloutpw = len(array_plot)

    results = readinputconstr(constrf, constrs, int(tfresh), matches, eollorow, eolhirow)
    pw = findpwmin(results[0], minpw, step, results[2], results[1], coloutpw)

    stringout = matches + str(pw[0]) + "_pw"
    matches_outcal = [stringout]
    array_outcal = columnArrOut(df, matches_outcal)
    outcaldataFrameArr = [
        "mos",
        "vdd",
        "tfresh",
        "tstress",
        "toggle",
        "age_time_in_years",
    ] + array_outcal
    outc_df = df.filter(items=outcaldataFrameArr, axis=1)

    if int(tfresh) == eollo:
        outc_df = outc_df[outc_df.tfresh == eollo]
    if int(tfresh) == eolhi:
        outc_df = outc_df[outc_df.tfresh == eolhi]

    ga = (
        outc_df.groupby(["tfresh", "toggle", "vdd", "mos", "tstress"])
        .apply(lambda x: x.sort_values(["age_time_in_years"], ascending=False))
        .reset_index(drop=True)
    )

    gb = ga.groupby(["tfresh", "toggle", "vdd", "mos", "tstress"])

    df_key = pd.DataFrame(columns=("tfresh", "toggle", "vdd", "mos", "tstress"))
    df_meas = pd.DataFrame(
        columns=("age_out_years(y)", "sim_age(y)", "sim_age_margin(ps)", "bstar_margin(ps)")
    )
    group_id = -1
    for key, item in gb:
        group_id = group_id + 1
        a_group = gb.get_group(key)
        result = findage(a_group, pw[1], pw[2], bstarage)
        df_key.loc[group_id] = key
        df_meas.loc[group_id] = result
    df_outage = pd.concat([df_key, df_meas], axis=1)

    dout = pd.DataFrame(df_outage)
    dprint(HIGH, f"Output dataframe:\n{dout}")
    if matches == matches_txplot:
        csvname = str(projectname) + "txclk" + str(tfresh) + ".csv"
        nprint(f"Saving:\t {csvname}")
        dout.to_csv(csvname, index=False)
    elif matches == matches_lcdlplot:
        csvname = str(projectname) + "pclk" + str(tfresh) + ".csv"
        nprint(f"Saving:\t {csvname}")
        dout.to_csv(csvname, index=False)

    lifetime_plot(constrf, constrs, csvresult, matches, tfresh, eollorow, eolhirow, listed, keys)


# Source files to load workbook (Boost report & Non-Boost report)
# ------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------
def findpwmin(tarin, minpw, step, period, dislack, colpwout):
    pwout = round(period / 2 - dislack)
    for x in range(colpwout):

        pw = minpw + x * step
        if pw >= tarin:
            if x == 0:
                pwindex = x
            else:
                pwindex = x - 1
            pwdis = round(tarin - (minpw + pwindex * step), 2)
            pwresult = [pwindex, pwdis, pwout]
            break
    return pwresult


def columnArrOut(dataframe, matches):

    array_output = []
    for columnName, columnData in dataframe.iteritems():
        if all(x in columnName for x in matches):
            array_output.append(columnName)
    return array_output


def dataOut(dataframe, rowmatch):
    array_output = []
    array_output = dataframe.loc[
        (df["mos"] == rowmatch[0])
        & (dataframe["tfresh"] == rowmatch[1])
        & (dataframe["tstress"] == rowmatch[2])
        & (dataframe["toggle"] == rowmatch[3])
    ]
    return array_output


def linear(y1, y0, x1, x0, xt):
    # input aray with two values and find the interception of the target value between the two point
    m = (y1 - y0) / (x1 - x0)
    dprint(LOW, f"Slope: {m}")
    yt = (xt - x0) * m + y0
    return yt


def findage(df, pwdis, tarout, bstarage):
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
    bindex = -1
    for row in df.itertuples():  # loop to find bstar margin
        bindex = bindex + 1

        if str(df.at[bindex, "pout"]) != "error":
            ydis = convert4(row.pout) + pwdis - tarout

        simage = df.at[bindex, "age"]

        if simage == bstarage:
            bmargin = ydis

    return bmargin


def convert4(num):  # Converting the number to ps
    ps = float(num) * (10**12)
    rou4 = round(ps, 4)
    return rou4


def convert(num):  # Converting the number to ps
    ps = float(num) * (10**12)
    rou = round(ps)
    return rou


def readinputconstr(constrf, constrs, tfresh, matches, eollorow, eolhirow):
    dj = pd.read_excel(constrf, constrs, usecols="F,H,K,P,R,U")
    if tfresh == eollo:
        data40 = dj.iloc[int(eollorow) - 2]
        if matches == matches_txplot:
            tarin = data40[5]
            dislack = data40[4]
        elif matches == matches_lcdlplot:
            tarin = data40[2]
            dislack = data40[1]
        period = data40[0]
    elif tfresh == eolhi:

        data125 = dj.iloc[int(eolhirow) - 2]

        if matches == matches_txplot:
            tarin = data125[5]
            dislack = data125[4]
        elif matches == matches_lcdlplot:
            tarin = data125[2]
            dislack = data125[1]
        period = data125[0]
    else:
        eprint("Wrong input")
    return [tarin, dislack, period]


def find_keys(tog, ts, gdata, df_age):
    for key, item in gdata:
        c_group = gdata.get_group(key)
        if key == (tog, ts):
            min_index1 = c_group["age_out_years(y)"].idxmin()

            df_min0 = df_age.iloc[min_index1, 0]
            df_min1 = df_age.iloc[min_index1, 3]
            df_min2 = df_age.iloc[min_index1, 5]
            df_min3 = df_age.iloc[min_index1, 8]
            listed.append(df_min1)
            listed.append(df_min0)
            listed.append(ts)
            listed.append(tog)
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
            keys.append(result0)
    return [listed, keys]


def lifetime_plot(constrf, constrs, dataf, matches, tfresh, eollorow, eolhirow, listed, keys):

    count = 0
    lis_index = 0

    for key in keys:

        plotparam = [listed[count], listed[count + 1], listed[count + 2], listed[count + 3]]
        count = count + 4

        in_list = []
        df = pd.read_csv(dataf, skiprows=6)
        array_outplot = columnArrOut(df, [matches])
        outplotdataFrameArr = [
            "mos",
            "tfresh",
            "tstress",
            "toggle",
            "age_time_in_years",
        ] + array_outplot
        out_df = df.filter(items=outplotdataFrameArr, axis=1)
        outplotdata = dataOut(out_df, plotparam)

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
                if item != "error":
                    new = convert(item)
                    proper_all[i].append(new)

        for i in range(rowplot):  # finding indices of all error elements
            length = (colplot - 1) - len(proper_all[i])
            in_list_all[i] = in_list[length + 1:]  # removing error elements

        inconstr = readinputconstr(constrf, constrs, tfresh, matches, eollorow, eolhirow)
        tarin = round(inconstr[0], 2)
        dislack = inconstr[1]
        period = inconstr[2]
        pwplot = findpwmin(tarin, minpw, step, period, dislack, colplot)
        pwout = pwplot[2]
        plotmin = minpw - 10
        plotmax = minpw + 30 * step + 20
        plt.xlim(plotmin, plotmax)
        plt.ylim(0, plotmax)
        plt.axvline(x=tarin, label="Min pulse width in = " + str(tarin), color="aquamarine")
        plt.hlines(
            y=pwout, xmin=tarin, xmax=110, label="Min pulse width out = " + str(pwout), color="y"
        )

        for i in range(rowplot):  # finding indices of all error elements

            plt.scatter(in_list_all[i], proper_all[i])
            plt.plot(
                in_list_all[i], proper_all[i], label="Age = " + str(df.at[i, "age_time_in_years"])
            )

        plt.legend(loc="lower right", prop={"size": 8})
        # plt.figtext()
        plt.xlabel("Input Pulse Width (ps)")
        plt.ylabel("Output Pulse Width (ps)")

        EOL = "EOL " + str(listed[lis_index + 1])
        tstress = "tstress " + str(listed[lis_index + 2])
        toggle = "toggle " + str(listed[lis_index + 3])
        name = matches + "_" + EOL + "_" + tstress + "_" + toggle

        plt.title(str(key))
        filename = str(projectname) + str(name) + ".png"
        nprint(f"Saving:\t {filename}")
        plt.savefig(filename, dpi=200)
        plt.close()

        lis_index = lis_index + 4

        name = " "


def check_config_path(args):
    if not os.path.isfile(args.cfile):
        fatal_error(f'Config file "{args.cfile}" not found. Exiting...')
        sys.exit(1)
    else:
        dprint(LOW, f'Config file "{args.cfile}" found')


def parse_config(args):
    global projectname
    global eolhi
    global eollo
    global ap2temp
    global emtemp
    global automotive
    global contarage
    global ap2age
    global minpw
    global step
    global constrf
    global constrs
    global eollorow
    global eolhirow

    config = configparser.ConfigParser()
    config.read(args.cfile)
    for section in config.sections():
        if section.lower() == "pclk":
            projectname = config[section]["projectname"]
            eolhi = int(config[section]["eolhi"])
            eollo = int(config[section]["eollo"])
            ap2temp = int(config[section]["ap2temp"])
            emtemp = int(config[section]["emtemp"])
            automotive = int(config[section]["automotive"])
            contarage = int(config[section]["contarage"])
            ap2age = int(config[section]["ap2age"])
            minpw = int(config[section]["minpw"])
            step = int(config[section]["step"])
            constrf = config[section]["constrf"]
            constrs = config[section]["constrs"]
            eollorow = int(config[section]["eollorow"])
            eolhirow = int(config[section]["eolhirow"])
            break
        else:
            fatal_error("[PCLK] section not found in config file. Exiting...")
            sys.exit(1)


# ======================================================================
# Project information (Sample):
# ======================================================================
projectname = "d900"  # project name
eolhi = 125  # define EOL for high temp
eollo = -40  # define EOL for low temp
ap2temp = 105  # define ap2 temp
emtemp = 105  # define em temp
csvresult = (
    "../d900pclk.csv"  # aging simulation results
)
automotive = 0  # define whether if the project is automotive or non-automotive (1 – automotive, 0 – non-automotive)
contarage = 10  # define passing age for non-automotive project
ap2age = 1  # define passing age for automotive project
minpw = 75  # minimum simulated input pulse width for input pulse train
step = 2  # step size for input pulse train
constrf = "../dislack/d900DISLACK.xlsx"  # Timing constraint file
constrs = "d900DI"  # Tab/worksheet for timing constraint
eollorow = 12  # constraint row for EOL low temp
eolhirow = 11  # constraint row for EOL hi temp
# =======================================================================

args = parse_args()

filename = os.getcwd() + "/" + os.path.basename(__file__) + ".log"
logger = create_logger(filename)  # Create log file

# Register exit function
atexit.register(footer)

# Initalise shared variables and run main
CommonHeader.init(args, __author__, __version__)

header()

check_config_path(args)
parse_config(args)

df = pd.read_csv(csvresult, skiprows=6)
keys = []
listed = []
matches_txplot = "txclk_dqs_pn"
matches_lcdlplot = "lcdl_in_pn"
if automotive == 0:
    bstarage = contarage
    key2temp = emtemp
else:
    bstarage = ap2age
    key2temp = ap2temp

main(constrf, constrs, df, matches_lcdlplot, eolhi, eollorow, eolhirow)
main(constrf, constrs, df, matches_lcdlplot, eollo, eollorow, eolhirow)
main(constrf, constrs, df, matches_txplot, eolhi, eollorow, eolhirow)
main(constrf, constrs, df, matches_txplot, eollo, eollorow, eolhirow)
iprint(f"Log file: {filename}")
