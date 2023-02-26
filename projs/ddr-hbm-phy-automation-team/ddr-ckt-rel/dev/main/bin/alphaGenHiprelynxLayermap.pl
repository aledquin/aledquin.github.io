#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use File::Basename;
use FindBin qw($RealBin $RealScript);
use Cwd;
use Carp qw(cluck confess croak);

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG         = NONE;
our $VERBOSITY     = NONE;
our $TESTMODE      = NONE;
our $PROGRAM_NAME  = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11'; 
our $FPRINT_NOEXIT = 1;
#--------------------------------------------------------------------#

BEGIN{
    our $AUTHOR='clouser, kevinxie, ljames';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END{
    local $?;   ## adding this will pass the status of failure if the script
    footer();
    write_stdout_log("$LOGFILENAME");
}

#-------------------------------------------------------------------------------
sub Main(){
    my ($opt_gds, $opt_tech, $opt_help, $streamLayermap);
    my ($opt_nousage, $opt_testmode, $opt_verbosity, $opt_debug);

    my $opt_output  = "layermap.txt";
    my $opt_mapFile = "$RealBin/alphaGenHiprelynxLayermap.tech";

    my @orig_argv = @ARGV;
    logger( pretty_print_aref( \@ARGV ));
    logger( "\n" );
    
    my $success = GetOptions(
        "tech=s"      => \$opt_tech,
        "gds=s"       => \$opt_gds,
        "output=s"    => \$opt_output,
        "mapFile=s"   => \$opt_mapFile,
        "h|help"      => \$opt_help,
        "nousage"     => \$opt_nousage,
        "testmode"    => \$opt_testmode,
        "verbosity=i" => \$opt_verbosity,
        "debug=i"     => \$opt_debug,
        );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    &usage(1) unless( defined $opt_gds    && defined $opt_tech    &&
                      defined $opt_output && defined $opt_mapFile );

    $main::TESTMODE  = 1              if ( defined $opt_testmode  );
    $main::VERBOSITY = $opt_verbosity if ( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if ( defined $opt_debug     );

    my $USERNAME  = get_username();

    unless( $opt_nousage || $main::DEBUG ){
        utils__script_usage_statistics( $RealScript, $VERSION, \@orig_argv );
    }

    my %TechHash;
    my $techmaps = $opt_mapFile;
    if ( ! ( -r $techmaps ) ){
        logconfess( "Fatal:  Cannot open '$techmaps' for read\n");
    }
    my @lines = read_file( $techmaps );
    foreach my $line ( @lines ){
        $line =~ s/\#.*//;
        my @toks = split(/\s+/, $line);
        next if (@toks != 2);

        vhprint(HIGH, "toks[0] = $toks[0] ; toks[1] = $toks[1]\n");
        $TechHash{$toks[0]} = $toks[1];
    }

    my $ArgOK = 1;
    $ArgOK &= CheckRequiredArg($opt_tech, "tech");
    $ArgOK &= CheckRequiredArg($opt_gds, "gds");
    if (!$ArgOK) {
        logconfess( "Exiting on missing required arguments\n");
    }

    my $deck = $TechHash{$opt_tech};
    if ( ! ( defined $deck ) ){
        fatal_error "Unrecognized technology \"$opt_tech\".\nChoices:\n";
        foreach (sort keys %TechHash){
            nprint "\t$_\n";
        }
        iprint "See $techmaps\n";
        exit(1);
    }
    if ( ! ( -r $deck ) ){
        logconfess( "Fatal:  Cannot open deck \"$deck\"\nCheck $techmaps\n");
    }
    iprint "Using deck $deck\n";

    #my $tmp = $ENV{TMP};
    my $tmp = (defined $ENV{TMP}) ? $ENV{TMP} : "/tmp";
    #open (*BashConf, ">", "$tmp/bash_config.sh") or logconfess( "Could not create $tmp/bash_config.sh file");
    my @bashconf_contents;
    push( @bashconf_contents,  "#!/bin/bash\n");
    push( @bashconf_contents,  ". /global/etc/modules/3.1.6/init/sh\n");
    push( @bashconf_contents,  "module purge\n");
    push( @bashconf_contents,  "module use /remote/cad-rep/etc/modulefiles/msip\n");
    push( @bashconf_contents,  "module load msip_shell_lay_utils\n");
    push( @bashconf_contents,  "msip_layGdsGetLayerMap $opt_gds $deck\n");
    write_file( \@bashconf_contents, "$tmp/bash_config.sh");
    vhprint(LOW, "Created file '$tmp/bash_config.sh\n");

    my @output;
    if ( $main::TESTMODE ){
        hprint("TESTMODE: chmod +x $tmp/bash_config.sh; $tmp/bash_config.sh\n");
    }else{
        my ($stdout_err, $rstatus) = run_system_cmd("chmod +x $tmp/bash_config.sh; $tmp/bash_config.sh");
        @output = split(/\n/, $stdout_err);
    }

    iprint( "Writing $opt_output\n" );
    foreach my $line ( @output ){
       $line =~  s/\?/\# Unknown/;
    }
    write_file(\@output, $opt_output);
    # P10020416-35175 ljames Fixed foreach loop
    #foreach my $line ( @output) {
    #    $line =~ s/\?/\# Unknown/; 
    #    print OUT $line;
    #}

    my $name = basename($opt_gds);
    $name    =~ s/\..*$/.rep/;

    unless( $main::TESTMODE or $main::DEBUG ) {
        unlink $name;
        unlink "$tmp/bash_config.sh";
    }
    exit(0);
} # end Main

#-------------------------------------------------------------------------------
sub CheckRequiredArg($$){
    my $ArgValue = shift;
    my $ArgName  = shift;

    if (!defined $ArgValue)
    {
        eprint "Required argument \"$ArgName\" not supplied\n";
        return 0;
    }
    return 1;
}

#-------------------------------------------------------------------------------
sub logconfess($){
    my $msg = shift;

    logger($msg);
    confess $msg;
}

#-------------------------------------------------------------------------------
sub usage(){
    my $exit_status = shift;
    print "Usage: $RealScript -gds <gdsfile> -tech <TECHNOLOGY> [-output <output-file>]
    Purpose:
    \tThis script generated a Hiprelynx gds layermap file using the gds to be published with lpp annotation
    \tfrom the streamLayermap file.
 
------------------------------------
Required Args:
------------------------------------
    \t-gds       <gdsfile>
    \t-tech      <TECHNOLOGY>

------------------------------------
Optional Arguments:
------------------------------------
    \t-mapFile   <path_to_a_tech_file>
    \t-output    <output-file>
    \t-debug     <debug-level>
    \t-verbosity <verbosity-level>
    \t-help

    \tJohn Clouser
    \n";
    exit($exit_status);
}

1;
