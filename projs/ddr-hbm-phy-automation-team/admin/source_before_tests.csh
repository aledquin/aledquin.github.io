# Source this file before automated tests
# TODO: Fix $GITROOT and $tool
export DDR_DA_DEFAULT_P4WS=p4_nightly_runs
export DDR_DA_SKIP_USAGE=1
export DA_RUNNING_UNIT_TESTS=1

export DA_TEST_NOGUI=1

export P4CLIENT=msip_cd_ljames_nightly_runs
export P4PORT='p4p-us01:1999'

export gitlab=/tmp/$USER/gitlab
#export GITROOT=$gitlab/ddr-hbm-phy-automation-team
export DDR_DA_COVER_DB=${GITROOT}/${tool}_cover_db
export DDR_DA_MAIN=$GITROOT/${tool}/dev/main
