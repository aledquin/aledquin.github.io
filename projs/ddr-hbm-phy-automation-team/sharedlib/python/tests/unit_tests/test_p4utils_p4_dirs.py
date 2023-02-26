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
from P4Utils import da_p4_dirs
import CommonHeader


class TestDirectoryFunctions(unittest.TestCase):

    # Helper class to emulate argparser
    class ArgClass:
        d = 0
        v = 0

    # Initialise variables
    args = ArgClass()
    __author__ = 'unittest'
    __version__ = '1.00'
    CommonHeader.init(args, __author__, __version__)

    def test_list_dirs(self):

        test0 = {
            'file': "//sde-drops/cci/e2010.12/prod_bf4/*",
            'expect': [
                "//sde-drops/cci/e2010.12/prod_bf4/avv",
                "//sde-drops/cci/e2010.12/prod_bf4/cci",
                "//sde-drops/cci/e2010.12/prod_bf4/clct",
                "//sde-drops/cci/e2010.12/prod_bf4/compat",
                "//sde-drops/cci/e2010.12/prod_bf4/dev_root",
                "//sde-drops/cci/e2010.12/prod_bf4/dox",
                "//sde-drops/cci/e2010.12/prod_bf4/export",
                "//sde-drops/cci/e2010.12/prod_bf4/gvar",
                "//sde-drops/cci/e2010.12/prod_bf4/include",
                "//sde-drops/cci/e2010.12/prod_bf4/test",
                "//sde-drops/cci/e2010.12/prod_bf4/tools",
                "//sde-drops/cci/e2010.12/prod_bf4/unit",
                "//sde-drops/cci/e2010.12/prod_bf4/utils"
            ]
        }

        test1 = {
            'file': "//wwcad/msip/projects/golden_tb/*",
            'expect': [
                "//wwcad/msip/projects/golden_tb/HSIC",
                "//wwcad/msip/projects/golden_tb/TOP_Sim",
                "//wwcad/msip/projects/golden_tb/USB2",
                "//wwcad/msip/projects/golden_tb/doc",
                "//wwcad/msip/projects/golden_tb/flow",
                "//wwcad/msip/projects/golden_tb/work_dir"
            ]
        }

        test2 = {
            'file': "//foundation-drops/boost/g2012.03/prod/boost/*",
            'expect': [
                "//foundation-drops/boost/g2012.03/prod/boost/boost",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_chrono",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_date_time",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_exception",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_filesystem",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_graph",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_iostreams",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_locale",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_math_c99",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_math_c99f",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_math_c99l",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_math_tr1",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_math_tr1f",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_math_tr1l",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_prg_exec_monitor",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_program_options",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_random",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_regex",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_serialization",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_signals",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_system",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_test_exec_monitor",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_thread",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_timer",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_unit_test_framework",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_wave",
                "//foundation-drops/boost/g2012.03/prod/boost/boost_wserialization",
                "//foundation-drops/boost/g2012.03/prod/boost/doc",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-aix64",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-amd64",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-linux",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-rs6000",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-sparc64",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-sparcOS5",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-suse32",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-suse64",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-x86sol32",
                "//foundation-drops/boost/g2012.03/prod/boost/lib-x86sol64"
            ]
        }

        test3 = {
            'file': "//sde-drops/.test/*",
            'expect': NULL_VAL
        }

        test4 = {
            'file': "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/ABCXYZ/...",
            'expect': NULL_VAL
        }

        test5 = {
            'file': "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/ASD.",
            'expect': NULL_VAL
        }

        test6 = {
            'file': "//foundation-drops/boost/h2013.03/prod/*/*",
            'expect': [
                "//foundation-drops/boost/h2013.03/prod/boost-windows-debug/lib-win32",
                "//foundation-drops/boost/h2013.03/prod/boost-windows-debug/lib-win64",
                "//foundation-drops/boost/h2013.03/prod/boost-windows/lib-win32",
                "//foundation-drops/boost/h2013.03/prod/boost-windows/lib-win64",
                "//foundation-drops/boost/h2013.03/prod/boost/boost",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_chrono",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_date_time",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_exception",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_filesystem",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_graph",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_iostreams",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_locale",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_math_c99",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_math_c99f",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_math_c99l",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_math_tr1",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_math_tr1f",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_math_tr1l",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_prg_exec_monitor",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_program_options",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_random",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_regex",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_serialization",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_signals",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_system",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_test_exec_monitor",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_thread",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_timer",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_unit_test_framework",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_wave",
                "//foundation-drops/boost/h2013.03/prod/boost/boost_wserialization",
                "//foundation-drops/boost/h2013.03/prod/boost/doc",
            ]
        }

        tests = [test0, test1, test2, test3, test4, test5, test6]

        for test_case in tests:
            output = da_p4_dirs(test_case['file'])
            with self.subTest():
                self.assertEqual(output, test_case['expect'])


if __name__ == '__main__':
    unittest.main()
