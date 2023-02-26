#!/depot/Python/Python-3.8.0/bin/python
############################################################
#  Test the p4 print file funciton
#  Author : Harsimrat Singh Wadhawan
############################################################
# nolint utils__script_usage_statistics
# nolint main
# nolint alpha_common
import unittest
import pathlib
import sys

bindir = str(pathlib.Path(__file__).resolve().parent.parent)
sys.path.append(bindir + '/../Util')

from CommonHeader import NULL_VAL, EMPTY_STR
from P4Utils import da_p4_print_p4_file
import CommonHeader


class TestPrintingFunctions(unittest.TestCase):

    file_array = []
    original_view = []
    original_root = EMPTY_STR
    depotPath = "wwcad/msip/projects/alpha/alpha_common/wiremodel"

    # Helper class to emulate argparser
    class ArgClass:
        d = 0
        v = 0

    # Initialise variables
    args = ArgClass()
    __author__ = 'unittest'
    __version__ = '1.00'
    CommonHeader.init(args, __author__, __version__)

    def test_print_non_existant_file(self):

        test_case = {
            # This file should not exist
            'file': '//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/MessagingTest.pm',
            'expect': NULL_VAL
        }

        output = da_p4_print_p4_file(test_case['file'])
        self.assertEqual(output, test_case['expect'])

    def test_print_existing_file(self):

        test_case = {
            # This file should exist
            'file': '//wwcad/msip/projects/alpha/alpha_common/bin/lib/Util/Messaging.pm',
            'expect': NULL_VAL
        }

        output = da_p4_print_p4_file(test_case['file'])
        self.assertNotEqual(output, test_case['expect'])

    def test_print_binary_file(self):

        # READ PDF
        with open(f"{bindir}/../tests/data/LICENSE.PDF", "rb") as in_file:
            bytes = (in_file.read())

        test_case = {
            # This file should not exist
            'file': '//openaccess-drops/lefdef/dev/5.8.3/lef/LICENSE.PDF',
            'expect': bytes
        }

        output = da_p4_print_p4_file(test_case['file'], binary=True)
        self.assertEqual(output, test_case['expect'])

    def test_print_bad_path(self):

        test_case = {
            # This path should not exist
            'file': 'wcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/...',
            'expect': NULL_VAL
        }

        output = da_p4_print_p4_file(test_case['file'])
        self.assertEqual(output, test_case['expect'])

    def test_print_binary_file_without_binary_flag(self):

        # In this testcase the output cannot be decoded because a binary stream
        # is returned from the standard output. The da_p4_print_p4_file function
        # cannot decode such an object.

        # READ PDF
        with open(f"{bindir}/../tests/data/LICENSE.PDF", "rb") as in_file:
            bytes = (in_file.read())  # noqa: F841

        test_case = {
            'file': '//openaccess-drops/lefdef/dev/5.8.3/lef/LICENSE.PDF',
            'expect': NULL_VAL
        }

        output = da_p4_print_p4_file(test_case['file'])
        self.assertEqual(output, test_case['expect'])

    def test_print_non_existant_file_with_binary_flag(self):

        test_case = {
            # This file should not exist
            'file': '//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/MessagingTest.pm',
            'expect': b''
        }

        output = da_p4_print_p4_file(test_case['file'], binary=True)
        self.assertEqual(output, test_case['expect'])

    def test_print_existing_file_with_binary_flag(self):

        test_case = {
            # This file should exist
            'file': '//wwcad/msip/projects/alpha/alpha_common/bin/lib/Util/Messaging.pm',
            'expect': NULL_VAL
        }

        output = da_p4_print_p4_file(test_case['file'], binary=True)
        self.assertNotEqual(output, test_case['expect'])

    def test_print_bad_path_with_binary_flag(self):

        test_case = {
            # This path should not exist
            'file': 'wcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/...',
            'expect': NULL_VAL
        }

        output = da_p4_print_p4_file(test_case['file'], binary=True)
        self.assertEqual(output, test_case['expect'])


if __name__ == '__main__':
    unittest.main()
