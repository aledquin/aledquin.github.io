#!/depot/perl-5.14.2/bin/perl -w
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Getopt::Std;
use Data::Dumper;
use File::Basename qw{ dirname };
use File::Spec::Functions qw{ catfile };
use Cwd qw{ abs_path };
use Carp qw{cluck confess croak};
use Test2::Bundle::More;
use Term::ANSIColor;
use FindBin qw($RealBin $RealScript);
# use Switch;

use lib "$RealBin/../../lib/perl/";
use lib "$RealBin";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
use Util::QA;
# use utilities;

use lib::test_get_number_random;

our $PROGRAM_NAME = $0;
our $AUTHOR_NAME  = 'Harsimrat Wadhawan';

#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $DEBUG_LOG = undef;

#----------------------------------#

Main();

########  YOUR CODE goes in Main  ##############
sub Main {

    utils__process_cmd_line_args();

    # Current planned test count
    plan(12);

    #-------------------------------------------------------------------------
    #  Test 'get_number'
    #-------------------------------------------------------------------------
    manual_tests__alert();    
    #-------------------------------------------------------------------------

    done_testing();
    exit(0);
}
############    END Main    ####################

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'testXXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}

#-------------------------------------------------------------------------
#  Test harness for alert function when used with 2 arguments. 
#  Borrowed from sharedlib message testing functions.
#-------------------------------------------------------------------------
sub stdout_is_4($$$$) {
    my $ref_print  = shift;
    my $fail_pass  = shift;
    my $print_what = shift;
    my $expected   = shift;
    my $temp_file  = get_temp_filename();
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0; # nolint open<
        $ref_print->($fail_pass, $print_what);
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0; #nolint open<
    my @lines = <$fh>;
    close($fh);
    is_deeply($lines[0], $expected);
}

#-------------------------------------------------------------------------
#  Test harness for alert function when the integer parameter is actually an array.
#  Borrowed from sharedlib message testing functions.
#-------------------------------------------------------------------------
sub stdout_is_array_test() {    

    my $print_what = "ABC";
    my $expected = colored ("WARNING: ", "blue") . "$print_what\n";
    my $temp_file  = get_temp_filename();
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0; # nolint open<
        alert([1, 2, 3], $print_what);
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0; #nolint open<
    my @lines = <$fh>;
    close($fh);
    is_deeply($lines[0], $expected);
}

#-------------------------------------------------------------------------
#  Test harness for alert function when used with 3 arguments. 
#  Borrowed from sharedlib message testing functions.
#-------------------------------------------------------------------------
sub stdout_is_5($$$$$) {
    my $ref_print   = shift;
    my $fail_pass   = shift;
    my $print_what  = shift;
    my $criticality = shift;
    my $expected    = shift;
    my $temp_file   = get_temp_filename();
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0; # nolint open<
        $ref_print->($fail_pass, $print_what, $criticality);
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0; #nolint open<
    my @lines = <$fh>;
    close($fh);
    is_deeply($lines[0], $expected);
}

#-------------------------------------------------------------------------
#  Setup manual tests to exercise the alert subroutine
#-------------------------------------------------------------------------
sub manual_tests__alert() {

    my $subname = 'alert';
    my $cnt     = 1;

    my $PASS = 1;
    my $FAIL = 0;
    
    my @array = (1 , 2 , 4);
    my $array_ref = \@array;

    # TEST GREEN
    my $input1 = "This is a test1.";
    my $expected1 = colored ("PASS: ",'green') . "$input1\n";
    stdout_is_4(\&alert, $PASS, $input1, $expected1);

    # TEST RED
    my $input2 = "This is a test1.";
    my $expected2 = colored ("FAIL: ",'red') . "$input2\n";
    stdout_is_4(\&alert, $FAIL, $input2, $expected2);

    # TEST RED CRITICALITY
    my $input3 = "This is a test1.";
    my $expected3 = colored ("FAIL:CRITICAL:LOW: ",'red') . "$input3\n";
    stdout_is_5(\&alert, $FAIL, $input3, "LOW", $expected3);

    # TEST GREEN CRITICALITY
    my $input4 = "This is a test1.";
    my $expected4 = colored ("PASS:CRITICAL:LOW: ",'green') . "$input4\n";
    stdout_is_5(\&alert, $PASS, $input4, "LOW", $expected4);

    # TEST STRING INTEGER
    my $input5 = "This is a test1.";
    my $expected5 = colored ("WARNING: ",'blue') . "$input5\n";
    stdout_is_4(\&alert, 1123, $input5, $expected5);

    # TEST INVALID INTEGER
    my $input6 = "This is a test1.";    
    my $expected6 = colored ("WARNING: ",'blue') . "$input6\n";
    stdout_is_4(\&alert, $array_ref, $input6, $expected6);

    # TEST INTEGER WHEN SPECIFIED AS AN ARRAY LENGTH
    my $input7 = "This is a test1.";    
    my $expected7 = colored ("WARNING: ",'blue') . "$input7\n";
    stdout_is_4(\&alert, @array, $input7, $expected7);

    # TEST INTEGER WHEN SPECIFIED AS A STRING
    my $input8 = "This is a test1.";    
    my $expected8 = colored ("FAIL: ",'red') . "$input8\n";
    stdout_is_4(\&alert, "0", $input8, $expected8);

    # TEST INTEGER WHEN SPECIFIED AS A STRING
    my $input9 = "This is a test1.";    
    my $expected9 = colored ("WARNING: ",'blue') . "$input9\n";
    stdout_is_4(\&alert, "-17", $input9, $expected9);

    # TEST INTEGER WHEN SPECIFIED AS AN ARRAY
    stdout_is_array_test();

    # TEST INTEGER WHEN SPECIFIED AS A STRING
    my $input10 = "This is a test1.\n\n\n\n\n\n";    
    my $expected10 = colored ("PASS: ",'green') . "This is a test1.\n";
    stdout_is_4(\&alert, 1, $input10, $expected10);

    # TEST INTEGER WHEN SPECIFIED AS A STRING
    my $input11 = "This is a test1.";    
    my $expected11 = colored ("PASS: ",'green') . "$input11\n";
    stdout_is_4(\&alert, "1", $input11, $expected11);

}

1;
