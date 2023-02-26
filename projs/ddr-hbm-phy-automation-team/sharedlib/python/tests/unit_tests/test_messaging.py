#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for Messaging.py
"""
import pytest
from pathlib import Path
import sys
import re

REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))

import CommonHeader
import Messaging


class CommonHeaderArgs:
    """Helper used for initializing CommonHeader"""

    d = 0
    v = 0
    __author__ = "unittest"
    __version__ = "1.00"


def setup_module(_) -> None:
    """Setup CommonHeader before tests."""
    CommonHeader.init(CommonHeaderArgs, CommonHeaderArgs.__author__, CommonHeaderArgs.__version__)


class TestMessaging:
    """Tests for Messaging.py"""

    Messaging.create_logger("/dev/null")

    def setup_method(self) -> None:
        CommonHeader.VERBOSITY = CommonHeader.FUNCTIONS
        CommonHeader.DEBUG = CommonHeader.HIGH

    def test_dprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = f"{Messaging.Color.CYAN}-D- This is a test{Messaging.Color.RESET}\n"
        expected_log = r"test_messaging.py:test_dprint:\d+ -D- This is a test"

        Messaging.dprint(CommonHeader.NONE, message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_iprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "-I- This is a test\n"
        expected_log = r"test_messaging.py:test_iprint:\d+ -I- This is a test"

        Messaging.iprint(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_nprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = f"{message}\n"
        expected_log = rf"test_messaging.py:test_nprint:\d+ {message}"

        Messaging.nprint(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_hprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[36m-H- " + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_hprint:\d+ -H- This is a test"

        Messaging.hprint(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_wprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[33m-W- " + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_wprint:\d+ -W- This is a test"

        Messaging.wprint(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_eprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[31m-E- " + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_eprint:\d+ -E- This is a test"

        Messaging.eprint(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_gprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[32m" + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_gprint:\d+ This is a test"

        Messaging.gprint(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_viprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "-I- This is a test\n"
        expected_log = r"test_messaging.py:test_viprint:\d+ -I- This is a test"

        Messaging.viprint(CommonHeader.NONE, message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_vhprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[36m-H- " + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_vhprint:\d+ -H- This is a test"

        Messaging.vhprint(CommonHeader.NONE, message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_vwprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[33m-W- " + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_vwprint:\d+ -W- This is a test"

        Messaging.vwprint(CommonHeader.NONE, message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_veprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[31m-E- " + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_veprint:\d+ -E- This is a test"

        Messaging.veprint(CommonHeader.NONE, message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_fprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[37;41m-F- " + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_fprint:\d+ -F- This is a test"

        with pytest.raises(SystemExit):
            Messaging.fatal_error(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_p4print(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = "\033[32m" + message + "\033[0m\n"
        expected_log = r"test_messaging.py:test_p4print:\d+ This is a test"

        Messaging.p4print(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_sysprint(self, capfd, caplog) -> None:
        message = "This is a test"
        expected_stdout = f"\x1b[35m-S- {message}\x1b[0m\n"
        expected_log = rf"test_messaging.py:test_sysprint:\d+ -S- {message}"

        Messaging.sysprint(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_sysprint_without_functions(self, capfd, caplog) -> None:
        CommonHeader.VERBOSITY = CommonHeader.NONE
        CommonHeader.DEBUG = CommonHeader.NONE
        message = "This is a test"
        expected_stdout = f"\x1b[35m-S- {message}\x1b[0m\n"
        expected_log = rf"-S- {message}"

        Messaging.sysprint(message)
        assert capfd.readouterr().out == expected_stdout
        assert re.match(expected_log, caplog.records[-1].message)

    def test_header(self, capfd, caplog) -> None:
        CommonHeader.VERBOSITY = CommonHeader.NONE
        expected_message = (
            r"\s+#######################################################\n"
            r"###  Date , Time     : '.*'\n"
            r"###  Launch args     : '.*'\n"
            r"###  Author          : '.*'\n"
            r"###  Release Version : '.*'\n"
            r"###  User            : '.*'\n"
            r"#######################################################\s+"
        )

        Messaging.header()
        assert re.match(expected_message, capfd.readouterr().out)
        assert re.search(expected_message, caplog.records[-1].message)

    def test_footer(self, capfd, caplog) -> None:
        CommonHeader.VERBOSITY = CommonHeader.NONE
        message = (
            "\n\n#######################################################\n###  Goodbye World\n"
        )

        Messaging.footer()
        assert message in capfd.readouterr().out
        assert message in caplog.records[-1].message


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__, "--capture", "no"] + sys.argv[1:])
    sys.exit(ret_code)
