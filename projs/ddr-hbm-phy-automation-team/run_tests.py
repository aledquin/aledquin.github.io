#!/depot/Python/Python-3.8.0/bin/python
"""
Utility script for running pytest and gathering coverage.
"""

__author__ = "Nicholas Seguin"
__tool_name__ = "ddr-da-run-tests-py"

import os
import argparse
from pathlib import Path
import sys
from dataclasses import dataclass
import pytest
import coverage
from typing import List
import colorama
from enum import Enum, auto


REPO_TOP = Path(__file__).resolve().parent
os.chdir(REPO_TOP)  # Keep paths consistent


# Cannot use Messaging.py due to import conflicts with coverage collection
def green_print(msg):
    print(colorama.Fore.GREEN, msg, colorama.Fore.RESET)


def red_print(msg):
    print(colorama.Fore.RED, msg, colorama.Fore.RESET)


def yellow_print(msg):
    print(colorama.Fore.YELLOW, msg, colorama.Fore.RESET)


class TestType(Enum):
    UNIT = auto()
    FUNCTIONAL = auto()


@dataclass
class Tool:
    """Represents a tool and its unit test results."""

    name: str
    source_dir: Path
    unit_tests_dir: Path
    functional_tests_dir: Path

    # Pytest options
    pytest_args: List[str] = None

    # Results
    cov: coverage.Coverage = None
    return_code: pytest.ExitCode = pytest.ExitCode.NO_TESTS_COLLECTED
    coverage_percent: float = 0.0

    def __post_init__(self):
        if self.pytest_args is None:
            # Disable "capture" to fix capsys and caplog fixtures
            self.pytest_args = ["--capture", "no"]

    def run_tests(self, test_dir: Path) -> pytest.ExitCode:
        full_test_dir = str(REPO_TOP / self.name / test_dir)
        suffix = test_dir.split('/')[-1]

        cov = coverage.Coverage(
            config_file=str(REPO_TOP / ".coveragerc"),
            data_suffix=f"{self.name}_{suffix}",
            omit=f"{self.name}/{test_dir}/*",
            source=[f"{self.name}/{self.source_dir}"],
        )
        cov.start()

        self.return_code = pytest.main([full_test_dir] + self.pytest_args)

        cov.stop()
        cov.save()
        self._create_html_coverage_report(cov, suffix)
        self.report_test_results()

        return self.return_code

    def run_unit_tests(self) -> pytest.ExitCode:
        """Runs unit tests and gathers coverage data."""
        return self.run_tests(self.unit_tests_dir)

    def run_functional_tests(self) -> pytest.ExitCode:
        """Runs functional tests and gathers coverage data."""
        return self.run_tests(self.functional_tests_dir)

    def _create_html_coverage_report(self, cov: coverage.Coverage, suffix: str) -> None:
        """Saves HTML coverage report and prints final coverage percentage."""
        try:
            cov_report_dir = f"htmlcov_{self.name}_{suffix}"
            self.coverage_percent = cov.html_report(
                directory=cov_report_dir,
                include=f"{self.name}/{self.source_dir}/*",
                title=f"{self.name} {suffix} Coverage Report",
            )
            green_print(f"Saved coverage report to {os.getcwd()}/{cov_report_dir}/index.html")
            green_print(f"{self.name} coverage: {self.coverage_percent:.2f}%")
        except coverage.misc.CoverageException as exception:
            yellow_print(f"Could not get coverage for tool: {self.name}\nError: {exception}")

    def report_test_results(self) -> None:
        """Prints final test results (PASS/FAIL)."""
        if self.return_code == pytest.ExitCode.OK:
            green_print(f"{self.name} PASSED\n\tCoverage: {self.coverage_percent:.2f}%")
        elif self.return_code == pytest.ExitCode.NO_TESTS_COLLECTED:
            yellow_print(f"{self.name} NO TESTS FOUND\n\tCoverage: {self.coverage_percent:.2f}%")
        else:
            red_print(f"{self.name} FAILED\n\tCoverage: {self.coverage_percent:.2f}%")


TOOLS = [
    Tool(name="bom-checker", source_dir="dev/main/bin", unit_tests_dir="dev/main/tests/unit_tests", functional_tests_dir="dev/main/tests/functional_tests"),
    Tool(name="ddr-ckt-rel", source_dir="dev/main/bin", unit_tests_dir="dev/main/tests/unit_tests", functional_tests_dir="dev/main/tests/functional_tests"),
    Tool(name="ddr-utils", source_dir="dev/main/bin", unit_tests_dir="dev/main/tests/unit_tests", functional_tests_dir="dev/main/tests/functional_tests"),
    Tool(name="ddr-utils-in08", source_dir="dev/main/bin", unit_tests_dir="dev/main/tests/unit_tests", functional_tests_dir="dev/main/tests/functional_tests"),
    Tool(name="ddr-utils-lay", source_dir="dev/main/bin", unit_tests_dir="dev/main/tests/unit_tests", functional_tests_dir="dev/main/tests/functional_tests"),
    Tool(
        name="ddr-utils-timing",
        source_dir="dev/main/bin",
        unit_tests_dir="dev/main/tests/unit_tests",
        functional_tests_dir="dev/main/tests/functional_tests",
    ),
    Tool(name="ibis", source_dir="dev/main/bin", unit_tests_dir="dev/main/tests/unit_tests", functional_tests_dir="dev/main/tests/functional_tests"),
    Tool(name="sharedlib", source_dir="python/Util", unit_tests_dir="python/tests/unit_tests", functional_tests_dir="dev/main/tests/functional_tests"),
]


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    tools = [x.name for x in TOOLS]

    parser = argparse.ArgumentParser(description="Runs Python unit and functional tests with coverage")
    parser.add_argument("-v", metavar="<#>", type=int, default=0, help="verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")

    tool_args = parser.add_mutually_exclusive_group(required=True)
    tool_args.add_argument("-a", "--all", action="store_true", help="Run tests on ALL tools")
    tool_args.add_argument("-t", "--tool", choices=tools, help="Run tests for the specified tool")
    tool_args.add_argument(
        "-m",
        "--merge",
        action="store_true",
        help="Only merge and print coverage results. Don't run any tests.",
    )

    test_type_args = parser.add_mutually_exclusive_group()
    test_type_args.add_argument("-u", "--unit_tests", action="store_true", help="Run ONLY unit tests in <TOOL>/tests/unit_tests/")
    test_type_args.add_argument("-f", "--functional_tests", action="store_true", help="Run ONLY functional tests in <TOOL>/tests/functional_tests/")

    args = parser.parse_args()
    return args


def print_summary() -> None:
    """Print a summary after running ALL unit tests."""
    print("-" * 32)
    print("TEST SUMMARY")
    for tool in TOOLS:
        print("-" * 32)
        tool.report_test_results()
    print_combined_coverage()


def print_combined_coverage() -> None:
    """Combine and print total coverage."""
    cov = coverage.Coverage(config_file=str(REPO_TOP / ".coveragerc"))
    cov.combine(keep=True)
    cov_report_dir = f"htmlcov_combined"
    coverage_percent = cov.html_report(directory=cov_report_dir)
    print("-" * 32)
    green_print(f"Saved combined coverage report to {os.getcwd()}/{cov_report_dir}/index.html")
    green_print(f"TOTAL coverage: {coverage_percent:.0f}%")
    print("-" * 32)

def _run_unit_and_functional_tests(tool: Tool) -> pytest.ExitCode:
    """Run both unit and functional tests."""
    unit_return_code = tool.run_unit_tests()
    functional_return_code = tool.run_functional_tests()
    if unit_return_code == pytest.ExitCode.NO_TESTS_COLLECTED and functional_return_code == pytest.ExitCode.NO_TESTS_COLLECTED:
        return pytest.ExitCode.NO_TESTS_COLLECTED
    if unit_return_code != pytest.ExitCode.OK or functional_return_code != pytest.ExitCode.OK:
        return pytest.ExitCode.TESTS_FAILED
    return pytest.ExitCode.OK


def main() -> None:
    """Main function."""
    args = parse_args()

    final_return_code = pytest.ExitCode.OK
    if args.all:
        for tool in TOOLS:
            if args.unit_tests:
                return_code = tool.run_unit_tests()
            elif args.functional_tests:
                return_code = tool.run_functional_tests()
            else:
                return_code = _run_unit_and_functional_tests(tool)

            if return_code not in [pytest.ExitCode.OK, pytest.ExitCode.NO_TESTS_COLLECTED]:
                final_return_code = pytest.ExitCode.TESTS_FAILED
        print_summary()
    elif args.merge:
        print_combined_coverage()
        sys.exit(0)
    else:
        tool = next(x for x in TOOLS if x.name == args.tool)
        if args.unit_tests:
            final_return_code = tool.run_unit_tests()
        elif args.functional_tests:
            final_return_code = tool.run_functional_tests()
        else:
            final_return_code = _run_unit_and_functional_tests(tool)

    if final_return_code == pytest.ExitCode.OK:
        green_print("TESTS PASSED")
        sys.exit(0)

    if final_return_code == pytest.ExitCode.NO_TESTS_COLLECTED:
        yellow_print("NO TESTS FOUND")
        sys.exit(0)

    red_print("TESTS FAILED")
    sys.exit(1)


if __name__ == "__main__":
    main()
