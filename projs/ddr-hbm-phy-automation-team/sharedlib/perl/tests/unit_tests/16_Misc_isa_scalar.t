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
    my $warn      = "-W- Undefined value passed : 'Main -> stdout_is -> Util::Misc::isa_scalar'\n";
    my $expected  = colored( $warn, 'yellow');

    # isa_scalar for the next check passes TRUE , I believe because the @array is
    # converted to a scalar representing how many items are in the array.
    ok( TRUE  == isa_scalar( @arrvar)   , "Testing isa_scalar with array of numbers");
    ok( FALSE == isa_scalar( \@arrvar)   , "Testing isa_scalar with ref array");
    # isa_scalar for the next check passes TRUE. For some reason, passing in a hash
    # has a ref() value of SCALAR
    ok( TRUE  == isa_scalar( %hashvar )  , "Testing isa_scalar with hash");
    ok( FALSE == isa_scalar( \%hashvar ) , "Testing isa_scalar with ref hash");
    ok( TRUE  == isa_scalar( $floatvar) , "Testing isa_scalar with float");
    ok( FALSE == isa_scalar( \$floatvar) , "Testing isa_scalar with ref float");
    ok( TRUE  == isa_scalar( $scalarvar), "Testing isa_scalar with int");
    ok( FALSE == isa_scalar( \$scalarvar), "Testing isa_scalar with ref int");
    #ok( FALSE == isa_scalar(undef) , "Testing isa_scalar with undef");
    ok( stdout_is(\&isa_scalar, undef, $expected) , "Testing isa_scalar with undef");
    ok( TRUE  == isa_scalar( $stringvar) , "Testing isa_scalar with string"); 
    ok( FALSE == isa_scalar( \$stringvar), "Testing isa_scalar with ref string"); 
    # isa_scalar for the next check passes TRUE , I believe because the @array is
    # converted to a scalar representing how many items are in the array. So it
    # does become a number.
    ok( TRUE  == isa_scalar( @str_arrvar)   , "Testing isa_scalar with array of strings"); 
    ok( FALSE == isa_scalar( \@str_arrvar)   , "Testing isa_scalar with ref array of strings"); 
    ok( FALSE == isa_scalar( \$stringvar)    , "Testing isa_scalar with ref string"); 
    ok( FALSE == isa_scalar( \$stringvar_num), "Testing isa_scalar with ref string number"); 
    ok( FALSE == isa_scalar( \$stringvar_num), "Testing isa_scalar with ref string number"); 


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

