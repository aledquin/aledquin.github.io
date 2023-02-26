package MyPackage::Graphics;
use strict;
use warnings;
use lib '..';
use MyPackage::Print;
use MyPackage::Math;

print "-PERL- Loading Package: ". __PACKAGE__ . "\n";
use FindBin qw($RealBin $RealScript);
use Exporter;
our @ISA   = qw(Exporter);
# Symbols (subs or vars) to export by default 
our @EXPORT    = qw(draw draw_add_two);

sub draw() {
    print("Draw picture...\n");
    return;    
}

sub draw_add_two($) {
    my $num = shift;
    MyPackage::Print::iprint("draw_add_two called\n");
    if ( $main::DEBUG ) {
        MyPackage::Print::iprint("iprint called DEBUG\n");
	}

    return addition(2, $num);   
}


################################
# A package must return "TRUE" #
################################

1;
 
