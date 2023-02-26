#!/depot/Python/Python-3.8.0/bin/python
############################################################
#  Test the p4 list file function
#  Author : Harsimrat Singh Wadhawan
############################################################
# nolint utils__script_usage_statistics
# nolint main
# nolint alpha_common
from unittest import TestCase  # noqa: F401
from unittest.mock import patch  # noqa: F401
import unittest
import pathlib
import sys

bindir = str(pathlib.Path(__file__).resolve().parent.parent)
sys.path.append(bindir + '/../Util')

from CommonHeader import NULL_VAL
from P4Utils import da_p4_files
import CommonHeader


class TestFileListingFunctions(unittest.TestCase):

    # Helper class to emulate argparser
    class ArgClass:
        d = 0
        v = 0

    # Initialise variables
    args = ArgClass()
    __author__ = 'unittest'
    __version__ = '1.00'
    CommonHeader.init(args, __author__, __version__)

    def test_list_files_0(self):

        test_case1 = {
            'file': "//openaccess-drops/lefdef/dev/5.8.3/def/*",
            'expect': [
                "//openaccess-drops/lefdef/dev/5.8.3/def/LICENSE.PDF",
                "//openaccess-drops/lefdef/dev/5.8.3/def/LICENSE.TXT",
                "//openaccess-drops/lefdef/dev/5.8.3/def/Makefile",
                "//openaccess-drops/lefdef/dev/5.8.3/def/template.mk",
            ]
        }

        output1 = da_p4_files(test_case1['file'])
        self.assertEqual(output1, test_case1['expect'])

    def test_list_files_1(self):

        test_case2 = {
            'file': "//wwcad/msip/projects/displayport/r102-dptxphy-gf14lpp-18/rel1.00/lib/dptxphy_gold/mpll_out_clocks/schematic/*",
            'expect': [
                "//wwcad/msip/projects/displayport/r102-dptxphy-gf14lpp-18/rel1.00/lib/dptxphy_gold/mpll_out_clocks/schematic/master.tag",
                "//wwcad/msip/projects/displayport/r102-dptxphy-gf14lpp-18/rel1.00/lib/dptxphy_gold/mpll_out_clocks/schematic/sch.oa",
                "//wwcad/msip/projects/displayport/r102-dptxphy-gf14lpp-18/rel1.00/lib/dptxphy_gold/mpll_out_clocks/schematic/snapshot.png",
            ]
        }

        output2 = da_p4_files(test_case2['file'])
        self.assertEqual(output2, test_case2['expect'])

    def test_list_files_2(self):

        test_case3 = {
            'file': "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/...",
            'expect': [
                "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/checksums.txt",
                "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/design_lib/IOPADS2DPT4W/IOPADS2DPT4W/abstract/layout.oa",
                "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/design_lib/IOPADS2DPT4W/IOPADS2DPT4W/abstract/master.tag",
                "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/design_lib/IOPADS2DPT4W/IOPADS2DPT4W/symbol/master.tag",
                "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/design_lib/IOPADS2DPT4W/IOPADS2DPT4W/symbol/symbol.oa"
            ]
        }

        output3 = da_p4_files(test_case3['file'])
        self.assertEqual(output3, test_case3['expect'])

    def test_list_files_3(self):

        test_case4 = {
            'file': "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/ABCXYZ/...",
            'expect': NULL_VAL
        }

        output4 = da_p4_files(test_case4['file'])
        self.assertEqual(output4, test_case4['expect'])

    def test_list_files_4(self):

        test_case5 = {
            'file': "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/ASD.",
            'expect': NULL_VAL
        }

        output5 = da_p4_files(test_case5['file'])
        self.assertEqual(output5, test_case5['expect'])

    def test_list_files_5(self):

        test_case6 = {
            'file': "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/ASDFGHIJKLMN/*",
            'expect': NULL_VAL
        }

        output6 = da_p4_files(test_case6['file'])
        self.assertEqual(output6, test_case6['expect'])


if __name__ == '__main__':
    unittest.main()
