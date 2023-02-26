###############################################################################
# IBIS test library routines
#
# Author: Harsimrat Singh Wadhawan
###############################################################################
package lib::testlib;

use strict;
use warnings;

print "-PERL- Loading Package: ". __PACKAGE__ . "\n";

use FindBin qw($RealBin $RealScript);
use Exporter;

use lib "$FindBin::Bin/../../lib/perl";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
use Util::P4;

use Exporter;
use Data::Dumper;
use List::Util 'first';  
use List::Util qw(shuffle);

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
  filter_projects 
);

# Symbols to export by request 
our @EXPORT_OK = qw();

################################################
# -- Get valid, and random, projects 
#     to test the script on
################################################
sub filter_projects($) {

    my $limit = shift;

    iprint("Generating testcases.\n");

    # Get the product families.
    my $BASE_PATH = "//depot/products/*";                  
    my @products = da_p4_dirs($BASE_PATH); 
    dprint SUPER, Dumper(@products)."\n";        

    if (@products) {
        for (my $i = 0; $i < @products; $i++){
            $products[$i] =~ chomp $products[$i];
            $products[$i] =~ s/$BASE_PATH\///ig;
        }
    }
    else {
        fatal_error "Could not find product families.\n";
    }
    dprint HIGH, Dumper(@products)."\n";

    # Get the projects
    my @project_hash;
    foreach my $product (@products) {

        iprint("Finding project(s) for $product.\n");
        my $path = "//depot/products/$product/project";

        if ($product =~ /lpddr5x_ddr5_phy/){
            
            if ( int(rand(10)) % 2 ) {
                $path = "//depot/products/lpddr5x_ddr5_phy/ddr5/project";
            }

            else {
                $path = "//depot/products/lpddr5x_ddr5_phy/lp5x/project";
            }
            
        }

        my @projects = da_p4_dirs("$path/*");        
        @projects = shuffle(@projects); 
        dprint (SUPER, Dumper(@projects)."\n");

        if (@projects) {
            
            my $selected = 0;
            
            for (my $i = 0; $i < @projects; $i++){
                $projects[$i] =~ chomp $projects[$i];
                $projects[$i] =~ s/$path\///ig;

                if ($projects[$i] =~ /^d[0-9]/ig) {
                                        
                    my @macros = da_p4_dirs("$path/$projects[$i]/ckt/rel/*");
                    
                    @macros = shuffle (@macros);

                    my $match = first { /(txrx)|(sec?io)/ } @macros;
                    
                    if ( $match ) {

                        my @releases = da_p4_dirs("$match/*/macro/ibis");                                                                        
                        @releases = shuffle (@releases);

                        my $A = $releases[0];
                        $A =~ s/\/macro\/ibis//g;
                        my @ANSWER = split("/", $A);                        

                        my @splat = split("/", $match);
                        my $macro =  $splat[-1];

                        my %data = (                         
                            'product' => $product,
                            'project' => $projects[$i],
                            'release' => "$ANSWER[@ANSWER-1]",
                            'macro'  => $macro
                        );

                        if ( $A ne NULL_VAL ) {

                            push (\@project_hash, \%data);
                            $selected++;

                        }


                    }
                   
                }

                if ($selected > $limit){
                    last;
                }

            }

        }

        else {
            wprint("Could not find product families.\n");
        }        

    }    

    return \@project_hash;

}

################################
# A package must return "TRUE" #
################################

1;

__END__

-----------------------------------------------------------------------------
                       DOCUMENTATION using POD
-----------------------------------------------------------------------------

The recommended order of sections in Perl module documentation is:

    NAME - Testlib
   
    DESCRIPTION

    Contains subroutines that are commonly used during testing. 
   
    AUTHOR

    HSW

    SEE ALSO

    module load ibis

    COPYRIGHT and LICENSE

    2021-2022. Synopsys. 
-----------------------------------------------------------------------------

=cut
