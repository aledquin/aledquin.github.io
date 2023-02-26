#!/depot/Python/Python-3.8.0/bin/python
"""
Finds and summarizes non-monotonicity issues in monotic logs
Example logs directory:
    /remote/us01sgnfs00444/lpddr5x/d932-lpddr5x-tsmc4ffp-12/rel1.00_cktpcs/design/timing_final/vdd_0.6/nt/dwc_lpddr5xphy_txrxdqs_ew/quality_checks/alphaLibCheckMonotonicSetupHold/MONOTONICLOGS
"""

__author__ = "Nicholas Seguin"
__tool_name__ = "ddr-utils-timing-summarize-non-monotonic-logs"
__description__ = "Finds and summarizes non-monotonicity issues in monotic logs"

import argparse
from pathlib import Path
import sys
from dataclasses import dataclass, field
from typing import List, Tuple

BIN_DIR = str(Path(__file__).resolve().parent)
# Add path to Python sharedlib
sys.path.append(BIN_DIR + "/../lib/Util")
sys.path.append(BIN_DIR + "/../lib/python/Util")


# Import messaging functions
from Messaging import (
    eprint,
    fatal_error,
    p4print,
    dprint,
    nprint,
)

# Import miscellaneous utilities
import Misc
import CommonHeader


MONOTONIC_LOGS_FILE_PATTERN = "*.monotoniclog"
TIMING_ARCS = [
    "setup_rising",
    "hold_rising",
    "hold_falling",
    "setup_falling",
    "non_seq_hold_rising",
    "non_seq_hold_falling",
    "non_seq_setup_rising",
    "non_seq_setup_falling",
]


@dataclass
class NonMonotonicError:
    """Represents and non-monotonicity error found in a monotonic log."""

    log_file: Path
    cell: str
    arc: str
    pin: str
    rel_pin: str
    start_constraint: str
    lineno: int
    values: List[str] = field(default_factory=list)
    end_constraint: str = None
    largest_error: float = 0.0
    largest_error_values: List[float] = field(default_factory=list)

    @staticmethod
    def from_log_file(log_file: Path) -> List["NonMonotonicError"]:
        """
        Creates NonMonotonicError's from a log file.
        Example format:
            ======================================================================================
            Arc : setup_rising
            pin :RxRepCalClkEn
            rel_pin : Pclk
            Constraint: rise_constraint
            Non monotonic : V
            variable: constrained_pin_transition, index=0, value=1.36500000954
            values: 28.0386257172 27.0323390961 25.8692855835 24.8418884277 25.4276218414
            Non monotonic : V
            variable: constrained_pin_transition, index=0, value=17.0625
            values: 34.9296722412 33.919708252 32.7616348267 31.7348690033 32.3086700439
            Non monotonic : V
            variable: constrained_pin_transition, index=0, value=34.125
            values: 40.8950157166 39.8783836365 38.7293357849 37.7037124634 38.255897522
            Non monotonic : V
            variable: constrained_pin_transition, index=0, value=68.25
            values: 49.7962493896 48.7612991333 47.637046814 46.6145744324 47.1073608398
            Constraint: fall_constraint
            ======================================================================================
        """
        errors = []
        current_error = None

        delimiter = "=" * 86

        dprint(CommonHeader.NONE, f"Reading log {log_file}")
        lines = log_file.read_text().splitlines()
        cell = lines[0].split()[1]  # Cell dwc_lpddr5xphy_txrxdqs_ew

        for i, line in enumerate(lines):
            if "Non monotonic" in line:
                if not current_error:
                    # New error found
                    current_error = NonMonotonicError(
                        log_file=log_file,
                        cell=cell,
                        arc=lines[i - 4].split()[2],  # Arc : setup_rising
                        pin=lines[i - 3].split()[1][1:],  # pin :RxRepCalClkEn
                        rel_pin=lines[i - 2],
                        start_constraint=lines[i - 1],
                        lineno=i - 3,
                    )
                values = lines[i + 2]  # Ex: values: 49.7962493896 48.7612991333 47.637046814 46.6145744324 47.1073608398
                values = values.split()[1:]
                try:
                    current_error.values.append([float(x) for x in values])
                except ValueError as exception:
                    eprint(f"Could not convert value to float. Setting to 0... {exception}")
                    current_error.values.append([0,0])
            if current_error and delimiter in line:
                current_error.end_constraint = lines[i - 1]
                errors.append(current_error)
                current_error = None

        for error in errors:
            error.largest_error, error.largest_error_values = error.find_largest_error_in_values()
        return errors

    def find_largest_error_in_values(self) -> float:
        """Returns in picoseconds the magnitude of the largest error."""
        largest_error = 0.0
        largest_values = []
        for value_set in self.values:
            current_error = self.calculate_error_magnitude(value_set)
            if current_error > largest_error:
                largest_error = current_error
                largest_values = value_set

        return round(largest_error, 3), largest_values

    def calculate_error_magnitude(self, values: List[float]) -> float:
        """Calculates the largest error in a set of values from the log"""

        # The error magnitude is either a 'peak' or 'valley' in values
        # The 'peak' or 'valley' is subtracted from the next value
        highest = max([(i,x) for (i,x) in enumerate(values)], key=lambda x: x[1])
        lowest = min([(i,x) for (i,x) in enumerate(values)], key=lambda x: x[1])

        # If highest or lowest is not the first or last element
        # Then it is a peak or valley
        if highest[0] != 0 and highest[0] != (len(values) - 1):
            # Peak found
            return abs(highest[1] - values[highest[0] + 1])
        # Valley
        return abs(lowest[1] - values[lowest[0] + 1])

    def as_string(self, show_all_values: bool = False) -> str:
        """Returns a string representation of the error."""
        lines = [
            f"Log file path : {self.log_file}",
            f"                line {self.lineno}",
            f"Arc           : {self.arc}",
            f"Pin           : {self.pin}",
            f"Largest error : {self.largest_error} ps",
        ]

        if show_all_values:
            lines.extend([
                f"Values        : {' '.join([str(x) for x in val])}, Error: {self.calculate_error_magnitude(val) :.3f} ps" for val in self.values
            ])
        else:
            lines.append(f"Values        : {' '.join([str(x) for x in self.largest_error_values])}")
        return "\n".join(lines)


def _create_argparser() -> argparse.ArgumentParser:
    """Initialize an argument parser. Arguments are parsed in Misc.setup_script"""
    # Always include -v and -d arguments
    parser = argparse.ArgumentParser(description=__description__)
    parser.add_argument("-v", metavar="<#>", type=int, default=0, help="Verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="Debug")

    parser.add_argument(
        "monotonic_logs_dir",
        type=Path,
        help="Path to monotonic logs directory containing *.monotoniclog files. "
        "Ex: /remote/us01sgnfs00444/lpddr5x/d932-lpddr5x-tsmc4ffp-12/rel1.00_cktpcs/design/timing_final/vdd_0.6/nt/dwc_lpddr5xphy_txrxdqs_ew/quality_checks/alphaLibCheckMonotonicSetupHold/MONOTONICLOGS",
    )

    return parser


def find_log_files(monotonic_logs_dir: Path) -> List[Path]:
    """Finds all monotonic logs in a directory."""
    if not monotonic_logs_dir.is_dir():
        fatal_error(
            f"Invalid monotonic logs dir: '{monotonic_logs_dir}'.\n"
            f"Directory does not exist or is not readable."
        )
    log_files = monotonic_logs_dir.glob(MONOTONIC_LOGS_FILE_PATTERN)
    if not log_files:
        fatal_error(
            f"No Monotonic logs found in directory '{monotonic_logs_dir}'\n"
            f"Log file names should match pattern: '{MONOTONIC_LOGS_FILE_PATTERN}'"
        )
    return sorted(log_files)


def find_non_monotonic_errors(
    log_files: List[Path],
) -> Tuple[List[NonMonotonicError], List[NonMonotonicError]]:
    """Returns non-monotonic errors found in log files."""
    non_monotonic_errors_per_log = []
    all_non_monotonic_errors = []
    for log_file in log_files:
        non_monotonic_errors = NonMonotonicError.from_log_file(log_file)
        all_non_monotonic_errors.extend(non_monotonic_errors)
        if non_monotonic_errors:
            non_monotonic_errors_per_log.append(non_monotonic_errors)
    return non_monotonic_errors_per_log, all_non_monotonic_errors


def main(cmdline_args: List[str] = None) -> None:
    """Main function."""
    argparser = _create_argparser()
    args = Misc.setup_script(argparser, __author__, __tool_name__, cmdline_args)

    log_files = find_log_files(args.monotonic_logs_dir)
    non_monotonic_errors_per_log, all_non_monotonic_errors = find_non_monotonic_errors(log_files)

    if not non_monotonic_errors_per_log:
        p4print(f"No non-monoticity errors found in {len(log_files)} log file(s). Exiting 0...")
        sys.exit(0)

    eprint(f"Found non-monotonicity errors in {len(non_monotonic_errors_per_log)} log file(s).")

    errors_by_arc = {}
    for arc in TIMING_ARCS:
        errors = [x for x in all_non_monotonic_errors if x.arc == arc]
        errors_by_arc[arc] = errors

    largest_error = max([x.largest_error for x in all_non_monotonic_errors])
    nprint(f"Largest error: {largest_error} ps\n")

    nprint("---------------------------------------------------------------")
    nprint("| Timing Arc                | Num errors | Largest error (ps) |")
    nprint("---------------------------------------------------------------")
    for arc, errors in errors_by_arc.items():
        largest_error = max([x.largest_error for x in errors]) if errors else "-"
        num_errors = len(errors) if errors else "-"
        nprint(f"| {arc :<25} | {num_errors :<10} | {largest_error :<18} |")
    nprint("---------------------------------------------------------------\n")

    nprint("\n---------------- SUMMARY LARGEST ERROR PER LOG ----------------\n")

    for non_monotonic_errors in non_monotonic_errors_per_log:
        largest_error = max(non_monotonic_errors, key=lambda x: x.largest_error)
        nprint(largest_error.as_string(show_all_values=False))
        nprint("-----")

    nprint("\n-------------------- SUMMARY ALL ERRORS ---------------------\n")
    for non_monotonic_errors in non_monotonic_errors_per_log:
        for error in non_monotonic_errors:
            nprint(error.as_string(show_all_values=True))
            nprint("-----")

    nprint("")
    eprint("Non-monotonic errors found. Exiting 1...")
    sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
