#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Cwd;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use Getopt::Long;
use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      =  get_release_version() || '2022.11'; # Syntax: YYYYww##[.#] optional day 1-7
                                # The work week number can be found in
                                # your outlook calendar. The days are 1=sunday
                                # 2=monday ... 7=saturday
#--------------------------------------------------------------------#

our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log("${LOGFILENAME}.log");
   footer(); 
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);
}

sub Main {
#chop( my $Me = `basename $0` );
chop( my $Me = run_system_cmd("basename $0",$VERBOSITY ));

my $Usage = "Usage: $Me  <directory with lib-files>  \n";

if ($#ARGV != 0) {
    iprint ("$Usage\n");
    exit 0;
}

my $dir = $ARGV[0];
my @allfiles;
my ($libname, $logfile);
my $lctcl = "__checkalllibs.lctcl";
my $cshscript = "__tmpscript.csh";

#chop (my $binPath = `dirname $0` );
my $binPath =  "$RealBin";
my $logdirname = "MONOTONICLOGS";
my $ext = "monotoniclog";

opendir(DIR, $dir) || die "Cannot open directory $dir\n";
#@allfiles = grep /\.lib$/, readdir( DIR );
@allfiles = grep { /\.lib$/ } readdir( DIR );

closedir(DIR);

if (-d $logdirname) { 
    run_system_cmd("rm -f $logdirname/*.$ext",$VERBOSITY) ;
} else  { 
   run_system_cmd("mkdir $logdirname",$VERBOSITY);
}

#open (my $SRC, ">$cshscript");
#print $SRC "#!/bin/csh\n";
#print $SRC "module unload lc\n";
#print $SRC "module load lc/2015.12-SP3\n";
#print $SRC "lc_shell -f $lctcl | tee lc_shell.log\n";
#close $SRC;
my @SRC;
my $SRC = "#!/bin/csh
module unload lc
module unload lc
module load lc/2015.12-SP3
lc_shell -f $lctcl | tee lc_shell.log";

push @SRC,"$SRC\n";
my $status1 = write_file(\@SRC, $cshscript);

chmod 0777, $cshscript;
my @files = "";
foreach my $file (sort @allfiles) {
	push @files,$file;
    ($libname = $file) =~ s/\.lib//;
    $logfile = "$logdirname/$libname.$ext";
	#open (my $TCL, ">$lctcl");
        #print $TCL "source  ${RealBin}/FindNonMonotonicConstraints_proc.lctcl\n";
        #print $TCL "FindNonMonotonicConstraints $dir/$file $logfile \n";	
	#print $TCL "quit\n";
	#close $TCL;
	my @TCL;
	my $TCL = "source  ${RealBin}/FindNonMonotonicConstraints_proc.lctcl
FindNonMonotonicConstraints $dir/$file $logfile
quit";
	
	push @TCL,"$TCL\n";
	my $status2 = write_file(\@TCL, $lctcl);
	

run_system_cmd ("$cshscript",$VERBOSITY);;
unlink $lctcl;
}

   

opendir(DIR, $logdirname) || die "Cannot open directory $logdirname\n";
#@files = grep /\.$ext$/, readdir( DIR );
@files = grep { /\.$ext$/ } readdir( DIR );
closedir(DIR);
foreach my $file (sort @files) {
  ($libname = $file) =~ s/\.$ext/.lib/;
  if(`grep 'Non monotonic' $logdirname/$file`) {    
     iprint ("Library $libname has non-monotonic arcs. Check $logdirname/$file\n");
  } else {
     nprint ("Library $libname is clean\n");
  
  }
}

#unlink $lctcl, $cshscript;
exit 0;
}
#&Main();
