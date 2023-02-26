############################################################
#  Constants to be used in all new scripts 
#
#  Author : James Laderoute
############################################################
package Util::CommonHeader;

use strict;
use warnings;


use base 'Exporter';
our @EXPORT = qw[TRUE FALSE NULL_VAL NFS EMPTY_STR NONE LOW MEDIUM FUNCTIONS HIGH SUPER CRAZY INSANE];

#----------------------------------#
use constant TRUE  => 1;
use constant FALSE => 0;
#----------------------------------#
use constant NULL_VAL  => 'N/A';
use constant NFS       => qr|[^/]+|;  # not forward slash
use constant EMPTY_STR => '';         # Empty String
#----------------------------------#
# Debug Diagnostic Levels
#----------------------------------#
use constant NONE      => 0;
use constant LOW       => 1;
use constant MEDIUM    => 2;
use constant FUNCTIONS => 3;
use constant HIGH      => 4;
use constant SUPER     => 5;
use constant CRAZY     => 6;
use constant INSANE    => 100;

1;
