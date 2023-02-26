#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use YAML::XS qw(LoadFile);
use Data::Dumper qw(Dumper);

#nolint utils__script_usage_statistics

sub Main(){
    my $fname = shift @ARGV;
    if ( $fname eq "-help" ){
        return 0;
    }

    my $yaml_data = LoadFile( $fname );
    print Dumper $yaml_data;


    # print ($yaml_data->{supply_pins_override}->{patrick} );

}

Main();

