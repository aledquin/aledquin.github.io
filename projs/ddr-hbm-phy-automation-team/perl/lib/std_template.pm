###############################################################################
# Description of this perl module goes here
#
# Author: name of person who created this
###############################################################################
package std_template;

use strict;
use warnings;


use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;

use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
  template_func_1 template_func_2 
);

# Symbols to export by request 
our @EXPORT_OK = qw();

#--------------------------------------
sub template_func_1($$) {
    my $arg1 = shift;
    my $arg2 = shift;

    return;
}

#--------------------------------------
sub template_func_2($$) {
    my $arg1 = shift;
    my $arg2 = shift;

    return;
}

################################
# A package must return "TRUE" #
################################

1;


__END__

#-----------------------------------------------------------------------------
#                        DOCUMENTATION using POD
#-----------------------------------------------------------------------------
#
# The recommended order of sections in Perl module documentation is:
#
#    NAME
#
#    SYNOPSIS
#
#    DESCRIPTION
#
#    One or more sections or subsections giving greater detail of available
#    methods and routines and any other relevant information.
#
#    BUGS/CAVEATS/etc
#
#    AUTHOR
#
#    SEE ALSO
#
#    COPYRIGHT and LICENSE
#
#
#-----------------------------------------------------------------------------
#
#=cut
#
#      include a blank line after =cut for this lets Perl (and the Pod 
#      formatter) know that this is where Perl code is resuming.  (The blank 
#      line before the "=cut" is not technically necessary, but many older 
#      Pod processors require it.
