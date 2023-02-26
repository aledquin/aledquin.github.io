#! /usr/bin/env bash

pushd ./../../bin

echo '*************************************'
echo -e "\e[1;32mTesting ibis_impedance_spreadsheet.py\e[0m"
echo '*************************************'

echo '*************************************'
echo 'ddr54/d807-ddr54-gf12lpp18/1.00a'
echo '*************************************'
./ibis_impedance_spreadsheet.py -proj ddr54/d807-ddr54-gf12lpp18/1.00a          2>&1 | tee -a test_run_log.txt 

echo '*************************************'
echo 'ddr54/d819-ddr54-cuamd-tsmc7ff18/1.00a'
echo '*************************************'
./ibis_impedance_spreadsheet.py -proj ddr54/d819-ddr54-cuamd-tsmc7ff18/1.00a    2>&1 | tee -a test_run_log.txt

echo '*************************************'
echo 'ddr54/d832-ddr54v2-cuamd-tsmc6ff18/1.00a'
echo '*************************************'
./ibis_impedance_spreadsheet.py -proj ddr54/d832-ddr54v2-cuamd-tsmc6ff18/1.00a  2>&1 | tee -a test_run_log.txt

echo '*************************************'
echo 'ddr54/d839-ddr54v2-tsmc7ff18/1.00a'
echo '*************************************'
./ibis_impedance_spreadsheet.py -proj ddr54/d839-ddr54v2-tsmc7ff18/1.00a        2>&1 | tee -a test_run_log.txt

# Check whether a script failed.
if grep Traceback test_run_log.txt >/dev/null 2>&1
then
    echo -e "\e[1;31m FAIL: The script finished running tests with errors, check test_run_log.txt for more details.\e[0m"
else
    echo -e "\e[1;32m PASS: The script finished running tests without errors, check test_run_log.txt for output.\e[0m"
fi

popd

# Move the output to the current directory.
mv ../bin/test_run_log.txt ./test_run_log.txt

echo -e "Done.\n"

