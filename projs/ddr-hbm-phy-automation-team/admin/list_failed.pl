#!/depot/perl-5.14.2/bin/perl
#
# This script is called by nightly_run.csh
#
use strict;
use warnings;
use File::Basename;

#nolint utils__script_usage_statistics
sub Main(){
    my $log_file = shift @ARGV;
    if ( $log_file eq "-help"){
        exit(0);
    }

    my $username = getlogin() || getpwuid($<) || $ENV{'USER'};

    open(my $fh, "<", $log_file) || die "Can't open '$log_file': $!"; #nolint open<
    my @input_text = <$fh>;
    close($fh);

    my $output = "";

    my $have_sendmail=`which sendmail`;  #nolint backticks 
    foreach my $line ( @input_text ) {
        chomp $line;
        if ( $line =~ m/(.*) makefile for (.*)/ ){
            my $condition = $1; # PASSED FAILED
            my $tool      = $2;

            my $lint_fail     = 0;
            my $tcl_lint_fail = 0;
            my $compile_fail  = 0;
            my $test_fail     = 0;

            if ( $condition =~ m/PASSED/ ) {
                $condition = "PASSED";
            } else {
                $condition = "FAILED";

                $lint_fail = `grep 'FAILED LINT' /tmp/${username}/tests_output/${tool}_run_before_checkin_make.log | wc --lines`;
                chomp $lint_fail;
                $lint_fail = 0 if ( $lint_fail eq "");

                $tcl_lint_fail = `grep 'FAILED TCL LINT' /tmp/${username}/tests_output/${tool}_run_before_checkin_make.log | wc --lines`;
                chomp $tcl_lint_fail;
                $tcl_lint_fail = 0 if ( $tcl_lint_fail eq "");

                $compile_fail = `grep 'FAILED COMPILE' /tmp/${username}/tests_output/${tool}_run_before_checkin_make.log | wc --lines`;
                chomp $compile_fail;
                $compile_fail = 0  if ( $compile_fail eq "");

                #print("looking for 'FAILED.*tests/.*' in file /tmp/${username}/tests_output/${tool}_run_before_checkin_make.log\n");
                $test_fail = `grep -P '^FAILED.*functional_tests.*' /tmp/${username}/tests_output/${tool}_run_before_checkin_make.log | wc --lines`;
                chomp $test_fail;
                $test_fail = 0 if  ($test_fail eq "");

                my $test_fail_more = `grep -P '^FAILED.*See.*' /tmp/${username}/tests_output/${tool}_run_before_checkin_make.log | wc --lines`;
                chomp $test_fail_more;
                $test_fail_more = 0 if  ($test_fail_more eq "");
                $test_fail = $test_fail + $test_fail_more;
            }

            my $total_lint_fail = $lint_fail + $tcl_lint_fail;
            if ( "$have_sendmail" eq "" ){ 
                $output .= "$tool $condition              " if ( $condition eq "FAILED" );
                $output .= "linting   $total_lint_fail    " if ( $total_lint_fail);
                $output .= "                              " if ( $total_lint_fail);
                $output .= "compiling $compile_fail       " if ( $compile_fail); 
                $output .= "                              " if ( $compile_fail);
                $output .= "func/unit $test_fail          " if ( $test_fail); 
                $output .= "                              " if ( $test_fail); 
            }else{
                $output .= "<br>$tool $condition<br>      " if ( $condition eq "FAILED" );
                $output .= "linting   $total_lint_fail<br>" if ( $total_lint_fail);
                $output .= "compiling $compile_fail<br>   " if ( $compile_fail); 
                $output .= "func/unit $test_fail<br>      " if ( $test_fail); 
            } 
        }

    }

    print "$output";
    return;
}

Main();

