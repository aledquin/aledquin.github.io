#!/depot/Python/Python-3.8.0/bin/python -BE
# Read vflags from cdl files

from __future__ import division, print_function, absolute_import

import argparse
import collections
import os
import re
import xlsxwriter


def utils__script_usage_statistics(toolname, version):
    prefix = 'ddr-da-ddr-utils-'
    reporter = '/remote/cad-rep/msip/tools/bin/msip_get_usage_info'
    cmd = [reporter, '--tool_name', prefix + toolname, '--stage', 'main',
           '--category', 'ude_ext_1', '--tool_path', 'NA', '--tool_version', version]
    cmd = reporter + ' --tool_name ' + prefix + toolname + ' --stage ' + ' main ' + \
        ' --category ' + ' ude_ext_1 ' + ' --tool_path ' + \
        ' NA ' + ' --tool_version ' + version
    os.system(cmd)


fields = 'filename library subckt name net v vhigh vhigh_int vlow vlow_int higheq loweq unique'.split()

Row = collections.namedtuple('Row', fields)


def detect_ends(line, lib, subckt):
    """Detect .ends"""
    m = re.match(r'\.ends', line, flags=re.I)
    if m:
        assert subckt is not None
        words = line.split()
        if len(words) > 1:
            assert words[1] == subckt

        lib = None
        subckt = None
    return lib, subckt


def get_vflags(filename, tags):

    # Read entire file into memory
    with open(filename, 'r') as fh:
        print('Reading %s' % fh.name)
        contents = fh.readlines()

    data = []

    lib = None
    subckt = None

    for i, line in enumerate(contents):

        # Detect .subckt statement
        m = re.match(r'\.subckt\s+(\w+)', line, flags=re.I)
        if m:
            assert subckt is None

            subckt = m.group(1)

            if i > 6:

                # Get library name
                m = re.match(r'^\*\slibrary\s+:\s+(\w+)',
                             contents[i - 6], flags=re.I)
                if m:
                    lib = m.group(1)
                else:
                    lib = None
            else:
                lib = None

            continue

        # Find vflaghl instance
        m = re.match(r'^x\S+ \s+ \S+ \s+ vflaghl\s', line, flags=re.I | re.X)
        n = re.match(r'^x\S+ \s+ \S+ \s+ vflag\s', line, flags=re.I | re.X)
        if m or n:

            assert subckt is not None

            row = {
                'filename': filename,
                'library': lib,
                'subckt': subckt,
                'v'		: None,
                'vhigh': None,
                'vlow': None,
                'vhigh_int': None,
                'vlow_int': None,
            }

            words = line.split()

            # sample line:
            # xvflag_VDD VDD vflaghl vhigh=0.9
            # vlow=0.0 vhigh_int=0.9 vlow_int=0.0
            row['name'] = words[0]
            row['net'] = words[1]
            for word in words[3:]:
                param = word.split('=')
                assert len(param) == 2
            if m:
                row[param[0]] = float(param[1])
            elif n:
                row[param[0]] = float(param[1])

            # Applies check rules

            #   checks that vlow_int is the same as vlow_int
            row['higheq'] = row['vhigh'] == row['vhigh_int']

            #   checks that vlow_int is the same as vlow_int
            row['loweq'] = row['vlow'] == row['vlow_int']

            # Check for unique cell
            tag = (row['library'], row['subckt'], row['net'])
            row['unique'] = not(tag in tags)
            tags.add(tag)

            data.append(Row(**row))

        # Detect .ends
        lib, subckt = detect_ends(line, lib, subckt)

    return data


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument('filenames', nargs='+')
    parser.add_argument('-o', '--output', default='audit_vflags.xlsx')

    args = parser.parse_args()

    tags = set()
    data = []

    # Get vflags for each file
    for filename in args.filenames:
        data_cur = get_vflags(filename, tags)
        data.extend(data_cur)

    # Write data to xlsx
    with xlsxwriter.Workbook(args.output) as workbook:
        print("Opening %s" % args.output)

        sheet = workbook.add_worksheet()

        sheet.write_row(0, 0, fields)
        sheet.autofilter(0, 0, 0, len(fields) - 1)
        sheet.set_column(0, 2, 25, None)
        sheet.freeze_panes(1, 0)

        for i, row in enumerate(data):
            sheet.write_row(i + 1, 0, row)


if __name__ == "__main__":
    main()
    utils__script_usage_statistics(
        "ddr-utils-original-audit_vflags", "2022ww21")
