0DEVEL0PER_README.txt                                   10/3/2022

HISTORY:
001 ljames  10/3/2022
    Created this document.

The purpose of this README is to have a record/knowledge of things that might
be difficult to discover on your own. 


1.0 Prevent Old Release Versions from running

    We have a text file that lists version numbers that should be treated
    as obsolete. We have a Misc.pm function that checks this file.

    the file is:
        /remote/proj/alpha/alpha_common/bin/ddr_da_releases.txt

    the Misc.pm function is:
        Util::Misc::da_is_script_in_list_of_obsolete_versions

    the Misc.pm function actually runs a script to determine this. The
    script will return BLOCKED or NOTBLOCKED 

    the script is:
        /admin/da_is_script_in_list_of_obsolete_versions.pl

1.1 How to bypass the blocking of obsolete scripts for testing/debugging

    The developer will need to have alpha_common/bin in their perforce
    repository.  They can then edit the ddr_da_releases.txt file to comment
    out any versions that you need to access.  Then the developer will need
    to submit those changes to perforce.  This is required so that the file
    gets to the mirrored sites (aka.  /remote/proj/alpha/alpha_common/bin )

    When the developer is finished testing /debugging things, they should 
    then restore the ddr_da_releases.txt file back to the way it was.


2.0 Environment Variables for development and testing

    We have a number of environment variables that we use in order to run
    our tests and makefiles in our DDR DA environment. Here is a list of
    the know env variables.  (NOTE: this is subject to change, and so this
    info could become outdated)

Env Name                Value(s)                             Purpose
----------------------  ------------------------------  ----------------------
DDR_DA_DEFAULT_P4WS     p4_ws|p4_nightly_runs|etc...    functional tests to point to another perforce repository
DDR_DA_MAIN             Points to the tool's /main dir  Testing ddr-ckt-rel
DDR_DA_TIMEBOMB_FILE    filename                        Debug timebomb feature
DDR_DA_SKIP_USAGE       anything                        Testing/avoid usuage stats calls
DDR_DA_COMPARATOR_DIFF  1                               To enable the comparator's diff feature during testing.
DDR_DA_TESTING          anything                        In case any scripts need to do something special during testing
DDR_DA_COVERAGE         anything                        Let's the scripts know that coverage is going to be captured.
                                                        Used by adjust_cmd_for_perl_coverage function; for many ddr scripts
                                                        that need to call another script.
DDR_DA_COVERAGE_DB      directory path                  When -coverage is used with the ddr test scripts, this env variable
                                                        is used to tell the coverage tool where to create the coverage database.
DDR_DA_SKIP_YAML_FIRSTAVAILABLEFILE anything            To test the code that reads legalRelease.txt files when also present is the
                                                        legalRelease.yaml file. Force tests to ignore .yaml files.
DA_TEST_NOGUI           anything                        Was used to bypass code that might popup a dialog box; 
                                                        I don't see it used anymore in our code
GITROOT                 to top of your gitlab folder    Used by golden Makefile.include (in /admin) so it knows 
                                                        where your GitLab is located
TOOL                    the name of the ddr tool        Used by golden Makefile.include (in /admin) ; this is 
                                                        usually set in each tools's  /dev/main/Makefile before 
                                                        including the golden Makefile.include file
    
