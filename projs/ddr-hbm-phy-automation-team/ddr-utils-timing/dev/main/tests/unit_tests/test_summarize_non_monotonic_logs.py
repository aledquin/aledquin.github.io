#!/depot/Python/Python-3.8.0/bin/python
"""
Tests for summarize_non_monotonic_logs.py
"""
import pytest
from pathlib import Path
import sys

TOOL_DIR = Path(__file__).resolve().parent.parent.parent
sys.path.append(str(TOOL_DIR / "lib/python/Util"))
sys.path.append(str(TOOL_DIR / "bin"))

import CommonHeader

import summarize_non_monotonic_logs as snml


class CommonHeaderArgs:
    """Helper used for initializing CommonHeader"""

    d = 0
    v = 0
    __author__ = "unittest"
    __version__ = "1.00"


def setup_module(_) -> None:
    """Setup CommonHeader before tests."""
    CommonHeader.init(CommonHeaderArgs, CommonHeaderArgs.__author__, CommonHeaderArgs.__version__)


class TestSummarizeNonMonotonicLogs:
    """Tests for summarize_non_monotonic_logs.py"""

    LOGS_DIR = TOOL_DIR / "tests/data/MONOTONICLOGS"

    def test_find_logs(self) -> None:
        """Test finding all log files."""
        expected_log_files = ["example_0.monotoniclog", "example_1.monotoniclog"]
        log_files = list(snml.find_log_files(TestSummarizeNonMonotonicLogs.LOGS_DIR))
        for expected_log in expected_log_files:
            expected_full_path = TestSummarizeNonMonotonicLogs.LOGS_DIR / expected_log
            assert expected_full_path in log_files

    def test_find_non_monotonic_errors(self) -> None:
        """Test finding non-monotonic errors"""
        log_files = snml.find_log_files(TestSummarizeNonMonotonicLogs.LOGS_DIR)
        (
            non_monotonic_errors_per_log,
            all_non_monotonic_errors,
        ) = snml.find_non_monotonic_errors(log_files)

        # Make sure first error is correct
        error = all_non_monotonic_errors[0]
        assert error.arc == "setup_rising"
        assert error.pin == "RxRepCalClkEn"
        assert error.largest_error == 0.586
        assert error.lineno == 354
        assert error.largest_error_values == [28.0386257172, 27.0323390961, 25.8692855835, 24.8418884277, 25.4276218414]

        peak_error = all_non_monotonic_errors[-3]
        assert peak_error.pin == "PeakTest"
        assert peak_error.largest_error_values == [28.0386257172, 29.0323390961, 30.7692855835, 29.9418884277, 28.4276218414]
        assert peak_error.largest_error == 0.827  # 30.7692855835 - 29.9418884277

        assert len(all_non_monotonic_errors) == 7
        assert len(non_monotonic_errors_per_log) == 2
        assert len(non_monotonic_errors_per_log[0]) == 3


if __name__ == "__main__":
    # nolint utils__script_usage_statistics
    # nolint main
    ret_code = pytest.main([__file__, "--capture", "no"] + sys.argv[1:])
    sys.exit(ret_code)
