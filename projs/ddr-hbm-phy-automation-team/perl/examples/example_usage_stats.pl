#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use FindBin qw($RealBin  $RealScript);

use lib "$RealBin/../lib/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

our $STDOUT_LOG   = undef; # use constant EMPTY_STR to log iprint,hprint,etc messages
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = '2022ww20';

BEGIN { our $AUTHOR='your name here'; header(); }
END { write_stdout_log("${PROGRAM_NAME}.log"); footer(); }

sub Main{
    utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@ARGV );

    # body of your code goes here;  
}

Main();

