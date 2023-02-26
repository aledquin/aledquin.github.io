package MyPackage::Print;
use strict;
use warnings;

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use MyPackage::Math;
use MyPackage::Other;

print "-PERL- Loading Package: ". __PACKAGE__ . "\n";

use Exporter;
our @ISA   = qw(Exporter);
# Symbols (subs or vars) to export by default 
our @EXPORT    = qw(iprint write_stdout_log);
our @EXPORT_OK = qw();

sub iprint($) {
    my $msg = shift;
    print("-I- $msg");
    return 0;
}

sub write_stdout_log($){
    my $filename = shift;
    write_file("test", $filename);
}

################################
# A package must return "TRUE" #
################################

1;
 
