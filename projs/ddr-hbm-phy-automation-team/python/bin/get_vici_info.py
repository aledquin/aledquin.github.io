#!/global/freeware/Linux/2.X/python-3.6.1/bin/python
"""
Implemented by Synopsys LLC (synopsys.com).

Description: 
    Get all corners from vici and dump to the file

Dependencies & Supported Versions: 
    Python 3.6.x

Libraries: 
    os, re, logging, sys, requests, bs4

Revision: 
    v1.0 alpha (May 20, 2020)
    Author : Patrick Juliano

Usage: get_vici_info.py <url>
"""
try:
    import os
    import re
    import sys
    import shutil
    import requests
    from bs4 import BeautifulSoup
except ImportError as exception:
    print("%s - Please install the necessary libraries." % exception)
    sys.exit(1)


def get_url_content(url):
    """
    Open content of url and search the right table for check.
    Args:
        url - URL name for open and get content.
    Returns:
    """
    try:
        data = []
        list_tmp = []
        final_dict = {}
        cell_names_and_version = {}
        all_corners_type_and_name = {}
        cell_names_and_version_data = []

        print("-I- Opening the '%s' url for checking content" % url)
        response = requests.get(url)
        content = BeautifulSoup(response.text, 'lxml')
        print ("-I- Get cell_names and version from vici")
        if content:
            print("-I- ViCi information returned.")
 
        # ID of the subcomponents table and can change when VICI gets released
        # Use print soup.prettify to debug and find the new XML
        soup = content.find('div', {'id': '5388'})
        if not soup:
            soup = content.find('div', {'id': '4153'})
            if not soup:
                soup = content.find('div', {'id': '1167'})
                if not soup:
                    soup = content.find('div', {'id': '633'})
                    if not soup:
                        #print(soup.prettify())
                        print("-E- Couldn't find the table of information expected...INDEX value may have changed in latest ViCi release!")
        soup = soup.find('div', attrs={'class': ''})
        rows = soup.find_all('tr')

        for row in rows:
            #$print ("row => "+row.text)
            cols = row.find_all('td')
            #for col in row.find_all('td'):
                #  TAG obj ... dump for table "Sub Projects/Components"
                #print(type(col), col.text)
            cols = [ele.text.strip() for ele in cols]
                #  print list of values in each row of "Sub Projects/Components"
            #print(type(cols), ' '.join(cols) )
            cell_names_and_version_data.append([ele for ele in cols]) # Get rid of empty values

        for column in cell_names_and_version_data[1:]:
            #print("-----------------")
            #print("     => column[0]",column[0])  # Component name
            #print("     => column[1]",column[1])  # Project name
            #print("     => column[2]",column[2])  # Release/Version
            #print("     => column[3]",column[3])  # Version Note (orientation)
            #print("     => column[4]",column[4])  # Path to Component
            #print("     => column[5]",column[5])  # Component tarball
            #print("     => column[6]",column[6])  # Component ready?
            #  Check if there's at least 6 columns AND
            #        check if there's a value for the version (col #2)
            component = column[0].lower()
            version = column[2]
            orientation = column[3].lower()
            #print ("col len=" , len(column))
            if len(column) > 5 and version:
                orientations=""
                if orientation:
                    if 'ns' in orientation and 'ew' in orientation:
                        orientations = '_ew+_ns'
                    else:
                        if 'ns' in orientation:
                            orientations = '_ns'
                        if 'ew' in orientation:
                            orientations = orientations + '_ew'
                cell_names_and_version[component + " : " + orientations] = version
                # Dump the orientation exactly as extracted from the 'Version Note' field in ViCi
                #   Do this if you want the regex from users to deal with extracting orientations
                #cell_names_and_version[component + " : " + orientation] = version
            if len(column) > 5 and not version:
                cell_names_and_version[component] = " : " + orientation 
        print ("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
        for cell_name, version in cell_names_and_version.items():
            print (cell_name + ' : ' + version)
        print ("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++")

        print ("-I- Done grabbing cell_names and version from ViCi")
        #############################################################
        #  Go grab the PVT info
        #############################################################
        list_tmp = []
        table = content.find('table', attrs={'class':'PVTcasesTable'})
        rows = table.find_all('tr')

        import pprint
        import sys
        pp = pprint.PrettyPrinter(indent=4)
        print ("-I- Get pvt_corners from vici")
        for row in rows:
            cols = row.find_all('td')
            cols = [ele.text.strip() for ele in cols]
            # Use the re.sub cmd below to remove
            #    comments out of the PVT tables...example 
            # ORIGINAL = <td class="PVTtableCells">0.935 (boost+10%)</td>
            #                                           ^^^^^^^^^^^^
            #                                           ^^^^^^^^^^^^
            # FIXED    = <td class="PVTtableCells">0.935</td>
            data.append([re.sub('\s\([^\)]*?\)', "", ele) for ele in cols if ele]) # Get rid of empty values

        for each_row in data[1:]:
            each_row_length = len(each_row)
            all_corners_type_and_name.setdefault(each_row[0], [])
            i = 1
            while i < each_row_length:
                if i == 1 or i == 4 or i == 5:
                    i += 1
                else:
                    list_tmp.append(each_row[i])
                    i += 1
                    if i == each_row_length:
                        all_corners_type_and_name[each_row[0]].append(list_tmp)
                        list_tmp = []


       #  Patrick : Table defintion extracted from ViCi
       #  [
       #    ['FF', '0.825', '-40 / 0 /125', 'cworst_CCworst, ....'],
       #    ['SS', '0.675', '-40 / 0 /125', 'cworst_CCworst, ....'],
       #    ...,
       #    ['TT', '0.675', '25', 'typical' ]
       #  ]
        corner_name_by_table = ''
        patt = r'\(.*\)'
        import pprint;
        pp = pprint.PrettyPrinter(indent=4)
        #pp.pprint(all_corners_type_and_name.items())
        # Patrick : Create list with files
        for type_corner, corners_values in all_corners_type_and_name.items():
            mycorners = []
            final_dict.setdefault(type_corner, [])
            #pp.pprint(final_dict)
            print (type_corner)
            for each_values_list in corners_values:
                print (each_values_list)            
                string_with_brackets = re.search(patt, each_values_list[3])
                if string_with_brackets:
                    each_values_list[3] = each_values_list[3].replace(string_with_brackets.group(0), '')
                # Iterate over 'Extraction Corners' (i.e. cworst_CCworst, rcbest_CCbest, etc)
                #print("Table of Values")
                #pp.pprint(each_values_list[3])
                for extraction_corner in each_values_list[3].split(' '):
                    extraction_corner = extraction_corner.replace("," , "")
                    extraction_corner = extraction_corner.replace(" " , "")
                    # Patrick : Now, check if there are multiple temperatures in the field, seperated by '/' (e.g. '-40 / 0 / 125') 
                    if '/' in each_values_list[2]:
                        # Patrick : Print element where temperatures are captured
                        # pp.pprint(each_values_list[2])
                        for each_voltage in each_values_list[1].split('/'):
                            each_voltage =  each_voltage.replace('.', 'p') + 'v'
                            for each_temperature in  each_values_list[2].split('/'):
                                each_temperature = each_temperature.strip()
                                if int(each_temperature) < 0:
                                    each_temperature = each_temperature.replace('-', 'n') + 'c_'
                                    corner_name_by_table = each_values_list[0].lower() + \
                                            each_voltage + each_temperature + extraction_corner
                                else:
                                    each_temperature = each_temperature + 'c_'
                                    corner_name_by_table = each_values_list[0].lower() + \
                                            each_voltage + each_temperature + extraction_corner.strip()
                                mycorners.append(corner_name_by_table)
                                #pp.pprint(corner_name_by_table)

                    else:
                        for each_voltage in each_values_list[1].split('/'):
                            each_voltage =  each_voltage.replace('.', 'p') + 'v'
                            for each_temperature in  each_values_list[2].split(','):
                                each_temperature = each_temperature.strip()
                                if int(each_temperature) < 0:
                                    each_temperature = each_temperature.replace('-', 'n') + 'c_'
                                    corner_name_by_table = each_values_list[0].lower() +\
                                            each_voltage + each_temperature + extraction_corner
                                else:
                                    each_temperature = each_temperature + 'c_'
                                    corner_name_by_table = each_values_list[0].lower() +\
                                            each_voltage + each_temperature.strip() + extraction_corner.strip()
                                mycorners.append(corner_name_by_table)
                # Corner by 
                final_dict[type_corner] = mycorners
        # Patrick : Show the list of corners extracted from ViCi
        #pp.pprint(final_dict)

        print ('++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
        for corner, options in final_dict.items():
            #print (corner + ' : Corner type')
            #pvt_list = "\n".join(options) 
            pvt_list = " ".join(options) 
            pvt_list = "PVT options : " + pvt_list
            print (corner + ' : '+pvt_list)
        print ('++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n')

        #############################################################
        #  Go grab the metal information:  Foundry + PHY opt
        #############################################################
        print ('+++++++++++++++++++++++++++++++++++++++++++++')
        print ("-I- Get metal stacks from vici")
        all_metal_stacks = []
        metal_stack_table = content.find('table', attrs={'class':'di-phy-metal-options'})
        rows = metal_stack_table.find_all('tr')
        for row in rows:
            cols = row.find_all('td')
            cols = [x.text.strip() for x in cols]
            all_metal_stacks.extend(cols)
				
        metal_name = all_metal_stacks[0]
        foundry_metal = metal_name + ":"
        for metal_op in all_metal_stacks[::2]:
            if metal_op != metal_name:
                foundry_metal = foundry_metal + " " + metal_op 
        print (foundry_metal)

        metal_name = all_metal_stacks[1]
        PHY_metal = metal_name + ":"
        for metal_op in all_metal_stacks[1::2]:
            if metal_op != metal_name:
                PHY_metal = PHY_metal + " " + metal_op 
        print (PHY_metal)
        print ('+++++++++++++++++++++++++++++++++++++')

    except Exception as exception:
        print ("-E- Failed to open url and get information")
        print (exception)


def main():
    """
    Main function
    """
    try:
        url = sys.argv[1]
    except ImportError as ierr:
        print ("Please run the script with the following command:\nget_vici_info.py [vici_url]")
    finally:
        get_url_content(url)


if __name__ == "__main__":
    main()

