#!/depot/perl-5.14.2/bin/perl

###############################################################################
#
# Name    : alphaFlattenSpiceInstances.pl 
# Author  : N/A
# Date    : N/A
# Purpose : N/A
#
# Modification History:
#   001 ljames  10/25/2022
#       Issue-343 cleaning linting errors
###############################################################################
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use Cwd     qw(getcwd );
use Carp    qw( confess );
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

########  MAIN FOLLOWS  ##############

##  This script is a simple flattener, dealing only with subcircuit instances. 
BEGIN {
    our $AUTHOR='Multiple Authors';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main() unless caller();
END {
   footer();
   write_stdout_log($LOGFILENAME);
   local $?;
}

my %g_cells;
my @globalLines;
my $g_hierSep = "/";
my $g_incParams = 0;

sub Main(){
    my $opt_verbosity;
    my $opt_debug;
    my $opt_nousage;
    my $opt_help;
    my @saved_argv = @ARGV;

    my $topCell;
    my $output;

    my $result = GetOptions(
        "topCell=s"   => \$topCell,
        "hierSep=s"   => \$g_hierSep,
        "output=s"    => \$output,
        "incParams!"  => \$g_incParams,
        "nousage"     => \$opt_nousage,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "help"        => \$opt_help,
    );

    if ( $opt_help ){
        usageHelp(0);
    }

    my $infile = $ARGV[0];

    unless( $main::DEBUG || $opt_nousage) {
       utils__script_usage_statistics( $PROGRAM_NAME , $VERSION, \@saved_argv );
    }

    if (!$infile ){ 
        eprint("No input specified on the command line.\n");
        usageHelp(1); 
    }

    if (!(defined $output)) {
        $output = "$infile.flat";
    }

    open(my $OUT, ">", $output) || confess "Error:  $output cannot be opened for write\n"; # nolint open>
    dprint(HIGH, "$infile\n");

    ProcessFile($infile);

    if (defined $topCell) {
        Flatten($OUT, $topCell, undef, undef, "");
    }


    exit(0);
}

sub ProcessFile($) {
    my $infile = shift;
    my $cellName;

    open( my $IN, "<", $infile) || confess "Error: Cannot open $infile\n"; # nolint open<
    while (my $line = GetLine($IN)){
        dprint (HIGH, $line);
        my @tokens = Tokenify($line);
        if (@tokens == 0) {next}
        my $tok1 = lc $tokens[0];
        if (substr($tok1, 0, 1) eq "*") {next}
        if (substr($tok1, 0, 1) eq '$') {next}
        if ($tok1 eq ".subckt") {
            shift @tokens;
            $cellName = shift @tokens;
            my @ports = ();
            my @params = ();
            foreach my $t (@tokens) {
            if (index($t, "=") == -1) {
                push @ports, $t
            } 
            else {
                push @params, $t}
            }
            $g_cells{$cellName}->{PORTS}  = @ports;
            $g_cells{$cellName}->{PARAMS} = @params;
            $g_cells{$cellName}->{GUTS}   = ();

        } elsif ($tok1 eq ".ends") {
            
            $cellName = undef;

        } else {
            
            if (defined $cellName) {
                push (@{$g_cells{$cellName}->{GUTS}}, $line);
            } else {
                ##  A line outside of a subckt definition.
                push @globalLines, $line;
            }
        }
    }
    
    close $IN;
} # end ProcessFile

sub parseInstance($){
    my $line = shift;

    my @toks = split(/\s+/, $line);
    my $instName = shift @toks;
    my @ports;
    my @params;
    foreach my $t (@toks) {
	    if (index($t, "=") == -1) {push @ports, $t} else {push @params, $t}
    }
    my $cellName = pop @ports;
    dprint (SUPER, ">>> $instName:$cellName, {@ports}  {@params}\n");
    return ($instName, $cellName, \@ports, \@params);
}

sub portRename {
    
    ##  Rename a port.
    my $port = shift;
    my $renames = shift;
    my $prefix = shift;

    dprint (LOW, "Rename\n");
    foreach my $p (keys %$renames) {
        dprint (HIGH, "\t$p --> $renames->{$p}\n");
    }

    my $i;
    my $n = @$port;
    for ($i=0; ($i<$n); $i++) {
        if ( defined ($renames->{$port->[$i]})) {
            ##  Signal is ported.
            $port->[$i] = $renames->{$port->[$i]}
        } else {
            ##  Signal local to the subckt
            $port->[$i] = "$prefix$port->[$i]";
        }
    }
}

sub Flatten($$$$$) {
    my $OUT        = shift;
    my $cellName   = shift;
    my $instPorts  = shift;
    my $instParams = shift;
    my $path       = shift;

    dprint (HIGH, "Info:  Flattening $path:$cellName\n");
    if (!(defined $g_cells{$cellName})) {return}

    my $sep        = ($path eq "") ? "" : $g_hierSep;
    my $cellPorts  = $g_cells{$cellName}->{PORTS};
    my $cellParams = $g_cells{$cellName}->{PARAMS};
    my $cellGuts   = $g_cells{$cellName}->{GUTS};

    my %renames;
    
    ## Build node rename hash.
    my $i = 0;
    foreach my $p (@$instPorts) {
	    $renames{$cellPorts->[$i++]} = $p;
    }

    my $prefix = "$path$sep";
    foreach my $line (@$cellGuts) {
        
        $line =~ s/^\s+?(.*)\s+$/$1/;
        my $id = lc(substr($line,0,1));
        
        if ($id eq "x") {
            
            my ($instName, $instCell, $instPorts, $instParams) = parseInstance($line);
            portRename($instPorts, \%renames, $prefix);
            dprint (HIGH, "portRename: @$instPorts\n");
            
            if (defined $g_cells{$instCell}) {
                print $OUT "*Flatten* $prefix$instName @$instPorts $instCell @$instParams\n";
                ## RECURSION
                &Flatten($instCell, $instPorts, $instParams, "$prefix$instName");
            } else {
                if ($g_incParams) {
                    print OUT "$prefix$instName @$instPorts $instCell @$instParams\n";
                } 
                else {
                    print OUT "$prefix$instName @$instPorts $instCell\n";
                }  
            }
	    }
    }
} # end Flatten

sub GetLine($) {

    my $fh = shift;
    my $linebuf;
    my $line;
    
    ## $linebuf should hold the pre-fetched next non-continuation line.
    if (!$linebuf) {$linebuf = <$fh>}   ##  Read first line of file.
    
    while (my $line = <$fh>){
        ##$linebuf =~ s/^\s*(.*)\s*$/$1/g;
        if (substr($line, 0, 1) eq "+")
        {
            ## Line is continuation
            chomp $linebuf;
            $linebuf .= substr($line, 1);
        }
        else
        {
            ##  Non-continuation.  Return $linebuf
            my $rline = $linebuf;
            $linebuf = $line;
            return $rline;
        }
    }
}

sub Tokenify($) {
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s+?(.*)\s+$/$1/;
    $line =~ s/\s*=\s*/=/g;   ## Strip any whitespace around "=" signs.  Makes later parsing easier.
    return split(/\s+/, $line);
}

# NOTE: need to add help text to this script when use passes -help as an option
sub usageHelp($){
    my $exit_status = shift;

    print("Script: $RealScript\n");
    print("Options:\n");
    print("    -topCell string\n");
    print("    -hierSep seperator\n");
    print("    -output  filename\n");
    print("    -incParams  ???\n");
    print("    -nousage\n");
    print("    -debug <number>\n");
    print("    -verbosity <number>\n");
    print("    -help  Show this help\n");


    exit($exit_status);
}

1;
