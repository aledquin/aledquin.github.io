#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : alphaCompileLibs.pl
# Author  : Davidgh
# Date    : 
# Purpose : Compiles all libs in the current directory
#
# Modification History
#     
###############################################################################

use strict;
use warnings;

use Pod::Usage;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use Getopt::Long;
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Cwd;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = FALSE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
#--------------------------------------------------------------------#

## Compiles all libs in the current directory
## Added -lvf option to compile lvf libs with LVF QA steps # davidgh

BEGIN {
    our $AUTHOR='davidgh, J Laderoute';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
#&_run_unit_tests();
END {
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer();
   write_stdout_log( $LOGFILENAME );
}

sub Main(){
    my $def_module  = "syn";
    my $def_lvf     = 0;
    my $lvf         = 0;
    my $opt_nousage = FALSE;
    my $opt_help    = FALSE;
    my $lc          = "lc";
    my ($module, $lc_module );
    my (@scr_array, @tcl_array );

    my @orig_argv   = @ARGV; # keep this here cause GetOpts modifies ARGV
    ($module,$lc_module ,$lvf, $opt_nousage, $opt_help) 
        = process_cmd_line_args();

    unless( defined $lvf) {
        $lvf = $def_lvf;
    }
    unless (defined $lc_module) {
        $lc_module = $lc;
    }  
    if ( $opt_help ) {
        pod2usage(0);
    }

    unless (defined $module) {
        $module = $def_module;
    }

    unless ( $DEBUG || $opt_nousage ) {
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_argv );
    }

    dprint(LOW, "Args: module='$module' lvf='$lvf' lc='$lc_module'\n");
    
    push( @scr_array, "#!/bin/csh\n");
    push( @scr_array, "\n");
    push( @scr_array, "module purge\n");
    push( @scr_array, "module load $module\n");
    push( @scr_array, "module unload lc\n");
    push( @scr_array, "module load $lc_module\n");
    push( @scr_array, "lc_shell -f compile.tcl\n");
    push( @scr_array, "exit\n");
    my $status1 = write_file(\@scr_array, "compile.csh");


    push( @tcl_array, "set lc_check_lib_keep_line_number true\n");


    my @libs = glob("*.lib");

    foreach my $lib (@libs)
    {
        my $db = $lib;
        $db =~ s/\.lib$/.db/;
        if(!-l $db){ ## ignore symbolic links
            my $libName = libraryName($lib);
            if (defined $libName){
                viprint(LOW, "Found '$libName' in '$lib'\n"); 
                unlink $db;  ## Remove db if it exists
                if ($lvf){
                    unlink "$libName.report";        ## Remove report if it exists
                    unlink "${libName}_lvf.csv";     ## Remove report if it exists
                    unlink "${libName}_summary.csv"; ## Remove report if it exists   
                }
                push( @tcl_array, "puts \"Compiling $lib\"\n");
                push( @tcl_array, "read_lib $lib\n");
                
                if ($lvf) { 
                    push( @tcl_array, "set_check_library_options -analyze {lvf} -criteria {max_sigma_to_nominal_ratio=0.1} -report_all -report_format {csv}\n");
#                    push( @tcl_array, "set_check_library_options -analyze {lvf} -criteria {max_sigma_to_nominal_ratio=0.1} -report_format {csv}\n");
                    push( @tcl_array, "report_check_library_options > $libName.report\n");
                }

                push( @tcl_array, "write_lib $libName -output $db\n");
            } else {
                eprint("Failed to get library name from '$lib'\n");
            }
        }
    }

    if ($lvf) {
        push( @tcl_array, "check_library\n");
    }
    push( @tcl_array, "quit\n");

    my $status2 = write_file(\@tcl_array, "compile.tcl");

    my @output;

    if ( $TESTMODE ){
        hprint("TESTMODE: chmod +x compile.csh; ./compile.csh\n");
        push(@output, "TESTMODE: did not run ./compile.csh or ./compile.tcl");
    }else{
        my $cmd = "chmod +x compile.csh; ./compile.csh";
        my ($stdoutput, $runstat) = run_system_cmd($cmd);
        @output = split(/\n/, $stdoutput);
        unlink "compile.csh";
        unlink "compile.tcl";
        unlink "command.log";
    }

    write_file(\@output, "compile.log");

    my $failure=0;
    foreach my $lib (@libs){
        my $db = $lib;
        $db    =~ s/\.lib$/.db/;
        if ( $TESTMODE ) {
            # the $db file won't exist in TESTMODE. We don't want
            # to mark this as a failure in TESTODE.
        }else{
            if ( ! ( -e $db ) ){ 
                eprint "$lib compile failed\n";
                $failure += 1;
            }
        }
    }

    iprint "Compile complete. See compile.log for details\n";
    exit( $failure>0?1:0);  ## 0=success 1=failure
} # Main end



#------------------------------------------------------------------------------
sub libraryName($){
    print_function_header();
    my $lib     = shift;
    my $LIB;
    my @lib_lines = read_file($lib);
#    if ( ! $pass ){
#        print_function_footer();
#        return ; #undef;  (note: undef is the default when doing a return without a value)
#    }
    my $libname = undef;
    foreach my $line (@lib_lines) {
        if ($line =~ m/^\s*library\s*\(\"*(\w+)\"*\)/) {
            $libname = $1;
            last;
            
        }
    }
    print_function_footer();
    return $libname;
}

#------------------------------------------------------------------------------
sub process_cmd_line_args(){
    my ( $opt_module, $opt_lc,        $opt_lvf,  $opt_dryrun, 
         $opt_debug,  $opt_verbosity, $opt_help, $opt_nousage_stats );

    my $success = GetOptions(
        "module=s"    => \$opt_module,
        "lc=s"        => \$opt_lc,
        "lvf+"        => \$opt_lvf,
        "dryrun!"     => \$opt_dryrun,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "nousage"     => \$opt_nousage_stats,  # when enabled, skip usage stats
        "help"        => \$opt_help,           # Prints help
     );

    if( defined $opt_dryrun ){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   
   return( $opt_module, $opt_lc, $opt_lvf, $opt_nousage_stats, $opt_help );
};

__END__


=head1 NAME

alphaCompileLibs.pl

=head1 VERSION

2022ww18

=head1 SYNOPSIS

Compiles all libs in the current directory

=head1 DESCRIPTION

Compiles all libs in the current directory

=head1 OPTIONS

=head2 ARGS

=over 8

=item B<-module> The module name

=item B<-lvf> This option to compile lvf libs with LVF QA steps

=item B<-lc> This option to specify lc version. Default is current version.

=item B<-testmode> Goes thru the motions without actually running the generated scripts.

=item B<-debug> Set debug level

=item B<-verbosity> Verbosity level

=item B<-nousage> Prevents the usage statistics from getting generated

=item B<-help> This help (just spits out this POD by default, but we can chose something else if we like 

=back

=head1 BUGS

Please report any bugs or feature requests using the Synopsys bug reporting
methodology.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

=head1 AUTHORS

 Davit Ghukasyan
 James Laderoute

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT_AND_LICENSE

Copyright 2021-2022, Synopsys

This software is owned by Synopsys; you are not allowed to redistribute it
and/or modify it.


=cut
