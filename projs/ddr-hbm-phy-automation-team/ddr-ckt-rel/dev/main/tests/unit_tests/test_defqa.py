#!/depot/Python/Python-3.8.0/bin/python
"""
Tests ddr-ckt-rel/dev/main/bin/defQA.py
"""
import pytest
from unittest import mock
from pathlib import Path
import sys

REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "ddr-ckt-rel/dev/main/bin"))
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))

import defQA
import CommonHeader


class CommonHeaderArgs:
    """Helper used for initializing CommonHeader"""

    d = 0
    v = 0
    __author__ = "unittest"
    __version__ = "1.00"


def setup_module(_) -> None:
    """Setup CommonHeader before tests."""
    CommonHeader.init(CommonHeaderArgs, CommonHeaderArgs.__author__, CommonHeaderArgs.__version__)


class TestDefQa:
    """Tests for defQA.py"""

    LOG = Path("defQA.log")
    TEST_DATA = REPO_TOP / "ddr-ckt-rel/dev/main/tests/data/defQA"

    def teardown_method(self) -> None:
        """Delete log after every test."""
        TestDefQa.LOG.unlink(missing_ok=True)

    def test_help_text(self, capfd) -> None:
        """Test printing the help (usage) text."""
        with mock.patch("sys.argv", ["defQA.py", "--help"]):
            with pytest.raises(SystemExit):
                defQA.main()
        assert "Syncs all the def files mentioned in the crr file." in capfd.readouterr().out

    def test_golden_log(self) -> None:
        """Test calling defQA.py with a CRR file and check if log matches 'gold' log."""
        crr_file = TestDefQa.TEST_DATA / "ckt_release_1.00a_pre3_crr.txt"
        gold_log = TestDefQa.TEST_DATA / "gold_defQA_log.txt"
        with mock.patch("sys.argv", ["defQA.py", "--crr", str(crr_file)]):
            defQA.main()

        gold_log_text = gold_log.read_text()
        assert TestDefQa.LOG.is_file()

        actual_log_text = TestDefQa.LOG.read_text()
        assert actual_log_text == gold_log_text


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__] + sys.argv[1:])
    sys.exit(ret_code)
