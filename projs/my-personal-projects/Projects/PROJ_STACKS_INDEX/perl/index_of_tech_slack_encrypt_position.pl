use strict;
use warnings;

use env::env;

use strict;
use Devel::StackTrace;
use Data::Dumper;
use File::Copy;
use Getopt::Long;
use File::Basename qw( dirname basename);
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);

sub do_it {



    my @MSIP_CAD_PROJ_ROOT_GROUP = `find ${MSIP_PROJ_ROOT} -maxdepth 2 -mindepth 2 -name \*-${MSIP_CAD_PROJ_TECH}\[0-9-\]\*`;

    foreach my $MSIP_CAD_PROJ_ROOT (@MSIP_CAD_PROJ_ROOT_GROUP) {
        my $MSIP_CAD_PROJ_NAME ;
    }






}
