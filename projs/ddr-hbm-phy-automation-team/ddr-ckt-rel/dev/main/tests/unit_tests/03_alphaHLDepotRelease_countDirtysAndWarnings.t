use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;
use Util::CommonHeader;
use Util::Messaging;
use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...


our $DEBUG = NONE;
our $VERBOSITY = NONE;

sub Main() {
    plan(8);

    my $fileName = generateFile01();
    my ($count, $nwarnings) = countDirtysAndWarnings( $fileName );
    ok( $count==4,     "countDirtysAndWarnings good count test $count");
    ok( $nwarnings==3, "countDirtysAndWarnings good count of warnings test $nwarnings");
    unlink( $fileName ); # CLEANUP

    $fileName = generateFile02();
    ($count, $nwarnings) = countDirtysAndWarnings( $fileName );
    ok( $count==2,     "countDirtysAndWarnings good count test $count");
    ok( $nwarnings==1, "countDirtysAndWarnings good count of warnings test $nwarnings");
    unlink( $fileName ); # CLEANUP

    $fileName = generateFile03();
    ($count, $nwarnings) = countDirtysAndWarnings( $fileName );
    ok( $count==2,     "countDirtysAndWarnings good count test $count");
    ok( $nwarnings==1, "countDirtysAndWarnings good count of warnings test $nwarnings");
 
    $fileName = generateFile04();
    ($count, $nwarnings) = countDirtysAndWarnings( $fileName );
    ok( $count==2,     "countDirtysAndWarnings good count test $count");
    ok( $nwarnings==1, "countDirtysAndWarnings good count of warnings test $nwarnings");

    done_testing();

    return 0;
}

sub generateFile01() {
    # Using what is known as a "here document" to construct the output
    my $items = <<'EOL';
Dirty
clean
Error
clean
Warning
Warning
Warning
clean
clean
Error
clean
Dirty
clean
clean
EOL

    my $fname = "/tmp/countDirtysAndWarnings$$.input";
    return writeTheFile( $fname, $items );
}

sub generateFile02() {
    # Using what is known as a "here document" to construct the output
    my $items = <<'EOL';
Dirty
Error
Warning
EOL

    my $fname = "/tmp/countDirtysAndWarnings$$.input";
    return writeTheFile( $fname, $items );
}

sub generateFile03() {
    # Using what is known as a "here document" to construct the output
    my $items = <<'EOL';
-I- Dirty
-E- Error
-W- Warning
EOL

    my $fname = "/tmp/countDirtysAndWarnings$$.input";
    return writeTheFile( $fname, $items );
}

sub generateFile04() {
    # Using what is known as a "here document" to construct the output
    my $items = "-I- Dirty\n";
    my $error = colored("-E- Error Message", 'red');
    my $warning = colored("-W- Warning Message", 'yellow');

    $items = "${items}${error}\n";
    $items = "${items}${warning}\n";

    my $fname = "/tmp/countDirtysAndWarnings$$.input";
    return writeTheFile( $fname, $items );
}


sub writeTheFile($) {
    my $fileName = shift;
    my $items    = shift;
    
    open(*FH, ">", "$fileName") || die;
    foreach my $item ( split /\n/,$items ) {
        print FH "$item\n";
    }
    close(*FH);
    return $fileName;
}

Main();

