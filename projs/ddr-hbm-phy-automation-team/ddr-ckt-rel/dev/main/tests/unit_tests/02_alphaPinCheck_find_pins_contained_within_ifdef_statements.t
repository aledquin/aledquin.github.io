use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../bin/";

# Disable the annoying header and footer that gets printed out when we
# require the perl script and then exit.

our $DDR_DA_DISABLE_HEADER = 1;
our $DDR_DA_DISABLE_FOOTER = 1;


do {
    local *STDOUT;
    open(STDOUT, '>', "/tmp/ddr-ckt-rel_unit_test_${RealScript}.log") || exit -1;
    ok( require( "$RealBin/../../bin/alphaPinCheck.pl"), '01: require alphaPinCheck.pl') or exit -1;
};

sub TestMain(){
    my $scriptName = "alphaPinCheck.pl";
    my $tdata      = "$RealBin/../data";

    my %t = (
        '02' => {
            'desc'     => "File is missing test",
            'file'     => "$tdata/$scriptName/unit_test_find_pins_test_missing.v",
            'e_stat'   => -1,
            'e_npins'  => 0,
            'e_pins'   => [],
        },
        '03' => {
            'desc'     => "File exists but empty",
            'file'     => "$tdata/$scriptName/unit_test_find_pins_test_emptyfile.v",
            'e_stat'   => 0,
            'e_npins'  => 0,
            'e_pins'   => [],
        },
        '03' => {
            'desc'     => "File exists but has no ifdef _PG_PINS section",
            'file'     => "$tdata/$scriptName/unit_test_find_pins_test_no_ifdef.v",
            'e_stat'   => 0,
            'e_npins'  => 0,
            'e_pins'   => [],
        },
        '04' => {
            'desc'     => "File exists and has ifdef _PG_PINS section",
            'file'     => "$tdata/$scriptName/unit_test_find_pins_test_with_ifdef.v",
            'e_stat'   => 0,
            'e_npins'  => 2,
            'e_pins'   => [['VDD','input'],['VSS','input']],
        },
    );

#    my $ntests = keys(%t);
#    plan(1 + $ntests );
    
    foreach my $tstnum (sort keys %t) {
        my $status;
        my $href_args = $t{"$tstnum"};
        my $vfile  = $href_args->{'file'};
        my $estat  = $href_args->{'e_stat'};
        my $enpins = $href_args->{'e_npins'};
        my $desc   = $href_args->{'desc'};
        my $epins  = $href_args->{'e_pins'};

        my ($npins, $aref_pins) = find_pins_contained_within_ifdef_statements( 
            $vfile, \$status );

        my @got;
        push(@got, $status);
        push(@got, $npins);
        push(@got, $aref_pins);

        my @expected;
        push(@expected, $estat);
        push(@expected, $enpins);
        push(@expected, $epins);

        is_deeply(\@got, \@expected, "$tstnum: $desc");

    }
    
    done_testing();

    return 0;
}

&TestMain();
