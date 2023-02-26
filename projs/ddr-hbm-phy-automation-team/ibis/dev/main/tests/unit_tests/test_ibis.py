#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for ibis.py
"""
import pytest
from pathlib import Path
import sys

REPO_TOP = Path(__file__).resolve().parent.parent.parent.parent.parent.parent
sys.path.append(str(REPO_TOP / "ibis/dev/main/bin"))
sys.path.append(str(REPO_TOP / "sharedlib/python/Util"))

import CommonHeader
import Messaging
import ibis


class CommonHeaderArgs:
    """Helper used for initializing CommonHeader"""

    d = 0
    v = 0
    __author__ = "unittest"
    __version__ = "1.00"


def setup_module(_) -> None:
    """Setup CommonHeader before tests."""
    CommonHeader.init(
        CommonHeaderArgs, CommonHeaderArgs.__author__, CommonHeaderArgs.__version__
    )


class TestIbis:
    """Tests for ibis.py"""

    Messaging.create_logger("/dev/null")

    def test_correlation_report(self) -> None:
        """test correlation report results"""
        expected_stdout = [
            {"Case": "drv max ddr5", "Ideal Impedance": 120.0, "PU Impedance": 1.9086},
            {"Case": "drv min ddr5", "Ideal Impedance": 120.0, "PU Impedance": 1.7656},
            {"Case": "drv typ ddr5", "Ideal Impedance": 120.0, "PU Impedance": 1.9122},
            {"Case": "drv max ddr5", "Ideal Impedance": 30.0, "PU Impedance": 129.7262},
            {"Case": "drv min ddr5", "Ideal Impedance": 30.0, "PU Impedance": 129.4272},
            {"Case": "drv typ ddr5", "Ideal Impedance": 30.0, "PU Impedance": 129.7197},
            {"Case": "drv max ddr5", "Ideal Impedance": 60.0, "PU Impedance": 75.4504},
            {"Case": "drv max ddr5", "Ideal Impedance": 60.0, "PD Impedance": 43.3169},
            {"Case": "drv min ddr5", "Ideal Impedance": 60.0, "PU Impedance": 0.8597},
        ]
        assert (
            ibis.run_correlation_analysis(
                f"{REPO_TOP}/ibis/dev/main/tests/data/ibis_correlation_file_testdata.xlsx"
            )
            == expected_stdout
        )


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__, "--capture", "no"] + sys.argv[1:])
    sys.exit(ret_code)
