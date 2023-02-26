#!/depot/Python/Python-3.8.0/bin/python
# nolint utils__script_usage_statistics
# nolint main
from unittest import TestCase    # noqa: F401
from unittest.mock import patch
from io import StringIO
import unittest
import os
import pathlib
import sys

bindir = str(pathlib.Path(__file__).resolve().parent.parent)
sys.path.append(bindir + '/../Util')

from CommonHeader import NULL_VAL
from P4Utils import da_p4_create_instance
from P4 import P4


class TestInstanceFunctions(unittest.TestCase):

    def test_da_p4_create_instance(self):
        p4 = da_p4_create_instance()
        self.assertIsInstance(p4, P4)

    def test_da_p4_create_instance_without_variables(self):
        del os.environ['P4PORT']
        del os.environ['P4CLIENT']
        with patch('sys.stdout', new=StringIO()) as fake_out:  # noqa: F841
            p4 = da_p4_create_instance()
        self.assertEqual(p4, NULL_VAL)


if __name__ == '__main__':
    unittest.main()
