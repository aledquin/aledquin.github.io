#!/depot/perl-5.14.2/bin/perl
#!/depot/perl-5.8.0/bin/perl
###############################################################################
#
# Name    : alphaCompileLibs_batch.pl
# Author  : N/A
# Date    : N/A
# Purpose : N/A
#
# Modification History:
#   001 ljames  10/25/2022
#       Issue-343 cleaning lint errors
###############################################################################
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path getcwd );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

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
   local $?;  ## to ensure exit(value) gets returned
}

########  MAIN FOLLOWS  ##############

sub Main(){
    my $opt_nousage;
    my $opt_help;
    my $opt_verbosity;
    my $opt_debug;

    my $ThisScript = Cwd::abs_path($0);
    my $cwd = getcwd();

    my @save_argv = @ARGV;

    my $module = "syn/2013.12";
    my $passed = GetOptions(
        "module=s" => \$module,
        "nousage"  => \$opt_nousage,
        "debug=i"  => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "help"     => \$opt_help,
        );

    if ( $opt_help ){
        usageHelp(0);
    }
    if ( ! $passed){
        usageHelp(1);
    }

    $main::DEBUG     = $opt_debug if ( $opt_debug );
    $main::VERBOSITY = $opt_verbosity if ( $opt_verbosity );

    my $compile = 1;
    my $check   = 0;
    if (@ARGV > 0) {
        my $arg0 = lc $ARGV[0];
        if ($arg0 eq "compile") {
            $compile = 1;
            $check = 0;
        }
        elsif ($arg0 eq "check") {
            $compile = 0;
            $check = 1;
        }
        else {
            eprint("Unrecognized keyword \"$arg0\"! Valid keywords are: compile, check\n");
            usageHelp(1);
        }
    }else{
        eprint("No keyword specified! Valid keywords are: compile, check \n");
        usageHelp(1);
    }

    my @libs = glob("*.lib");
    my @compileJobs;
    my @compileRoots;

    unless ( $main::DEBUG || $opt_nousage){
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@save_argv);
    }

    foreach my $lib (@libs){
        $lib =~ /(.*)\.lib$/;
        my $root = $1;
        push @compileRoots, $root;
        if ($compile) {
        
            my @SCRout;
            
            push( @SCRout, "#!/bin/csh\n");
            push( @SCRout, "\n");
            push( @SCRout, "module purge\n");
            push( @SCRout, "module load $module\n");
            push( @SCRout, "lc_shell -f compile_$root.tcl\n");
            push( @SCRout, "exit\n");
            write_file(\@SCRout, "compile_$root.csh");

            my @TCLout;
            my $db = $lib;
            $db =~ s/\.lib$/.db/;
            if(!-l $db){ ## ignore symbolic links
                my $libName = libraryName($lib);
                if (defined $libName) {
                    unlink $db;  ## Remove db if it exists
                    push( @TCLout, "puts \"Compiling $lib\"\n");
                    push( @TCLout, "read_lib $lib\n");
                    push( @TCLout, "write_lib $libName -output $db\n");
                }
                else {
                    eprint( "Failed to get library name from $lib\n");
                }
            }
            push( @TCLout, "quit\n");
            write_file(\@TCLout, "compile_$root.tcl");
            chmod 0777, "compile_$root.csh";

#            my @o = `qsub -P bnormal -V -cwd -b n -N alphaCompileLibs_$root -e $root.compile.err -o $root.compile.log compile_$root.csh`;
            my $cmd = "qsub -P bnormal -V -cwd -b n -N alphaCompileLibs_$root ".
                      "-e $root.compile.err " .
                      "-o $root.compile.log compile_$root.csh";
            my ($stdout, $status) = run_system_cmd( $cmd );
            if ( ! $status ){
                fatal_error("Failed to run '$cmd'\n");
            }

            my @o = split /\n/,$stdout;
            if (@o) {
                if ($o[-1] =~ /Your job (\d+) .*has been submitted/) {
                    ##  Job submitted.
                    iprint( "Job $1 submitted for $root\n");
                    push @compileJobs, $1;
                }
            }else{
                eprint("Job not submitted.\n");
            }
        }
    }

    my $username  = get_username();
    my $emailaddr = "$username\@synopsys.com";

    if ($compile ){
        ##  Create check job
        my $depJobs = "@compileJobs";
        if ( ! $depJobs ){
            fatal_error("No jobs have been submitted!\n");
        }

        $depJobs =~ tr/ /,/;        
        my @SCRout;
        push(@SCRout, "#!/bin/csh\n");
        push(@SCRout, "\n");
        push(@SCRout, "$ThisScript check\n");
        write_file( \@SCRout, "compileCheck.csh");
        chmod 0777, "compileCheck.csh";
        unlink "compileCheck.out";
        unlink "compileCheck.err";
        my ($out, $err) = run_system_cmd ("qsub -hold_jid \"$depJobs\" -m e -P bnormal -V -cwd -b n -N alphaCompileLibsCheck -e compileCheck.err -o compileCheck.out compileCheck.csh");

        iprint("$out\n$err\n");
    }

    if ($check ){
        my @LOGout;
        my @SUMout;

        my @execSummary;
        push( @SUMout, "Summary:\n");
        push( @LOGout, "Summary:\n");
        foreach my $root (@compileRoots) {
            my $libFile = "$root.lib";
            my $dbFile = "$root.db";
            push( @SUMout, "\t$libFile --> $dbFile:  ");
            push( @LOGout, "\t$libFile --> $dbFile:  ");
            if (-e $dbFile ){
                push( @SUMout, "OK\n");
                push( @LOGout, "OK\n");
            } else {
                push( @SUMout, "FAILED\n");
                push( @LOGout, "FAILED\n");
            }
        }
        write_file( \@SUMout, "compile.sum");

        push( @LOGout, "\n\n");
        
        foreach my $root (@compileRoots) {
            unlink "compile_$root.csh";
            unlink "compile_$root.tcl";
            push( @LOGout, 
                    "-------------------------------- $root --------------------------------\n");
            my $dbFile = "$root.db";
            my $logFile = "$root.compile.log";
            my $errFile = "$root.compile.err";
            push( @LOGout, "\t$dbFile:  ");
            if (-e $dbFile ){
                push( @LOGout, "OK\n");
            }else{
                push( @LOGout, "MISSING\n");
            }
            push( @LOGout, "\n");
            push( @LOGout, "\tCompile stdout:\n");
            attachFile(\@LOGout, $logFile);
            unlink $logFile;
            push( @LOGout, "\n");
            push( @LOGout, "\tCompile stderr:\n");
            attachFile(\@LOGout, $errFile);
            unlink $errFile;
            push( @LOGout, "-----------------------------------------------------------------------\n");
        }
        write_file(\@LOGout, "compile.log");
        my $mailCmd = "mail -s \"alphaCompileLibs $cwd complete\" $emailaddr < compile.sum";
        iprint( "$mailCmd\n");
        my ($stdout, $status) = run_system_cmd($mailCmd);
    }
    exit(0);
} # end of Main

sub usageHelp($){
    my $exit_status = shift;

    exit($exit_status);
}

sub attachFile($$) {
    my $aref_fh = shift;
    my $attFile = shift;

    if (!(-e $attFile)) {
        push(@$aref_fh, "Error:  $attFile does not exist\n");
    }
    else {
        my @FF = read_file($attFile);
        my $line;
        foreach my $line (@FF) {
            push( @$aref_fh, $line);
        }
    }
}

sub libraryName($){
    my $lib = shift;

    my @LIB = read_file( $lib );
    foreach my $line (@LIB){
        if ($line =~ m/^\s*library\s*\(\"*(\w+)\"*\)/) {
            return $1
        }
    }
    return;  ## returning nothing actually returns undef
}
