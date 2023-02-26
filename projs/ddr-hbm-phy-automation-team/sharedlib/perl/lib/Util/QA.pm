###############################################################################
# Common QA utility functions.
# Author: Harsimrat Singh Wadhawan
###############################################################################
package Util::QA;

use strict;
use warnings;

use strict;
use warnings;
use Exporter;
use Term::ANSIColor;
use Try::Tiny;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
use Util::DS;
use JSON;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
  map_check_severity parse_severities initialise_severities
);

# Symbols to export by request 
our @EXPORT_OK = qw();

# Module level variable to store severity information
my %SEVERITIES;
my %SEVERITIES_parsed;


#--------------------------------------
# Get the name of the caller of this function.
# Then check whether that function is of high priortiy or not.
# Return:   Priority found in the SEVERITIES hashtable.
#           NULL_VAL if the function is not found in the SEVERITIES hashtable.
#--------------------------------------
sub map_check_severity() {
    
    # Get the name of the function which called this funciton.
    my $parent = ( caller(1) )[3];

    if (exists($SEVERITIES_parsed{"$parent"})){
        return $SEVERITIES_parsed{"$parent"};
    }

    return NULL_VAL;

}

#--------------------------------------
# Parse the list of functions that should be marked as severe.
# The functions are specified in a JSON object with the following format
#   {
#       
#       "checkname":{"namespace::function_name": "HIGH"},
#       "checkname":{"namespace::function_name": "LOW"},
#       "checkname":{"main::my_function": "HIGH"}
#   
#   }
#--------------------------------------

sub parse_severities($) {

    my $filename = shift;

    if ($filename eq "" or $filename eq NULL_VAL){                  
        $filename = "$RealBin/../resources/severities.json";
    }

    # Debug the filename
    dprint(LOW, "Severities file: $filename.\n");

    # nolint open<
    # my $json_text = do {
    #     open(my $json_fh, "<:encoding(UTF-8)", $filename)
    #         or return NULL_VAL;
    #     local $/;
    #     <$json_fh>
    # };

    my @json_text = read_file($filename);
    my $json_text = join("", @json_text);

    # Obtain JSON object for parsing.
    my $json = JSON->new;
    
    my $answer = eval {
        $json->decode($json_text)
    };

    %SEVERITIES = ();
    %SEVERITIES_parsed = ();

    if (!$answer) {
        return %SEVERITIES_parsed;
    }

    %SEVERITIES = %{$answer};

    foreach my $key (keys %SEVERITIES){
        foreach my $keys (keys %{$SEVERITIES{$key}}){
            $SEVERITIES_parsed{$keys} = $SEVERITIES{$key}{$keys};
        }
    }

    # eprint("From module: ".Dumper(%SEVERITIES_parsed));

    return %SEVERITIES_parsed;

}

# A perl module must return TRUE
1;

__END__

