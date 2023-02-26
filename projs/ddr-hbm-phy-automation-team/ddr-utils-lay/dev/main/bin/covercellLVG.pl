#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : covercellLVG.pl
# Author  : Ahmed Hesham(ahmedhes)
# Date    : 08/09/2022
# Purpose : This is a wrapper script for the covercell msip_lefVsGds check.
#
# Modification History
#     000 ahmedhes 08/09/2022
#         Created this script
#     001 YOURNAME DATE_OF_YOUR_CHANGES
#         Description of what you have changed.
#     
###############################################################################
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Cwd;
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use alphaHLDepotRelease;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG               = NONE;
our $VERBOSITY           = NONE;
our $AUTO_APPEND_NEWLINE = TRUE;
our $PROGRAM_NAME        = $RealScript;
our $LOGFILENAME         = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION             = get_release_version();
#--------------------------------------------------------------------#

BEGIN {
    our $AUTHOR='Ahmed Hesham(ahmedhes)';
    $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    #$STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
Main();
END {
   footer(); 
   write_stdout_log("$LOGFILENAME");
}

########  YOUR CODE goes in Main  ##############
sub Main {
    # Process the arguments passed to the script
    my @args = @ARGV; # save cmd line args because 'process_cmd_line_arg' modifies @ARGV
    my ( $opt_nousage, $opt_version ) = process_cmd_line_args();

    # A call to the usage statistics
    unless( defined $opt_nousage ){
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@args ); 
    }

    # Check that the argument is in the correct form. Get the path for the 
    # legalRelease file.
    my( $fname_projRelFile, $fname_gds, $tech, $metalStack, $macro ) = parse_argv($ARGV[0]);
    
    my ( %legalRelease );
    # Call processLegalReleaseFile that reads the project legal release file 
    # for the project and do some processing using the items read.
    processLegalReleaseFile($fname_projRelFile, \%legalRelease);

    
    # Get the hardmacro name from the covercell macro name.
    my $hardmacroSegmenet = $macro =~ s/.*cover_//r;
    my( $fname_diLef, $hardmacro ) = get_latest_di_file($metalStack, $hardmacroSegmenet,
                                                        \%legalRelease);
    
    # Get the mapfile
    my( $fname_map ) = get_map_file($tech);

    # Get the MIPLAST
    my $MIPLAST = $legalRelease{'supplyPins'};
    if( !defined($MIPLAST) ){
        fatal_error("Failed to find MIPLAST from the legalRelease file (supply_pins)!");
    }
    # Take only the first layer
    $MIPLAST =~ s/\s+.*//g;

    my $cmd = "source ~/.bashrc; module unload msip_shell_lef_utils;";
    if( defined($opt_version) ){
        $cmd .= " module load msip_shell_lef_utils/$opt_version;";
    }else{
        $cmd .= " module load msip_shell_lef_utils;";
    }
    $cmd .= " msip_lefVsGds $fname_gds $fname_diLef $fname_map".
            " -checkLayers $MIPLAST -c \"$hardmacro/$macro\" -labelOverMetal";

    run_system_cmd($cmd, $VERBOSITY+1);

    exit(0);
}
############    END Main    ####################

#------------------------------------------------------------------------------
sub process_cmd_line_args(){
    my ( $opt_verbosity, $opt_debug, $opt_help, $opt_nousage, $opt_path );
    my ( $opt_macrosList, $opt_useOldSubmacros, $opt_namingMode, $opt_version );
    GetOptions(
          "verbosity=i"     => \$opt_verbosity,
          "debug=i"         => \$opt_debug,
          "help"            => \$opt_help, 
          "nousage"         => \$opt_nousage,
          "Version=s"       => \$opt_version,
    );

    # VERBOSITY will be used to control the intensity level of 
    #     messages reported to the user while running.
    if( defined($opt_verbosity) ){
        $main::VERBOSITY = $opt_verbosity;
    }
    
    # decide whether to alter DEBUG variable
    # '--debug' indicates DEBUG value ... set based on user input
    if( defined($opt_debug) ){
        $main::DEBUG = $opt_debug;
    }

    my $nargs = @ARGV;
    if( defined($opt_help) ){
        pod2usage( -verbose => 2, -exitval=>0 );
    }elsif( $nargs == 0 ){
        pod2usage( -verbose => 1, -exitval=>1);
    }

    if( defined($opt_version) ){
        my $shelltoolsPath = "/remote/cad-rep/msip/tools/Shelltools/lef_utils/";
        if( !-e "$shelltoolsPath/$opt_version" ){
            eprint("The tool msip_lef_utils has no version named $opt_version.".
                   " Using the latest version instead.");
            undef($opt_version);
        }
    }

    return( $opt_nousage, $opt_version );
}

#-------------------------------------------------------------------------------
sub parse_argv($){
    print_function_header();
    my $gdsPath = shift;
    
    $gdsPath = abs_path($gdsPath);
    if( !-e $gdsPath ){
        fatal_error("The path provided '$gdsPath' doesn't exist!");
    }

    my( $projType, $proj, $cdRel, $metalStack, $macro );
    if($gdsPath =~ m|/verification/(${\NFS})/(${\NFS})/(${\NFS})/
                      (${\NFS})/${\NFS}/(${\NFS})/${\NFS}/?$|x){
        $projType   = $1;
        $proj       = $2;
        $cdRel      = $3;
        $metalStack = $4;
        $macro      = $5;
    }else{
        fatal_error("Resolved LVS path '$gdsPath' is not valid and must end with\n".
               "\t\t.../verification/<project_type>/<project>/<CD_release>/".
               "<metal_stack>/<CD_lib>/<macro>/<Verif>\n");
    }

    my $projPathAbs       = "/remote/cad-rep/projects/$projType/$proj/$cdRel";
    my $fname_projRelFile = firstAvailableFile(
        "$projPathAbs/design/legalRelease.yml",
        "$projPathAbs/design/legalRelease.txt",
        "$projPathAbs/design_unrestricted/legalRelease.yml",
        "$projPathAbs/design_unrestricted/legalRelease.txt");
    if( $fname_projRelFile eq EMPTY_STR ){
        $fname_projRelFile = "$projPathAbs/design/legalRelease.yml";
    }
    my $fname_gds = (glob("$gdsPath/$macro.gds*"))[0];
    if( !defined($fname_gds) ){
        fatal_error("Failed to find the GDS file '$gdsPath/$macro.gds*'");
    }
    # Get the tech from the project name
    my( $tech ) = $proj =~ /([^-]+$)/;
    if( !defined($tech) ){
        fatal_error("Unable to parse the tech from the project name '$proj'!");
    }
    # Remove the suffix _.*
    $tech =~ s/_.*$//;
    # Add - before the last number to match the naming of the map files directories.
    $tech =~ s/(\d+)$/-$1/;

    print_function_footer();
    return ( $fname_projRelFile, $fname_gds, $tech, $metalStack, $macro );
}

#-------------------------------------------------------------------------------
sub get_latest_di_file($$$){
    print_function_header();
    my $metalStack        = shift;
    my $macro             = shift;
    my $href_legalRelease = shift;

    # Get the DI release path
    my( $diPath ) = get_di_path($href_legalRelease);

    my $fname_diLef;
    # Loop all of the rel versions, starting from the latest one to look for the
    # DI LEF.
    foreach my $rel ( reverse(glob("$diPath/*")) ){
        $fname_diLef = (glob("$rel/*$macro/views/lef/$metalStack/*$macro.lef"))[0];
        if( defined($fname_diLef) ){
            last;
        }
    }
    if( !defined($fname_diLef) ){
        fatal_error("Couldn't find the DI LEF under '$diPath/*/*$macro/views/lef/".
               "$metalStack/*$macro.lef'!");
    }
    
    my( $hardmacro ) = $fname_diLef =~ /(${\NFS}).lef$/;
    print_function_footer();
    return( $fname_diLef, $hardmacro );
}

#-------------------------------------------------------------------------------
sub get_di_path($){
    print_function_header();
    my $href_legalRelease   = shift;
    #
    # Get the DI release path
    my $diPath = "/u/$ENV{'USER'}/p4_ws/$href_legalRelease->{'p4ReleaseRoot'}/".
                 "di/rel";
    if( !-d $diPath ){
        fatal_error("The DI release path '$diPath' does not exist!");
    }

    print_function_footer();
    return( $diPath );
}

#-------------------------------------------------------------------------------
sub get_map_file($){
    print_function_header();
    my $tech = shift;

    my $fname_map = "/remote/cad-rep/msip/ude_conf/lef_vs_gds/$tech/msip_lefVsGds.map";
    
    if( !-e $fname_map ){
        fatal_error("The technology LVG map file '$fname_map' does not exist!");
    }

    print_function_footer();
    return( $fname_map );
}
;

__END__

=head1 NAME

 covercellLVG.pl

=head1 VERSION

 2022ww32

=head1 ABSTRACT

 This is a wrapper script for the covercell msip_lefVsGds check.

=head1 DESCRIPTION

 This will run msip_lefVsGds for the covercell GDS vs. the latest DI LEF. The
 script takes the directory for the covercell GDS, assuming it was generated in
 the verification directtry with the following pattern
 .../verification/<project_type>/<project_name>/<CD_rel>/<metal_stack>/<CD_lib>/<macro>/<LVS>

 The script will parse the path and get the rest of the arguments used in the 
 msip_lefVsGds call which include

=over 4

=item B<DI LEF> 

 The latest DI LEF mapped into the user's local P4.

=item B<Map File>

 The map file found at
 /remote/cad-rep/msip/ude_conf/lef_vs_gds/<tech>/msip_lefVsGds.map

=item B<MIPLAST>

 The MIPLAST defined as the supply pin in the project's legalRelease.

=back

 The call to msip_lefVsGds will have the following format
 msip_lefVsGds <GDS> <LEF> <MAP> -checkLayers <MIPLAST> -c "<LEF_NAME>/<GDS_NAME>" -labelOverMetal

=head1 USAGE

 covercellLVG.pl <LVS_PATH> [options]

=head2 OPTIONS

=over 8

=item B<-help> 
  
 Prints this screen.

=item B<-verbosity> B<#>

 Print additional messages... Includes details of system calls, etc..
 Must provide integer argument where higher values increase verbosity.

=item B<-debug> B<#> 
 
 Print software debug diagnostic messages. Must provide integer argument where
 higher values increase verbosity.

=item B<-Version> B<#>

 Loads the specified version of msip_shell_lef_utils. If it was not specified,
 then the latest version is used.

=back

=cut
