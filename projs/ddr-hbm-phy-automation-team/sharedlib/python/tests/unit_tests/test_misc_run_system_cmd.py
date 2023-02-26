#!/depot/Python/Python-3.8.0/bin/python
############################################################
#  Test the run_system_cmd function
#  Author : Harsimrat Singh Wadhawan
############################################################
# nolint utils__script_usage_statistics
# nolint main
from unittest.mock import patch
from io import StringIO
import unittest
import os
import pathlib
import sys
import time
import threading

bindir = str(pathlib.Path(__file__).resolve().parent.parent)
sys.path.append(bindir + '/../Util')

from CommonHeader import NULL_VAL, EMPTY_STR, NONE, LOW, MEDIUM, FUNCTIONS, HIGH, SUPER, CRAZY, INSANE
from Messaging import fatal_error
from Misc import run_system_cmd
import CommonHeader


class TestNonBinaryFunctions(unittest.TestCase):

    test_dir = f"/tmp/python_run_system_cmd_{time.time()}"

    # Helper class to emulate argparser
    class ArgClass:
        d = 0
        v = 0

    # Initialise variables
    args = ArgClass()
    __author__ = 'unittest'
    __version__ = '1.00'
    CommonHeader.init(args, __author__, __version__)

    def delayed_interrupt(self):

        stdout, stderr, exit_code = run_system_cmd(
            "ps aux | grep -i 'sleep infinity'", NONE)
        lines = stdout.split("\n")

        for line in lines:
            words = line.split()
            if (len(words) > 0):
                pid = (words[1])
                run_system_cmd(f"skill -9 {pid}", NONE)

    # Test to ensure that the standard output is as expected.
    def test_run_system_cmd(self):

        test_input = "echo ABC"
        expected_output = "ABC\n"

        stdout, stderr, exit_code = run_system_cmd(test_input, NONE)
        self.assertEqual(stdout, expected_output)

    def test_run_system_cmd_verbosity_is_not_an_int(self):

        test_input = "echo ABC"
        expected_output = NULL_VAL

        stdout, stderr, exit_code = run_system_cmd(test_input, "ABCXYZ")
        self.assertEqual(stdout, expected_output)

    def test_run_system_cmd_return_value(self):

        test_input = "echo"
        expected_return_code = 0

        stdout, stderr, exit_code = run_system_cmd(f"{test_input}", NONE)
        self.assertEqual(exit_code, expected_return_code)

    # Borrowed from sharedlib\t\05_Misc_run_system_cmd.t
    def test_run_system_cmd_ls(self):

        self.create_directories_for_testing()
        test_input = f"ls {self.test_dir}/"
        expected_output = "test_0.log\ntest_1.log\ntest_2.log\ntest_3.log\ntest_4.log\n"

        stdout, stderr, exit_code = run_system_cmd(f"{test_input}", NONE)
        self.assertEqual(stdout, expected_output)

    # Borrowed from sharedlib\t\05_Misc_run_system_cmd.t
    def test_run_system_cmd_ls_verbose(self):

        test_input = f"ls {self.test_dir}/"
        expected_output = "test_0.log\ntest_1.log\ntest_2.log\ntest_3.log\ntest_4.log\n"

        levels = [NONE,
                  LOW,
                  MEDIUM,
                  FUNCTIONS,
                  HIGH,
                  SUPER,
                  CRAZY,
                  INSANE
                  ]

        # Patch stdout to supress output
        with patch('sys.stdout', new=StringIO()) as fake_out:  # noqa: F841
            for level in levels:
                stdout, stderr, exit_code = run_system_cmd(
                    f"{test_input}", level)
                self.assertEqual(stdout, expected_output)

    def test_run_system_cmd_bad_command(self):

        test_input = "bad-nosuch-command-torun-should-fail"
        expected_output = "/bin/sh: bad-nosuch-command-torun-should-fail: command not found\n"

        stdout, stderr, exit_code = run_system_cmd(f"{test_input}", NONE)
        self.assertEqual(stderr, expected_output)

    def test_run_system_cmd_exit_code(self):

        test_input = "exit 65"
        expected_return_code = 65
        with patch('sys.stdout', new=StringIO()) as fake_out:  # noqa: F841
            stdout, stderr, exit_code = run_system_cmd(f"{test_input}", LOW)
        self.assertEqual(expected_return_code, exit_code)

    def test_run_system_cmd_exit_code_negative(self):

        test_input = "exit -1"
        expected_return_code = 255
        with patch('sys.stdout', new=StringIO()) as fake_out:  # noqa: F841
            stdout, stderr, exit_code = run_system_cmd(f"{test_input}", LOW)
        self.assertEqual(expected_return_code, exit_code)

    def test_run_system_cmd_exit_code_interrupted(self):

        test_input = "sleep infinity"
        expected_return_code = -9

        # Start process in the background to kill the sleep infinity process
        timer = threading.Timer(5, self.delayed_interrupt)
        timer.start()   # will execute detection() after "5" seconds

        stdout, stderr, exit_code = run_system_cmd(f"{test_input}", NONE)
        self.assertEqual(expected_return_code, exit_code)

    def test_run_system_cmd_blank(self):

        test_input = EMPTY_STR
        expected_output = NULL_VAL

        stdout, stderr, exit_code = run_system_cmd(f"{test_input}", NONE)
        self.assertEqual(expected_output, stdout)

    def test_run_system_cmd_stderr(self):

        # Redirect output to stderr for testing
        test_input = ">&2 echo stderr-test"
        expected_output = "stderr-test\n"

        stdout, stderr, exit_code = run_system_cmd(f"{test_input}", NONE)
        self.assertEqual(expected_output, stderr)

    # Make test directory for listing temporary files through the ls command
    def create_directories_for_testing(self):

        try:
            os.mkdir(self.test_dir)
        except FileExistsError:
            fatal_error("Could not set-up test directory.")
        except:  # noqa: E722
            fatal_error("Could not set-up test directory.")

        for x in range(0, 5):

            filename = f"test_{x}.log"
            file_path = f"{self.test_dir}/{filename}"
            pathlib.Path(file_path).touch()


if __name__ == '__main__':
    unittest.main()
