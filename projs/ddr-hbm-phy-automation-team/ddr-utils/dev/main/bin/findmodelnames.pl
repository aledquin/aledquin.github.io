#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';
use Pod::Usage;
use Cwd;
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';

BEGIN {
    our $AUTHOR='DDR DA WG';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
    footer();
    write_stdout_log("$LOGFILENAME");
}





sub Main {
    utils__script_usage_statistics( "ddr-utils-$PROGRAM_NAME", $VERSION);

    my @MosPatterns = qw(^[np]ch);
    my @SkipPatterns = qw(pode);
    unlink ".tempfile";
    our $fullPath = 1;

    my %devSize;
	my ($nfin, $l) = "";
    foreach my $file (@ARGV) {
        if (-r $file) {
    	my @IN = read_file($file);
    	my $line;
    	foreach my $line (@IN) {
    	    my @toks = Tokenify($line);
    	    if (@toks == 0) {next}
    	    my $t0 = shift @toks;
    	    my $c0 = lc substr($t0, 0, 1);
    	    if ($c0 ne "m") {next}
    	    my $t;
    	    my $i = 0;
    	    my $devName = undef;
    	    my $nf = 1;
    	    foreach (@toks) {
    		if (/(.*)=(.*)/) {
    		    ## It's a param
    		    my $pName = lc $1;
    		    my $pVal = $2;
    		    if ($pName eq "nfin") {$nfin=$pVal}
    		    if ($pName eq "nf") {$nf=$pVal}
    		    if ($pName eq "l") {
    			$l=sprintf("%.2f", int(SpiceNumToReal($pVal)*1e9));
    		    }
    		}
    		else {
    		    $devName = $_;
    		}
    	    }
    	    $nfin /= $nf;
    	    $devSize{"$devName:$nfin/$l"} = 1;
    	}
        }
        else {
    	    eprint("Error:  Cannot open $file\n");
    	next;
        }
    }
	my @temp; 
    foreach my $d (sort keys %devSize) {
        push @temp,"$d\n";
    }
	my $write_status = write_file(\@temp,".tempfile");
}

sub Tokenify
{
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s*(.*)\s+$/$1/;
    return split(/\s+/, $line);
}
sub SpiceNumToReal
{

    my $InStr = lc(shift);
    my $value = "";
    if ($InStr =~ m/(([-+])?(\d+)?(\.)?(\d+)([e][-+]?\d+)?)([a-z]+)?/)
    {
	##  $1 is number part
	##  $7 is multiplier
	##  The rest can be ignored I think.
#	print "\t\$1 = $1\n";
#	print "\t\$2 = $2\n";
#	print "\t\$3 = $3\n";
#	print "\t\$4 = $4\n";
#	print "\t\$5 = $5\n";
#	print "\t\$6 = $6\n";
	my $mul = 1.0;
	my $mulstr = lc($7);
	if ($mulstr ne "")
	{
	    my $mulstr1 = substr($mulstr, 0, 1);
	    if ($mulstr1 eq "a") {$mul = 1e-18}
	    elsif ($mulstr1 eq "f") {$mul = 1e-15}
	    elsif ($mulstr1 eq "f") {$mul = 1e-15}
	    elsif ($mulstr1 eq "p") {$mul = 1e-12}
	    elsif ($mulstr1 eq "n") {$mul = 1e-09}
	    elsif ($mulstr1 eq "u") {$mul = 1e-06}
	    elsif ($mulstr1 eq "m") 
	    {
		$mul = 1e-03;
		if (substr($mulstr, 0, 3) eq "meg")
		{
		    $mul = 1e+06;
		}
	    }
	    elsif ($mulstr1 eq "k") {$mul = 1e+03}
	    elsif ($mulstr1 eq "x") {$mul = 1e+06}
	    elsif ($mulstr1 eq "g") {$mul = 1e+09}
	    elsif ($mulstr1 eq "t") {$mul = 1e+12}
	    else {$mul = 1.0}
	}
	$value = $1 * $mul;
#	print "$InStr: $value\n";
	return $value;
    }
    else 
    {
	eprint("SpiceNumToReal: Could not parse $InStr\n");
	return(undef);
    }
}
