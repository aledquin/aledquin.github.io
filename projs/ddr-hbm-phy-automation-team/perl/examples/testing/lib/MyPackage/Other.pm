package MyPackage::Other;

use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec::Functions qw( catfile );
use Devel::StackTrace;
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
use Capture::Tiny qw/capture/;
use MIME::Lite;
use Data::Dumper;

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use MyPackage::Print;

print "-PERL- Loading Package: ". __PACKAGE__ . "\n";

use Exporter;
our @ISA   = qw(Exporter);
# Symbols (subs or vars) to export by default 
our @EXPORT    = qw(header footer write_file);

sub header(){
    print("--header-----------------------------------\n");
}

sub footer(){
    print("--footer-----------------------------------\n");
}

sub write_file($$) {

}

################################
# A package must return "TRUE" #
################################

1;
 
