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
    #
    # This data represents multiple rows of just one column of data
    #
    my @populate = (
        1,
        2,
        3,
        4,
        5,
    );
    my @expected = (
        'some comment',
        1,
        2,
        3,
        4,
        5,
    );
    #
    # This writes data into a spreadsheet sheet
    #
    my $new_spreadsheet_fname = "/tmp/02_Excel_test.xlsx";
    my $sheet_name            = "page1";
    my $comment               = "some comment";
    my $format                = undef;

    # create a new workbook; deletes any existing one of the same name
    my $workbook = &xls_open( $new_spreadsheet_fname );
    my $worksheet = $workbook->add_worksheet($sheet_name);

    &write2Excel( \@populate, $worksheet, $comment, $format );
    
    # close the created workbook
    xls_close( $new_spreadsheet_fname, $workbook );

    #
    # Now read in the data and see if the data is the same as what we wrote
    #
    my $aref_cols_rows = &read_sheet_from_xlsx_file( 
        $new_spreadsheet_fname, 
        $sheet_name );

    # Now compare against expected values
    my $ex_index=0;
    foreach my $aref_row ( @$aref_cols_rows ){
        foreach my $col_value ( @$aref_row ){
            ok( $col_value eq $expected[$ex_index++] );
        }
    }

    done_testing();
}

Main();

