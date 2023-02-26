#!/depot/perl-5.14.2/bin/perl

use strict;
use Cwd;
use Carp;
use File::Spec::Functions qw/catfile/;
use Devel::StackTrace;
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
use Term::ANSIColor;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use FindBin;
use lib "$FindBin::Bin/../lib";
#use Util::CommonHeader;
#use Util::Misc;

BEGIN { }

	Main();

END { }


######################################### Main function ############################################
sub Main {

    my ($help, $macro, $rel, $ref, $view);
    my $MERGE_EXE = '/depot/perforce-2019.2/p4merge'; 

	GetOptions(
		"help|h"	=>	\$help,
		"macro=s"	=>	\$macro,
		"view=s"	=>	\$view,
		"rel=s"		=>	\$rel,
		"ref=s"		=>	\$ref,
	);
    
    open(my $rf, "<$ref") || print "Unable to open file $ref:$!\n";
    open(my $rl, "$rel") || print "Unable to open file $rel:$!\n";
    
    my @masterManifest = <$rf>;
    my @release = <$rl>;
    
    if(defined($macro) && defined($view)) {
        @masterManifest = grep(/\/$view\// && /\/$macro\//,@masterManifest);
        @release = grep(/\/$view\// && /\/$macro\//,@release);
    } elsif (defined($macro)) {
        @masterManifest = grep(/\/$macro\//,@masterManifest);
        @release = grep(/\/$macro\//,@release);
    } elsif (defined($view)) {
        @masterManifest = grep(/\/$view\//,@masterManifest);
        @release = grep(/\/$view\//,@release);
    } else { }

    @masterManifest = sort(@masterManifest); @release = sort(@release);
    open(my $outMM, ">./.masterManifest.txt");
    open(my $outRel, ">./.release.txt");
    print $outMM @masterManifest,"\n";
    print $outRel @release,"\n";
    close($outMM);
    close($outRel);

    if (! exists($ENV{'DA_TEST_NOGUI'})){
        if ( ! -e $MERGE_EXE ) {
            print("FAILED to merge because of missing merge tool '${MERGE_EXE}'\n");
        }
        system("$MERGE_EXE ./.masterManifest.txt ./.release.txt");    
    }
}

