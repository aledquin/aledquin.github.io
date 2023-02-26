use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::Excel;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 

sub Main() {
    # Note: this path assumes that the testing is done from one level above
    #       where this test script is located.
    my $filename = "$RealBin/../data/test01_4cols_2rows.xlsx";
    my $sheetname = "page1";
    my @expected = (
        'HeadingA',
        'HeadingB',
        'HeadingC',
        'HeadingD',
        1,2,3,4,
        5,6,7,8);

    my $aref_cols_rows = &read_sheet_from_xlsx_file( $filename, $sheetname );
    my $ex_index=0;
    foreach my $aref_row ( @$aref_cols_rows ){
        foreach my $col_value ( @$aref_row ){
             ok( $col_value eq $expected[$ex_index++] );
        }
    }

    done_testing();
}

Main();

