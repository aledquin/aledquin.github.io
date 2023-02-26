use strict;
use warnings;
use v5.14.2;

use Capture::Tiny ':all';
use Test2::Bundle::More;
use Test2::Tools::Compare;
use File::Temp;
use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;

sub Main() {
    plan(16);

    my @arrvar    = (1,2);
    my @str_arrvar= ("ab", "cd");
    my %hashvar   = ( 'a'=>3 );
    my $scalarvar = 10;
    my $floatvar  = 23.32;
    my $stringvar_num = "32";
    my $stringvar = "jim";
    my $warn      = "-W- Undefined value passed : 'Main -> stdout_is -> Util::Misc::isa_num'\n";
    my $expected  = colored( $warn, 'yellow');

    ok( TRUE  == isa_num( @arrvar)    , "Testing isa_num with array of numbers");
    ok( FALSE == isa_num( \@arrvar)   , "Testing isa_num with ref array");
    ok( FALSE == isa_num( %hashvar )  , "Testing isa_num with hash");
    ok( FALSE == isa_num( \%hashvar ) , "Testing isa_num with ref hash");
    ok( TRUE  == isa_num( $floatvar)  , "Testing isa_num with float");
    ok( FALSE == isa_num( \$floatvar) , "Testing isa_num with ref float");
    ok( TRUE  == isa_num( $scalarvar) , "Testing isa_num with int");
    ok( FALSE == isa_num( \$scalarvar), "Testing isa_num with ref int");
    ok( stdout_is(\&isa_num, undef, $expected) , "Testing isa_num with undef");
    ok( FALSE == isa_num( $stringvar) , "Testing isa_num with string"); 
    ok( FALSE == isa_num( \$stringvar), "Testing isa_num with ref string"); 
    # isa_num for the next check passes TRUE , I believe because the @array is
    # converted to a scalar representing how many items are in the array. So it
    # does become a number.
    ok( TRUE  == isa_num( @str_arrvar), "Testing isa_num with array of strings"); 
    ok( FALSE == isa_num( \@str_arrvar), "Testing isa_num with ref array of strings"); 
    ok( FALSE == isa_num( \$stringvar), "Testing isa_num with ref string"); 
    ok( FALSE == isa_num( \$stringvar_num), "Testing isa_num with ref string number"); 
    ok( FALSE == isa_num( \$stringvar_num), "Testing isa_num with ref string number"); 


    done_testing( );
    return(1); 
}
sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'testXXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}

sub stdout_is($$$) {
    my $ref_print  = shift;
    my $print_what = shift;
    my $expected   = shift;
    my $temp_file  = get_temp_filename();
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0;
        my $result = $ref_print->($print_what);
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    close($fh);
    #unlink($temp_file) if ( -e $temp_file);
    return( $lines[0] eq $expected);
}


Main();

