package MyPackage::Math;

use strict;
use warnings;

print "-PERL- Loading Package: ". __PACKAGE__ . "\n";

use Exporter;
our @ISA   = qw(Exporter);
# Symbols (subs or vars) to export by default 
our @EXPORT    = qw(addition);
# Symbols to export by request
our @EXPORT_OK = qw(subtraction);

# use Test::Builder::Module;

sub addition($$) {
    my $num1 = shift;
    my $num2 = shift;

#    my $Test = Test::Builder::Module->builder;
#    $Test->ok(($num1+$num2)==($num1+$num2), 'Math::addition' );

    return $num1 + $num2;
}

sub subtraction($$) {
    my $num1 = shift;
    my $num2 = shift;
    return $num1 - $num2;
}

################################
# A package must return "TRUE" #
################################

1;
 
