use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
#use Test2::Tools::Compare;
use Test2::Bundle::More;
use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
use Util::P4;

our $PROGRAM_NAME = $0;
our $AUTHOR_NAME  = 'ahmedhes';
#----------------------------------#
our $DEBUG         = NONE;
our $VERBOSITY     = NONE;
our $DEBUG_LOG     = undef;
our $FPRINT_NOEXIT = TRUE;
#----------------------------------#


Main();

########  YOUR CODE goes in Main  ##############
sub Main {
    utils__process_cmd_line_args();
    # Current planned test count
    plan(11);
    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__prompt_user_yesno();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
sub setup_tests__prompt_user_yesno() {
    my $subname = 'prompt_user_yesno';

    #-------------------------------------------------------------------------
    #  Test 'prompt_user_yesno'
    #-------------------------------------------------------------------------
    my %test1 = (
        'message'      => "Test message?", 
        'stdin'        => "Y\n",
        'expectReturn' => "Y",
        'expectPrint'  => colored("-I- Test message? [Y/N]\n", 'bright_yellow'),
        'name'         => "No default; STDIN Y",
    );

    my %test2 = (
        'message'      => "Test message?", 
        'extraArgs'    => "Y",
        'stdin'        => "Ye\n",
        'expectReturn' => "Y",
        'expectPrint'  => colored("-I- Test message? [Y/n]\n", 'bright_yellow'),
        'name'         => "Yes; STDIN Ye",
    );


    my %test3 = (
        'message'      => "Test message?", 
        'extraArgs'    => "N",
        'stdin'        => "Yes\n",
        'expectReturn' => "Y",
        'expectPrint'  => colored("-I- Test message? [y/N]\n", 'bright_yellow'),
        'name'         => "No; STDIN Yes",
    );

    my %test4 = (
        'message'      => "Test message?", 
        'stdin'        => "N\n",
        'expectReturn' => "N",
        'expectPrint'  => colored("-I- Test message? [Y/N]\n", 'bright_yellow'),
        'name'         => "No default; STDIN N",
    );

    my %test5 = (
        'message'      => "Test message?", 
        'extraArgs'    => "Y",
        'stdin'        => "No\n",
        'expectReturn' => "N",
        'expectPrint'  => colored("-I- Test message? [Y/n]\n", 'bright_yellow'),
        'name'         => "Yes; STDIN No",
    );

    my %test6 = (
        'message'      => "Test message?", 
        'extraArgs'    => "N",
        'stdin'        => "no\n",
        'expectReturn' => "N",
        'expectPrint'  => colored("-I- Test message? [y/N]\n", 'bright_yellow'),
        'name'         => "No; STDIN no",
    );

    my %test7 = (
        'message'      => "Test message?", 
        'stdin'        => "\n" x 10,
        'expectReturn' => "",
        'expectPrint'  => colored("-I- Test message? [Y/N]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [Y/N]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [Y/N]\n", 'bright_yellow'),
        'name'         => "No default; STDIN EMPTY_STR",
    );

    my %test8 = (
        'message'      => "Test message?", 
        'extraArgs'    => "Y",
        'stdin'        => "\n",
        'expectReturn' => "Y",
        'expectPrint'  => colored("-I- Test message? [Y/n]\n", 'bright_yellow'),
        'name'         => "Yes; STDIN EMPTY_STR",
    );

    my %test9 = (
        'message'      => "Test message?", 
        'extraArgs'    => "N",
        'stdin'        => "\n",
        'expectReturn' => "N",
        'expectPrint'  => colored("-I- Test message? [y/N]\n", 'bright_yellow'),
        'name'         => "No; STDIN EMPTY_STR",
    );

    my %test10 = (
        'message'      => "Test message?", 
        'extraArgs'    => "Y 5",
        'stdin'        => "a\n" x 4 . "\n",
        'expectReturn' => "Y",
        'expectPrint'  => colored("-I- Test message? [Y/n]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [Y/n]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [Y/n]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [Y/n]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [Y/n]\n", 'bright_yellow'),
        'name'         => "Yes; STDIN a x 4, EMPTY_STR; limit: 5",
    );

    my %test11 = (
        'message'      => "Test message?", 
        'extraArgs'    => "N 5",
        'stdin'        => "a\n" x 4 . "\n",
        'expectReturn' => "N",
        'expectPrint'  => colored("-I- Test message? [y/N]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [y/N]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [y/N]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [y/N]\n", 'bright_yellow').
                          colored("-W- The answer is not Y or N, please try again!\n", 'yellow').
                          colored("-I- Test message? [y/N]\n", 'bright_yellow'),
        'name'         => "No; STDIN a x 4, EMPTY_STR; limit: 5",
    );

    my @tests = (\%test1, \%test2, \%test3, \%test4, \%test5, \%test6, \%test7,
                 \%test8, \%test9, \%test10, \%test11);

    foreach my $cnt (@tests) {
        my %testcase = %{$cnt};
        do{
            local *STDIN;
            pipe( STDIN, my $stdin_wtr );
            $stdin_wtr->autoflush(1);

            print $stdin_wtr $testcase{stdin};
            ok(stdout_is(\&prompt_user_yesno, \%testcase), $testcase{name});
            close $stdin_wtr;
        };
    }
}

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'testXXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}

sub stdout_is($$) {
    my $ref_sub       = shift;
    my $href_testcase = shift;
    my $temp_file     = get_temp_filename();
    my $ret;
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0;
        my @args = $href_testcase->{message};
        push(@args, split(" ",$href_testcase->{extraArgs})) if( defined($href_testcase->{extraArgs}) );
        $ret = $ref_sub->(@args);
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    close($fh);
    my $printed = join("", @lines);
    #unlink($temp_file) if ( -e $temp_file);
    return( $printed eq $href_testcase->{expectPrint} && $ret eq $href_testcase->{expectReturn} );
}

1;
