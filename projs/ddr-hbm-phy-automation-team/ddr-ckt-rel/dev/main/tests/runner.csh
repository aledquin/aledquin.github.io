#!/bin/tcsh -f

# NOTE : setup your testing path using the ENV variable
#    Example:   setenv DDR_DA_MAIN /u/juliano/git-patrick-branch/ddr-ckt-rel/dev/main/
echo "#-----------------------------------------------------------"
if ( ! $?DDR_DA_MAIN ) then
    echo "You first need to set your DDR_DA_MAIN env variable"
    echo "eg. setenv DDR_DA_MAIN /u/juliano/git-patrick-branch/ddr-ckt-rel/dev/main/"
    exit -1
endif
if ( ! $?DDR_DA_DEFAULT_P4WS) then
    echo "The default workspace will be p4_func_tests"
    echo "You can change this via setenv DDR_DA_DEFAULT_P4WS other_workspace"
    setenv DDR_DA_DEFAULT_P4WS p4_func_tests
endif

echo "DDR_DA_MAIN       = '$DDR_DA_MAIN'"
echo "DDR_DA_DEFAULT_P4WS = '$DDR_DA_DEFAULT_P4WS'"
echo "P4CLIENT          = '$P4CLIENT'"

echo "Step -1: alphaHLDepotHackLibArea -p lpddr5x/d931-lpddr5x-tsmc3eff-12/rel1.00_cktpcs -p4ws p4_new_area"
../bin/alphaHLDepotHackLibArea -p lpddr5x/d931-lpddr5x-tsmc3eff-12/rel1.00_cktpcs -p4ws p4_new_area

echo "Step 9a: ./run-tests_alphaHLDepotRelPinCheck.pl"
./functional_tests/run-tests_alphaHLDepotRelPinCheck.pl
echo "Step 9b: ./run-tests_alphaPinCheck.pl"
./functional_tests/run-tests_alphaPinCheck.pl

echo "Step ?: ./run-tests_alphaHLDepotWaiver.pl"
./functional_tests/run-tests_alphaHLDepotWaiver.pl
echo "Step ?:  ./run-tests_alphaGenHiprelynxLayermap.pl"
./functional_tests/run-tests_alphaGenHiprelynxLayermap.pl
echo "Step ?: genTechrevFile.pl"
./functional_tests/run-tests_genTechrevFile.pl
echo "Step ?: alphaVerifyTimingCollateral.sh"
./functional_tests/run-tests_alphaVerifyTimingCollateral.sh
echo "Step ?: pin_check__ckt_specs.pl"
./functional_tests/run-tests_pin_check__ckt_specs.pl
echo "Step ?: alphaGdsPrep.pl"
./functional_tests/run-tests_alphaGdsPrep.pl
echo "Step ?: alphaFinishReleaseGen.pl"
./functional_tests/run-tests_alphaFinishReleaseGen.pl
echo "Step ?: alphaCompileLibs.pl"
./functional_tests/run-tests_alphaCompileLibs.pl

######################################################################################################
echo "Step 2: Seed"
./functional_tests/run-tests_alphaHLDepotSeed.pl
echo "Step 3: ExportRtl"
./functional_tests/run-tests_alphaHLDepotExportRtl.pl
echo "Step 6: BehaveRelease"
./functional_tests/run-tests_alphaHLDepotBehaveRelease.pl
echo "Step 7: PhyvRelease"
#./run-tests_alphaHLDepotPhyvRelease.pl
./functional_tests/test_alphaHLDepotPhyvRelease.pl -p4w p4_func_tests -gitlabPath ~/patrick-branch/ddr-ckt-rel/dev/main/bin -archive ~/p4_func_tests/phyv-testdata
../bin/alphaHLDepotPhyvRelease -nousage -v 2 -p /slowfs/us01dwt2p387/juliano/func_tests/phyv-testdata/juliano/verification/training/t115-training-tsmc7ffp12/rel1.00/13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2R/dwc_ddrphy_diff_io/dwc_ddrphy_diff_io_ew -p4ws p4_func_tests -dryrun

echo "Step X: alphaGenHiprelynxLayermap.pl"
./functional_tests/run-tests_alphaGenHiprelynxLayermap.pl

######################################################################################################
# we have to do this seeding as well in order for test#5 to pass in alphaHLDepotLibRelease tests
echo "Step 8: LibRelease ... preparing"
echo "Running seeding for test#5 alphaHLDepotLibRelease"
echo "../bin/alphaHLDepotSeed -p 'lpddr54/d890-lpddr54-tsmc5ff-12/rel1.00_cktpcs' -macros dwc_ddrphy_utility_blocks -p4ws $DDR_DA_DEFAULT_P4WS >& /dev/null"
../bin/alphaHLDepotSeed -p 'lpddr54/d890-lpddr54-tsmc5ff-12/rel1.00_cktpcs' -macros dwc_ddrphy_utility_blocks -p4ws $DDR_DA_DEFAULT_P4WS >& /dev/null

echo "Running seeding for test#6 alphaHLDepotLibRelease"
ehco "../bin/alphaHLDepotSeed -p 'lpddr54/d850-lpddr54-tsmc5ffp12/rel2.00_cktpcs' -macros dwc_ddrphy_utility_blocks -p4ws $DDR_DA_DEFAULT_P4WS >& /dev/null"
../bin/alphaHLDepotSeed -p 'lpddr54/d850-lpddr54-tsmc5ffp12/rel2.00_cktpcs' -macros dwc_ddrphy_utility_blocks -p4ws $DDR_DA_DEFAULT_P4WS >& /dev/null

#echo "Step 8: LibRelease ... skipping"
echo "Step 8: LibRelease ... running"
./functional_tests/run-tests_alphaHLDepotLibRelease.pl
######################################################################################################


echo "#-----------------------------------------------------------"
