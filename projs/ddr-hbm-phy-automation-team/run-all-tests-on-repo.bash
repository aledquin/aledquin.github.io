#!/usr/bin/env bash

#declare -a arr=( "./perl/test/functional/test1/run.cmds.bash" "./perl/test/functional/test--P80001562-84848/run.cmds.bash" )
declare -a arr=(
    "./python/test/TEST__get_vici_info.pl" 
    "./perl/test/functional/test1/run.cmds.bash" 
    "./perl/test/functional/test--P80001562-84848/run.cmds.bash" 
    "./perl/test/functional/test--P80001562-85312/run.cmds.bash" 
    "./perl/test/functional/test--P80001562-93206/run.cmds.bash" 
    "./perl/test/functional/test--P80001562-94922/run.cmds.bash" 
    )

OVERALL_STATUS="PASS"
PASS="PASS"
FAIL="FAIL"


echo "----------------------------------------------------------"
echo "run-all-tests-on-repo.bash: Running list of tests     ... "
echo "----------------------------------------------------------"
test_num=0
# Run each test listed in the array 'arr' and check the return value
#    to see if there's an error. "0"=pass, otherw"ise =fail
for script_name in "${arr[@]}"
do
   test_num=$((test_num+1))
   echo "Test #$test_num : $script_name"
   $script_name >& /dev/null
   STATUS=$?
   if [ $STATUS -gt 0 ] ; then
      OVERALL_STATUS=$FAIL
      echo "$test_num : $FAIL : TEST $script_name "
   else
      echo "$test_num : $PASS : TEST $script_name "
   fi
done

#  Check if any of the tests FAILED...report final status
if [ $OVERALL_STATUS == $FAIL ] ; then
      echo "-------------run-all-tests-on-repo.bash----------"
      echo "OVERALL STATUS of TESTs : $FAIL!"
      echo "--------------------------------------------------"
      exit 1
fi

if [ $OVERALL_STATUS == $PASS ] ; then
      echo "-------------run-all-tests-on-repo.bash----------"
      echo "OVERALL STATUS of TESTs : $PASS!"
      echo "--------------------------------------------------"
      exit 0
fi


# If you get to this exit statement, something unintended occurred.
exit -1
