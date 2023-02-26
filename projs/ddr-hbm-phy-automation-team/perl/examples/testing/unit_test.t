#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;

use Devel::StackTrace;
use Data::Dumper;
use File::Copy;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);
#use Test::More tests => 6;
use Test2::Bundle::More;

use lib "$RealBin/lib";
use MyPackage::Print;
use MyPackage::Math ;
use MyPackage::Graphics;
use MyPackage::Other;

#----------------------------------#
our $STDOUT_LOG   = undef;
our $DEBUG        = 1;
our $VERBOSITY    = 0;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = '1.0';
#----------------------------------#


BEGIN { plan(3); header(); }
END { write_stdout_log("test.log"); draw_add_two(1); footer(); }

sub Main() {
    my $result;
    # ok( boolean_expression,  note )
    ok(draw_add_two(1) == 3 , "Main->draw_add_two");
    ok(addition(10, 10) == 20, "Main->addition");
    ok(MyPackage::Math::subtraction(10, 10) == 0, "Main->subtraction");
    draw();
    exit(0);
}

Main();

