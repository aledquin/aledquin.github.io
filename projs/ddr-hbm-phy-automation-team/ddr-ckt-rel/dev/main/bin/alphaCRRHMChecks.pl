#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : alphaCRRHMChecks.pl
# Author  : Ahmed Hesham(ahmedhes)
# Date    : 09/05/2022
# Purpose : description of the script.. can put on multiple lines
#
# Modification History
#     000 ahmedhes  09/05/2022
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
use Getopt::Long;
use File::Basename qw( fileparse dirname basename );
use File::Spec::Functions qw( catfile );
use File::Path qw( rmtree );
use Cwd     qw( abs_path getcwd );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::DS;
use Util::Messaging;
use alphaHLDepotRelease;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $AUTO_APPEND_NEWLINE = TRUE;
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
#--------------------------------------------------------------------#

BEGIN {
    our $AUTHOR='ahmedhes';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
Main();
END {
   local $?;   # to prevent the exit() status from getting modified
   footer();
   write_stdout_log( $LOGFILENAME );
}

########  YOUR CODE goes in Main  ##############
sub Main {
    my $USERNAME = get_username();

    my @orig_argv = @ARGV; # keep this here cause GetOpts modifies ARGV
    my ($opt_nousage, $opt_dryrun, $opt_project_specs, $opt_parametersPath,
        $opt_hardmacros, $opt_crr, $opt_pll_crr, $opt_boundary_layer_lpp, 
        $opt_force, $opt_jobs )
            = process_cmd_line_args();

    unless( $DEBUG || defined $opt_nousage ){
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_argv );
    }

    my %parameters;
    my %hardmacros;
    # Parse the project specs to get its components
    parse_project_specs($opt_project_specs, \%parameters);
    set_default_pv_switches(\%parameters);
    # Get the parameters from the CSV file.
    if( defined($opt_parametersPath) ){
        iprint("Reading the parameters files");
        parse_parameters_file($opt_parametersPath, \%parameters, \%hardmacros);
    }
    check_project_specs(\%parameters);
    # Get the CRR file
    my $fname_crr;
    $fname_crr = $parameters{'crr_file'} if( defined($parameters{'crr_file'}) );
    $fname_crr = $opt_crr if( defined($opt_crr) );
    if( !defined($fname_crr) ){
        fatal_error("The CRR file was not defined. Please use -crr <CRR path> or ".
                    "add it to the parameters file.");
    }
    # Create a local directory to sync the files into it.
    my $dir_p4 = "perforce_files";
    unless ( -d $dir_p4 ) {
        if ( 0 == mkdir($dir_p4)){
            fatal_error("$PROGRAM_NAME failed mkdir of '$dir_p4'\n");
        }
    }

    if( $fname_crr =~ m|^//depot| ){
        $fname_crr = get_p4_file($fname_crr,$dir_p4);
    }
    if( !-e $fname_crr ){
        fatal_error("The CRR file '$fname_crr' doesn't exist!");
    }
    # Get the boundary layer LPP
    set_bounday_layer_LPP($opt_boundary_layer_lpp, \%parameters);
    # Get the technology files paths into the parameters hash
    get_technology_files(\%parameters);
    get_hardmacros_files($dir_p4, $fname_crr, \%hardmacros, \%parameters, $opt_hardmacros);
    # Read the DEF files, getting the list of unqiue macros across all files as
    # well as the macros list for each hardmacro.
    my @uniqueMacros;
    parse_def_files(\@uniqueMacros, \%hardmacros, \%parameters);
    # Get the PLL CRR file
    my $fname_pllCrr;
    $fname_pllCrr = $parameters{'pll_crr_file'} if( defined($parameters{'pll_crr_file'}) );
    $fname_pllCrr = $opt_pll_crr if( defined($opt_pll_crr) );
    if( defined($fname_pllCrr) ){
        if( $fname_pllCrr =~ m|^//depot| ){
            $fname_pllCrr = get_p4_file($fname_pllCrr,$dir_p4);
        }
        if( !-e $fname_pllCrr ){
            fatal_error("The PLL CRR file '$fname_pllCrr' doesn't exist!");
        }
    }
    # Sync the depot files(CRR/DEF/CDL) and selected views for the unqiue macros
    # into a local directory.
    my @fileTypes = ("gds", "lef");
    my( %macrosViews, %missingViews );
    iprint("Syncing selected CRR entries into $dir_p4");
    sync_macros_files($parameters{'metal_stack'}, $dir_p4, $fname_crr, $fname_pllCrr,
                      \@uniqueMacros, \@fileTypes, \%macrosViews, \%missingViews);

    # Check each hardmacro for missing views
    check_hardmacros_with_missing_components($opt_force, \%hardmacros, \%missingViews);

    # Create the reference lib that's common to all hardmacros
    iprint("Creating the reference library.");
    create_ref_lib(\%parameters, \%macrosViews);

    iprint("Creating the hardmacros GDS and running PV");
    create_hardmacros_and_run_checks(\%parameters, \%macrosViews, \%hardmacros,
                                     $opt_dryrun, $opt_jobs);
    exit(0);  
}
############    END Main    ####################
 
#------------------------------------------------------------------------------
sub process_cmd_line_args(){
    my ( $opt_debug, $opt_verbosity, $opt_help, $opt_nousage_stats, $opt_dryrun,
         $opt_project_specs, $opt_parametersPath, $opt_hardmacros, $opt_crr,
         $opt_pll_crr, $opt_boundary_layer_lpp, $opt_force, $opt_jobs );
    # The first letter of dryrun is capital so as to be able to differentiate it
    # from debug. So, using -D will invoke dryrun and -d will invoke debug.
    GetOptions(
        "debug=i"           => \$opt_debug,
        "verbosity=i"       => \$opt_verbosity,
        "nousage"           => \$opt_nousage_stats,  # when enabled, skip logging usage data
        "help"              => \$opt_help,           # Prints help
        "dryrun"            => \$opt_dryrun,         
        "p=s"               => \$opt_project_specs,
        "parameters_file=s" => \$opt_parametersPath,         
        "hardmacros=s"      => \$opt_hardmacros,
        "crr=s"             => \$opt_crr,
        "pll_crr=s"         => \$opt_pll_crr,
        "boundary_lpp=s"    => \$opt_boundary_layer_lpp,
        "force!"            => \$opt_force,
        "jobs:i"            => \$opt_jobs,
     );

   if( defined($opt_help) ){
      pod2usage( -verbose => 2, -exitval => 0);
   }elsif( !defined($opt_parametersPath) && !defined($opt_project_specs) ){
        eprint("One of the following arguments must be present: -p <project_specs>/<metal_stack> ".
               "or -parameters <parameters file path>");
      pod2usage( -verbose => 1, -exitval => 0);
   }

   if( defined($opt_jobs) ){
        if( $opt_jobs == 0 ){
            $opt_jobs = "-j";
        }else{
            $opt_jobs = "-j $opt_jobs";
        }
   }else{
        $opt_jobs = EMPTY_STR;
   }

   $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
   $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );

   return( $opt_nousage_stats, $opt_dryrun, $opt_project_specs, $opt_parametersPath,
           $opt_hardmacros, $opt_crr, $opt_pll_crr, $opt_boundary_layer_lpp, $opt_force,
           $opt_jobs );
}

#------------------------------------------------------------------------------
# Get the project_type/project_name/release_name/metal_stack from the project
# specs into the parameters hash. Also, check the project was specified correctly.
#------------------------------------------------------------------------------
sub parse_project_specs($$){
    print_function_header();
    my $opt_project_specs = shift;
    my $href_parameters   = shift;
    if( defined($opt_project_specs) ){
        if( $opt_project_specs =~ m|^(${\NFS})/(${\NFS})/(${\NFS})/(${\NFS})$| ){
            $href_parameters->{'project_type'} = $1;
            $href_parameters->{'project_name'} = $2;
            $href_parameters->{'release_name'} = $3;
            $href_parameters->{'metal_stack'}  = $4;
        }else{
            fatal_error("Unable to parse the project specs. It shoud be in the following format:\n".
                        "<project_type>/<project_name>/<release_name>/<metal_stack>");
        }
    }
    print_function_footer();
}

#------------------------------------------------------------------------------
# Read the parameters from a CSV file
#------------------------------------------------------------------------------
sub parse_parameters_file($$$){
    print_function_header();
    my $csvFile         = shift;
    my $href_parameters = shift;
    my $href_hardmacros = shift;

    if( !-e $csvFile ){
        fatal_error("The paramters file '$csvFile' doesn't exists!");
    }
    my @lines = read_file($csvFile);
    # Remove the commented lines
    @lines = grep{ !/^#|^[,\s]*$/ } @lines;
    foreach my $line (@lines){
        my @items = split(",", $line);
        if( $#items >= 1 ){
            $href_parameters->{$items[0]} = $items[1];
        }else{
            vwprint(LOW, "Empty entry in the parameters file: '$items[0]'!");
        }
    }

    # Ensure that the parameters passed include all of the necessary entries and
    # that their values are as expected.
    check_parameters($href_parameters);

    if( $href_parameters->{'project_name'} =~ /gf12lpp18|tsmc3eff|tsmc12ffc18|tsmc16ffc18/ ){
        $href_parameters->{'scale_factor'} = 10000;
    }else{
        $href_parameters->{'scale_factor'} = sprintf("%.0f",1e-6/$href_parameters->{'dbu'});
        if( $href_parameters->{'scale_factor'} == 0 ){
            fatal_error("The scale factor cannot be 0. Please check that you've entered the DBU value correctly.".
                   "The scale factor is related to the DBU by 1e-6/DBU");
        }
    }
    print_function_footer();
}

#------------------------------------------------------------------------------
sub check_parameters($){
    print_function_header();
    my $href_parameters = shift;

    # Ensure that all of the optional items are defined
    my @pvOptions = qw(drc_icv_options_file drc_icv_runset drc_icv_unselect_rule_names
                       drc_error_limit lvs_icv_grid_processes virtual_connect_icv grid
                       fill_icv_grid_processes);
    foreach my $option (@pvOptions){
        if( !defined($href_parameters->{$option}) ){
            $href_parameters->{$option} = EMPTY_STR;
        }
    }
    print_function_footer();
}

sub set_default_pv_switches($){
    print_function_header();
    my $href_parameters = shift;

    $href_parameters->{'grid'} = 1;
    $href_parameters->{'drc_icv_grid_processes'}  = 8;
    $href_parameters->{'lvs_icv_grid_processes'}  = 4;
    $href_parameters->{'fill_icv_grid_processes'} = 4;

    check_parameters($href_parameters);
    print_function_footer();
}

#------------------------------------------------------------------------------
# Checks that the project specs are correct by looking for them in the remote area
#------------------------------------------------------------------------------
sub check_project_specs($){
    print_function_header();
    my $href_parameters = shift;

    my $projectTypePath = "/remote/cad-rep/projects/$href_parameters->{'project_type'}";
    my $projectNamePath = "$projectTypePath/$href_parameters->{'project_name'}";
    my $releaseNamePath = "$projectNamePath/$href_parameters->{'release_name'}";
    if( ! -d $projectTypePath ){
        fatal_error("Unable to find the specified project type in the remote area: '$projectTypePath'");
    }elsif( ! -d $projectNamePath ){
        fatal_error("Unable to find the specified project name in the remote area: '$projectNamePath'");
    }elsif( ! -d $releaseNamePath ){
        fatal_error("Unable to find the specified release in the remote area: '$releaseNamePath'");
    }
    print_function_footer();
}

#------------------------------------------------------------------------------
# The boundary layer is set to the boundary argument's value if it exists, if not
# then the value in the parameters file is used. If it doesn't exists, then the
# technology default is used.
#------------------------------------------------------------------------------
sub set_bounday_layer_LPP($){
    print_function_header();
    my $opt_boundary_layer_lpp = shift;
    my $href_parameters        = shift;
    if( defined($opt_boundary_layer_lpp) ){
        $href_parameters->{'boundary_layer'} = $opt_boundary_layer_lpp;
    }elsif( !defined($href_parameters->{'boundary_layer'}) ){
        my $tech = (split(/-/, $href_parameters->{'project_name'}))[2];
        if( $tech =~ /tsmc/ ){
            $href_parameters->{'boundary_layer'} = "108:0";
        }else{
            fatal_error("The default boundary layer LPP for '$tech' does not exist!\n".
                        "Please add it to the parameters file.");
        }
        hprint("The boundary layer LPP was set to the default value for the technology '$href_parameters->{'boundary_layer'}'");
    }
    print_function_footer();
}

#------------------------------------------------------------------------------
#   get_technology_files: Updates the paths to the technology files (techfile, GdsOutMap)
#                         in the parameters hash if they were not defined beforehand.
#------------------------------------------------------------------------------
sub get_technology_files($){
    print_function_header();
    my $href_parameters = shift;
    if( defined($href_parameters->{'icc2_techfile'})
        && defined($href_parameters->{'icc2_gds_layer_map'}) ){
        hprint("The technology files defined in the parameters file will be used.");
    }else{
        # Use the project's CAD file to get the project's CCS. The technology files 
        # defined in the CCS will be used.
        hprint("Attempting to get the technology files from the project's PCS.");
        my $fname_projEnv = "/remote/cad-rep/projects/$href_parameters->{'project_type'}".
                            "/$href_parameters->{'project_name'}/$href_parameters->{'release_name'}/".
                            "cad/project.env";
        my ( $cadProj, $cadRel, $cadHome ) = getCadHome( $fname_projEnv );
        my $fname_ccsEnv = "$cadHome/$href_parameters->{'metal_stack'}/env.tcl";
        if( !-e $fname_ccsEnv ){
            fatal_error("Unable to find the project's CCS '$fname_ccsEnv'.");
        }
        # Read the env.tcl file in the CCS, and get the techfile/streamlayermap files paths
        # from there.
        my @ccsLines = read_file($fname_ccsEnv);
        my $icc2TechLine        = (grep { /Icc2TechFile/i } @ccsLines)[0];
        my $icc2GdsLayerMapLine = (grep { /Icc2StreamLayerMap/i } @ccsLines)[0];
        if( defined($icc2TechLine) && $icc2TechLine =~ /"(.*)"/ ){
            $href_parameters->{'icc2_techfile'} = $1;
            viprint(LOW, "The path to the ICC2 TechFile found is '$href_parameters->{'icc2_techfile'}'!");
        }else{
            fatal_error("Unable to find the Icc2TechFile in the project's CCS '$fname_ccsEnv'");
        }
        if( defined($icc2GdsLayerMapLine) && $icc2GdsLayerMapLine =~ /"(.*)"/ ){
            $href_parameters->{'icc2_gds_layer_map'} = $1;
            viprint(LOW, "The path to the ICC2 GDS Layer Map found is '$href_parameters->{'icc2_gds_layer_map'}'!");
        }else{
            fatal_error("Unable to find the Icc2StreamLayerMap entry in the project's CCS '$fname_ccsEnv'");
        }
        iprint("Succeeded in getting the technology files paths!");
    }
    print_function_footer();
}

#------------------------------------------------------------------------------
sub get_hardmacros_files($$$$$){
    print_function_header();
    my $dir_p4          = shift;
    my $fname_crr       = shift;
    my $href_hardmacros = shift;
    my $href_parameters = shift;
    my $opt_hardmacros  = shift;

    my @crrLines = read_file($fname_crr);
    my @selectedHardmacros;
    if( defined($opt_hardmacros) ){
        @selectedHardmacros = split(",", $opt_hardmacros);
    }
    # A variable to keep track of the number of def files found.
    my $defCount = 0;
    iprint("Preparing the hardmacros files.");
    # Read the DEF files from the CRR file
    foreach my $defEntry (grep { /\.def#/ } @crrLines){
        if( $defEntry =~ /'(.*)'/ ){
            my $fname_def = get_p4_file($1,$dir_p4);
            my @defLines = read_file($fname_def);
            my $line = (grep {/^DESIGN /} @defLines)[0]; 
            if( defined($line) && $line =~ /^DESIGN (\S+)/ ){
                if( !defined($opt_hardmacros) || grep {/^$1$/} @selectedHardmacros ){
                    $defCount++;
                    $href_hardmacros->{$1}->{"def"} = $fname_def;
                }
            }else{
                eprint("Failed to read the hardmacro name from the DEF file ".
                       "'$fname_def'!\nSkipping file...");
            }
        }
    }
    # Get the DEF entries from the parameters file
    foreach my $defEntry ( grep{ /^def_/ } keys(%{$href_parameters}) ){
        my( $hardmacro ) = $defEntry =~ /def_(\S+)/;
        next if( defined($opt_hardmacros) && grep {/^$hardmacro$/} @selectedHardmacros );

        my $file = $href_parameters->{$defEntry};
        if( $file =~ m|^//depot| ){
            $defCount++;
            $href_hardmacros->{$hardmacro}->{"def"} = get_p4_file($file,$dir_p4);
        }else{
            if( !-e $file ){
                fatal_error("The file '$file' read from the parameters file does not exist!");
            }
            $defCount++;
            $href_hardmacros->{$hardmacro}->{"def"} = $file;
        }
    }
    # Read the hardmacros GDS/CDL files from the CRR file
    foreach my $hardmacro ( keys(%{$href_hardmacros}) ){
        # Get the CDL path from the CRR file.
        my $line = (grep{ /${hardmacro}\.cdl#/ } @crrLines )[0];
        if( defined($line) && $line =~ /'(.*)'/){
            $href_hardmacros->{$hardmacro}->{"cdl"} = get_p4_file($1,$dir_p4);
        }
        # Get the GDS path from the CRR file.
        $line = (grep{ /${hardmacro}\.gds\.gz#/ } @crrLines )[0];
        if( defined($line) && $line =~ /'(.*)'/){
            $href_hardmacros->{$hardmacro}->{"lvl"} = get_p4_file($1,$dir_p4);
        }
    }
    # Get the GDS/CDL entries from the parameters file
    foreach my $entry ( grep{ /^cdl_|^gds_/ } keys(%{$href_parameters}) ){
        my( $view, $hardmacro ) = $entry =~ /(cdl|gds)_(\S+)/;
        next if( defined($opt_hardmacros) && grep {/^$hardmacro$/} @selectedHardmacros );
        $view =~ s/gds/lvl/;

        my $file = $href_parameters->{$entry};
        if( $file =~ m|^//depot| ){
            $href_hardmacros->{$hardmacro}->{$view} = get_p4_file($file,$dir_p4);
        }else{
            if( !-e $file ){
                fatal_error("The file '$file' read from the parameters file does not exist!");
            }
            $href_hardmacros->{$hardmacro}->{$view} = $file;
        }
    }
    # Make sure that there is at least a single DEF file
    if( $defCount == 0 ){
        if( defined($opt_hardmacros) ){
            fatal_error("No DEF files found in the parameters/CRR files that match ".
                   "the supplied list: '$opt_hardmacros'.");
        }else{
            fatal_error("No DEF files found in the parameters/CRR files.");
        }
    }

    print_function_footer();
}

#------------------------------------------------------------------------------
sub parse_def_files($$$){
    print_function_header();
    my $aref_uniqueMacros = shift;
    my $href_hardmacros   = shift;
    my $href_parameters   = shift;
    
    iprint("Reading the DEF files to get the macros list.");
    # Contains hardmacros and CKT macros, will be filtered out later. 
    # uniqueMacros should contain only CKT macros.
    my @uniqueMacros;
    # Create the macros list for each hardmacro
    foreach my $hardmacro ( keys(%{$href_hardmacros}) ){
        if( !defined($href_hardmacros->{$hardmacro}->{"def"}) ){
            wprint("The DEF file for '$hardmacro' was not found! Skipping...");
            next;
        }
        my $fname_def = $href_hardmacros->{$hardmacro}->{"def"};
        my @lines = read_file($fname_def);
        my ( @macros, @bBox );
        # Extract the components block, and add the unique cellnames to the
        # array. Also push to the uniqueMacro array.
        foreach my $line (@lines){
            if( $line =~ /^COMPONENTS/ ..  $line =~ /^END COMPONENTS/ ){
                if( $line =~ /^- \S+ (\S+)/ && !grep {/$1/} @macros ){
                    push(@macros,$1);
                    if( !grep{ /$1/ } @uniqueMacros ){
                        push(@uniqueMacros,$1);
                    }
                }
            }
            # Check the scalefactor in the DEF, it should be the same
            # as the one calculated from the DBU supplied in the parameters
            # file. If the DBU was not supplied, use the scale factor of
            # the first DEF view.
            if( $line =~ /UNITS\s+DISTANCE\s+MICRONS\s+(\d+)/ ){
                $href_hardmacros->{$hardmacro}->{"factor"} = $1/1000;
                if( !defined($href_parameters->{'scale_factor'}) ){
                    hprint("The scalefactor has been defined according to the '$hardmacro' DEF view ".
                           "to be $1.");
                    $href_parameters->{'scale_factor'} = $1;
                }elsif( $href_parameters->{'scale_factor'} ne $1 ){
                    wprint("The scalefactor '$1' defined in the '$hardmacro' DEF view ".
                           "does not match the reference scalefactor $href_parameters->{'scalefactor'}!");
                }
            }
            if( $line =~ /DIEAREA\s+\(\s+(\d+)\s+(\d+)\s+\)\s+\(\s+(\d+)\s+(\d+)\s+\)/ ){
                push(@bBox,$1);
                push(@bBox,$2);
                push(@bBox,$3);
                push(@bBox,$4);
                $href_hardmacros->{$hardmacro}->{"bBox"} = \@bBox;
            }
        }
        $href_hardmacros->{$hardmacro}->{"macros"} = \@macros;
    }

    # Check if any hardmacro is a submacro of another.
    foreach my $hardmacro ( keys(%{$href_hardmacros}) ){
        if( grep{ /^$hardmacro$/ } @uniqueMacros ){
            @uniqueMacros = grep { !/^$hardmacro$/ } @uniqueMacros;
            $href_hardmacros->{$hardmacro}->{'isSubmacro'} = 1;
            foreach my $macro ( keys(%{$href_hardmacros}) ){
                if( grep{ /^$hardmacro$/ } @{$href_hardmacros->{$macro}->{'macros'}} ){
                    push(@{$href_hardmacros->{$macro}->{'submacros'}},$hardmacro);
                }
            }
        }
    }
    foreach my $macro ( @uniqueMacros ) {
        push($aref_uniqueMacros,$macro);
    }

    print_function_footer();
}

#-------------------------------------------------------------------------------
sub sync_macros_files($$$$$$$$){
    print_function_header();
    my $metalStack        = shift;
    my $dir_p4            = shift;
    my $fname_crr         = shift;
    my $fname_pllCrr      = shift;
    my $aref_uniqueMacros = shift;
    my $aref_fileTypes    = shift;
    my $href_macrosViews  = shift;
    my $href_missingViews = shift;


    my @crrLines = read_file($fname_crr);
    # Get the depot path from the CRR and sync the views into the local directory
    foreach my $macro (@{$aref_uniqueMacros}){
        foreach my $view (@{$aref_fileTypes}){
            # Get the depot path from the CRR file.
            my $line = (grep{ /${macro}\.${view}(?:\.gz)?#/ } @crrLines )[0];
            if( defined($line) && $line =~ /'(.*)'/){
                $href_macrosViews->{$macro}->{$view} = get_p4_file($1,$dir_p4);
            }else{
                #eprint("The view '$view' for the macro '$macro' in the DEF view doesn't exist in the CRR!");
                $href_missingViews->{$macro}->{$view}++;
            }
        }
    }
    # Look for the PLL view in the PLL CRR if it was supplied
    if( defined($fname_pllCrr) ){
        my @pllLines = read_file($fname_pllCrr);
        my @pllMacros = grep { /pll/i } keys(%{$href_missingViews});
        foreach my $macro (@pllMacros){
            foreach my $view ( keys(%{$href_missingViews->{$macro}}) ){
                # Get the depot path from the PLL CRR file.
                my $line = (grep{ /$metalStack.*${macro}\.${view}(?:\.gz)?#/ } @pllLines )[0];
                if( defined($line) && $line =~ /'(.*)'/){
                    $href_macrosViews->{$macro}->{$view} = get_p4_file($1,$dir_p4);
                    delete $href_missingViews->[$macro]{$view};
                }
            }
        }
    }
    foreach my $macro ( keys(%{$href_missingViews}) ){
        foreach my $view ( keys(%{$href_missingViews->{$macro}}) ){
            eprint("The '$view' view for the '$macro' macro that was referenced in the ".
                   "DEF views doesn't exist in the CRR!");
        }
    }

    print_function_footer();
}

#-------------------------------------------------------------------------------
sub check_hardmacros_with_missing_components($$$){
    print_function_header();
    my $opt_force         = shift;
    my $href_hardmacros   = shift;
    my $href_missingViews = shift;

    my @incompleteHardmacros;
    my @missingMacrosList = keys(%{$href_missingViews});
    # Arrange the hardmacros so that the submacros are checked before the macros that use them.
    my @hmOrderedList;
    get_hardmacros_ordered_list(\@hmOrderedList, $href_hardmacros);
    foreach my $hardmacro (@hmOrderedList){
        my $aref_commonMacros = intersection(\@missingMacrosList, $href_hardmacros->{$hardmacro}->{"macros"});
        if( @{$aref_commonMacros} ){
            my $message = EMPTY_STR;
            foreach my $macro (@{$aref_commonMacros}) {
                $message .= "\n\t$macro: ". join(", ", keys(%{$href_missingViews->{$macro}}));
            }
            wprint("The CRR file is missing some views for the CKT macros present in the DEF view for '$hardmacro'".
                   $message);
            push(@incompleteHardmacros, $hardmacro);
            if( defined($href_hardmacros->{$hardmacro}->{"isSubmacro"}) ){
                $href_missingViews->{$hardmacro}->{"GDS generated from DEF view"}++;
                push(@missingMacrosList,$hardmacro);
            }
        }
    }
    if( @incompleteHardmacros ){
        if( !defined($opt_force) ){
            $opt_force = prompt_user_yesno("Proceed with the macros with missing component views anyway?", "Y");
        }elsif( $opt_force ){
            hprint("Proceeding with the macros with missing component views!");
        }else{
            hprint("Skiping macros with missing component views!");
        }
        # If the user decided to skip the macros, remove them from the hash
        if( !$opt_force || $opt_force eq "N" ){
            delete @{$href_hardmacros}{@incompleteHardmacros};
        }
    }
    dprint(CRAZY, "\%hardmacros keys=> ". scalar(Dumper (keys(%{$href_hardmacros}))) );
    print_function_footer();
}

#-------------------------------------------------------------------------------
sub create_ref_lib($$){
    print_function_header();
    my $href_parameters  = shift;
    my $href_macrosViews = shift;

    # If a directory called reference_lib.ndm already exists, delete it
    my $dir_refLib = "reference_lib.ndm";
    rmtree($dir_refLib) if( -d $dir_refLib );

    my @lm_lines;
    # Populate the lm(ICC2 Library Manager) array to be written into a file.
    push(@lm_lines, "set exitStatus 0");
    push(@lm_lines, "try {");
    push(@lm_lines, "\tcreate_workspace -technology $href_parameters->{'icc2_techfile'} reference_lib -scale_factor $href_parameters->{'scale_factor'}");
    push(@lm_lines, "\tconfigure_frame_options -mode preserve_all");
    foreach my $macro (keys %{$href_macrosViews}){
        if( defined($href_macrosViews->{$macro}->{"lef"}) ){
            push(@lm_lines, "\tread_lef $href_macrosViews->{$macro}->{'lef'}");
        }
    }
    push(@lm_lines, "\tcheck_workspace");
    push(@lm_lines, "\tcommit_workspace");
    push(@lm_lines, "} on error {- -} {");
    push(@lm_lines, "\tset exitStatus 1");
    push(@lm_lines, "} finally {");
    push(@lm_lines, "\texit \$exitStatus");
    push(@lm_lines, "}");

    my $fname_lm = "lm_generate_reference_lib.tcl";
    write_file(\@lm_lines, $fname_lm);

    my @runLm_lines;
    push(@runLm_lines,"#!/bin/bash");
    push(@runLm_lines,"source /remote/cad-rep/etc/.bashrc");
    push(@runLm_lines,"module unload icc2");
    push(@runLm_lines,"module load icc2");
    push(@runLm_lines,"lm_shell -file lm_generate_reference_lib.tcl");

    my $fname_runLm = "lm_generate_reference_lib.sh";
    write_file(\@runLm_lines, $fname_runLm);
    chmod(0775, $fname_runLm);
    my( $stdout, $status ) = run_system_cmd("./$fname_runLm", $VERBOSITY);
    if( $status != 0 ){
        fatal_error("Failed to generate the referance library, please check the log: lm_output.txt");
    }
    print_function_footer();
}

#-------------------------------------------------------------------------------
sub create_hardmacros_and_run_checks($$$$$){
    print_function_header();
    my $href_parameters  = shift;
    my $href_macrosViews = shift;
    my $href_hardmacros  = shift;
    my $opt_dryrun       = shift;
    my $opt_jobs         = shift;

    # Arrange the hardmacros so that the submacros are done before they are used.
    my @hmOrderedList;
    get_hardmacros_ordered_list(\@hmOrderedList, $href_hardmacros);

    # Create the results directory
    my $resultsDir = "results";
    if( ! -d $resultsDir ){
        if ( 0 == mkdir( $resultsDir )){
            fatal_error("$PROGRAM_NAME failed mkdir of '$resultsDir'\n");
        }
    }

    my $dir_current = getcwd();
    foreach my $hardmacro (@hmOrderedList){
        hprint("Generating the scripts for $hardmacro!");
        # Create an empty directory for the hardmacro and cd into it.
        if( -d $hardmacro ){
            rmtree($hardmacro);
        }
        if ( 0 == mkdir($hardmacro)){
            fatal_error("$PROGRAM_NAME failed mkdir of '$hardmacro'\n");
        }
        chdir($hardmacro);
        # Create the empty CDL if no CDL was defined for this hardmacro in the
        # parameters file.
        if( !defined($href_hardmacros->{$hardmacro}->{'cdl'}) ){
            iprint("\tNo CDL was defined for $hardmacro, creating an empty CDL!");
            create_empty_cdl($hardmacro);
            $href_hardmacros->{$hardmacro}->{'cdl'} = abs_path("${hardmacro}.cdl");
        }
        # Create the run script that will call the other scripts
        $href_hardmacros->{$hardmacro}->{'gds'} = "../$hardmacro/${hardmacro}.gds.gz";
        # Create the GDS generation script
        my $fname_generate_macro = create_generate_macro_script( $hardmacro, $href_parameters,
                                                                 $href_macrosViews, $href_hardmacros);
        # Add the lib path for the submacros
        if( defined($href_hardmacros->{$hardmacro}->{'isSubmacro'}) ){
            $href_macrosViews->{$hardmacro}->{'lib'} = "../$hardmacro/$hardmacro";
        } 
        # Create the results directory and the pv scripts otherwise
        else {
            my $dir_results = "../results/$hardmacro";
            if( -d $dir_results ){
                rmtree($dir_results);
            }
            if ( 0 == mkdir($dir_results)){
                fatal_error("$PROGRAM_NAME failed mkdir of '$dir_results'\n");
            }
            # Create PV scripts
            iprint("\tCreating PV scripts for $hardmacro!");
            my $fname_runPv = create_pv_scripts($hardmacro, $dir_results, $href_parameters,
                                                $href_hardmacros);
        }
        # Return back to the original directory.
        chdir($dir_current);
    }
    # Create the makefile that will handle the dependencies and the parallel execution
    hprint("Creating Makefile!");
    my $fname_makefile = create_makefile($href_hardmacros);
    # Call make
    if( !defined($opt_dryrun) ){
        run_system_cmd("/bin/make $opt_jobs -k", $VERBOSITY+2);
    }
    print_function_footer();
}

#-------------------------------------------------------------------------------
sub get_hardmacros_ordered_list($$){
    print_function_header();
    my $aref_hmOrderedList = shift;
    my $href_hardmacros    = shift;

    my @hardmacros = keys(%{$href_hardmacros});
    while( @hardmacros ){
        for my $index ( 0 .. $#hardmacros ) {
            my $macro = $hardmacros[$index];
            if( defined($href_hardmacros->{$macro}->{'submacros'}) ){
                # If all of the submacros have already been pushed into the 
                # orderedlist, push this hardmmcro too.
                my ($aref_common, undef, undef, undef) = 
                                    compare_lists($href_hardmacros->{$macro}->{'submacros'},
                                                  \@hardmacros);
                if( !@{$aref_common} ){
                    push(@{$aref_hmOrderedList}, $macro);
                    $hardmacros[$index] = "removed";
                }
            }else{
                push(@{$aref_hmOrderedList}, $macro);
                $hardmacros[$index] = "removed";
            }
        }
        # Remove all of the elements that have been pushed to the orderlist.
        @hardmacros = grep{ !/^removed$/ } @hardmacros;
    }
    print_function_footer();
}

#-------------------------------------------------------------------------------
sub create_hardmacro($$$$){
    print_function_header();
    my $hardmacro        = shift;
    my $href_parameters  = shift;
    my $href_macrosViews = shift;
    my $href_hardmacros  = shift;

    # Get the path for each macro GDS to place it according to the DEF.
    my $gdsPaths = EMPTY_STR;
    my $libPaths = EMPTY_STR;
    foreach my $macro (@{$href_hardmacros->{$hardmacro}->{'macros'}}){
        if( defined($href_macrosViews->{$macro}->{'gds'}) ){
            $gdsPaths .= "$href_macrosViews->{$macro}->{'gds'} ";
        }
        if( defined($href_macrosViews->{$macro}->{'lib'}) ){
            $libPaths .= " $href_macrosViews->{$macro}->{'lib'}";
        }
    }
    # Create the ICC2 script
    my @icc2_lines;
    push(@icc2_lines,"set exitStatus 0");
    push(@icc2_lines,"try {");
    push(@icc2_lines,"\tcreate_lib -technology $href_parameters->{'icc2_techfile'} -ref_libs \"../reference_lib.ndm${libPaths}\" $hardmacro");
    push(@icc2_lines,"\tcreate_block $hardmacro");
    push(@icc2_lines,"\tread_def -add_def_only_objects all $href_hardmacros->{$hardmacro}->{'def'}");
    push(@icc2_lines,"\tset_attribute -name physical_status -value locked -objects [get_cells]");
    # Generate the pins so that we can run LVS later on.
    my @generatePins = generate_pin_labels($href_parameters->{'project_name'});
    push(@icc2_lines, @generatePins);
    $gdsPaths =~ s/\s+$//;
    # Write the GDS.
    push(@icc2_lines, "\t".icc2_write_gds($hardmacro, $gdsPaths, $href_parameters));
    push(@icc2_lines,"\tsave_lib");
    push(@icc2_lines,"} on error {- -} {");
    push(@icc2_lines,"\tset exitStatus 1");
    push(@icc2_lines,"} finally {");
    push(@icc2_lines,"\texit \$exitStatus");
    push(@icc2_lines,"}");
    # Save the script into a file.
    my $fname_icc2 = "icc2_write_gds.tcl";
    write_file(\@icc2_lines, $fname_icc2);

    print_function_footer();
    return( $fname_icc2 );
}

#-------------------------------------------------------------------------------
sub generate_pin_labels($){
    print_function_header();
    my $projectName = shift;

    # Names of power supplies for regex matching.
    my $power_supplies = "^(VAA|VDD|VDDQ|VDDQ_VDD2H|VDDQLP|VSH|VSS)\$";
    # The array that will be returned.
    my @lines;
    push(@lines,"set terminals [get_terminals -hierarchical -include_lib_cell]");
    push(@lines,"foreach_in_collection terminal \$terminals {");
    push(@lines,"  set text [get_attribute -objects \$terminal -name port.name]");
    push(@lines,"  set parent_cell_name [get_attribute -objects \$terminal -name parent_cell.name]");
    push(@lines,"  if {[regexp {SpareCell.*} \$parent_cell_name] && !([regexp {${power_supplies}} \$text])} {");
    push(@lines,"    set text \${parent_cell_name}_\$text");
    push(@lines,"  }");
    push(@lines,"  set layer [get_attribute -objects \$terminal -name layer.name]");
    # Using boundary for text origin coordinate instead of bbox as bbox coordinate
    # may not fall within non-rectangular pin shape.
    push(@lines,"  set origin [lindex [get_attribute -objects \$terminal -name boundary] 0]");
    if( $projectName =~ /int22ffl18/ ){
        push(@lines,"  if [regexp {(m\\d+)} \$layer match layer] {");
        push(@lines,"    set layer \${layer}_pin");
    }
    # Check for metal layer by seeing if first letter of layer is M, C, K or G.
    # Text should be added to same metal layer in ICC2 to output to label datatype,
    # hence no "set layer" required.
    elsif( $projectName =~ /gf12lpp18/ ){
        push(@lines,"  if [regexp {^(M|C|K|G)} \$layer match] {");
    }else{
        push(@lines,"  if [regexp {M(\\d+)} \$layer match layer] {");
        push(@lines,"    set layer TEXT\${layer}");
    }
    push(@lines,"    create_shape -shape_type text -layer \$layer -origin \$origin -height 0.1 -text \$text");
    push(@lines,"  }");
    push(@lines,"}");

    print_function_footer();
    return( @lines );
}

#-------------------------------------------------------------------------------
# Copied and adjusted from ddr-utils-lay/ddr-crd_abutment.tcl
#-------------------------------------------------------------------------------
sub icc2_write_gds($$$){
    print_function_header();
    my $macro           = shift;
    my $gdsFiles        = shift;
    my $href_parameters = shift;
    
    my $line;
    if( $href_parameters->{'project_name'} =~ /gf12lpp18|tsmc16ffc18/ ){
        $line = "write_gds -compress -layer_map $href_parameters->{'icc2_gds_layer_map'} ".
                "-long_names -merge_files \"$gdsFiles\" -merge_gds_top_cell $macro ".
                "-units 1000 ${macro}.gds.gz";
    } elsif( $href_parameters->{'project_name'} =~ /tsmc3eff/ ){
        $line = "write_gds -compress -layer_map $href_parameters->{'icc2_gds_layer_map'} ".
                "-long_names -merge_files \"$gdsFiles\" -merge_gds_top_cell $macro ".
                "-units 2000 ${macro}.gds.gz";
    } elsif( $href_parameters->{'project_name'} =~ /tsmc12ffc18/ ){
        $line = "write_gds -compress -layer_map $href_parameters->{'icc2_gds_layer_map'} ".
                "-layer_map_format icc_extended ".
                "-long_names -merge_files \"$gdsFiles\" -merge_gds_top_cell $macro ".
                "-units 1000 ${macro}.gds.gz";
    } else {
        $line = "write_gds -compress -layer_map $href_parameters->{'icc2_gds_layer_map'} ".
                "-long_names -merge_files \"$gdsFiles\" -merge_gds_top_cell $macro ".
                "-units [get_attribute -objects [current_lib] -name scale_factor] ${macro}.gds.gz";
    }

    print_function_footer();
    return( $line );
}

#-------------------------------------------------------------------------------
sub create_boundary($$$){
    print_function_header();
    my $hardmacro       = shift;
    my $boundaryLayer   = shift;
    my $href_hardmacros = shift;

    my $gdsPath = "${hardmacro}.gds.gz";
    my @icvwb_lines;
    push(@icvwb_lines, "layout open $gdsPath $hardmacro");
    push(@icvwb_lines, "cell edit_state 1");
    if(   defined($href_hardmacros->{$hardmacro}->{"factor"}) 
          && defined($href_hardmacros->{$hardmacro}->{"bBox"}) ){
        my @bBox = @{$href_hardmacros->{$hardmacro}->{"bBox"}};
        foreach my $point (@bBox){
            $point = $point / $href_hardmacros->{$hardmacro}->{"factor"};
        }
        push(@icvwb_lines, "set boundary_bbox  \"$bBox[0] $bBox[1] $bBox[2] $bBox[3]\"");
    }else{
        wprint("Failed to read the area for $hardmacro from the DEF. The ".
               "boundary will be generated to include all of the macros.");
        push(@icvwb_lines, "set boundary_bbox [layer bbox $boundaryLayer -levels 1]");
    }
    push(@icvwb_lines, "cell object add rectangle \"coords {\$boundary_bbox} layer $boundaryLayer\"");
    push(@icvwb_lines, "layout save -format gds.gz $gdsPath -rename $gdsPath");
    push(@icvwb_lines, "exit");

    my $fname_icvwb = "icvwb_generate_boundary.mac";
    write_file(\@icvwb_lines, $fname_icvwb);

    print_function_footer();
    return( $fname_icvwb );
}

#-------------------------------------------------------------------------------
sub create_empty_cdl($){
    print_function_header();
    my $macro = shift;

    my @cdl_lines;
    push(@cdl_lines, ".subckt $macro");
    push(@cdl_lines, ".ends $macro");

    my $fname_cdl = "$macro.cdl";
    write_file(\@cdl_lines, $fname_cdl);

    print_function_footer();
}

#-------------------------------------------------------------------------------
sub create_generate_macro_script($$$$){
    my $hardmacro        = shift;
    my $href_parameters  = shift;
    my $href_macrosViews = shift;
    my $href_hardmacros  = shift;

    # Create the ICC2 script that will create the hardmacro GDS from the DEF.
    my $fname_icc2 = create_hardmacro($hardmacro, $href_parameters, $href_macrosViews,
                                      $href_hardmacros);
    # Create a script that will call the scripts that generate the GDS
    my @generate_macro_lines;
    push(@generate_macro_lines, "#!/bin/bash");
    push(@generate_macro_lines, "source /remote/cad-rep/etc/.bashrc");
    push(@generate_macro_lines, "logfile=\"$hardmacro.log\"");
    push(@generate_macro_lines, "refLib=\"$hardmacro\"");
    push(@generate_macro_lines, "if [[ -e \$refLib ]]; then");
    push(@generate_macro_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: GENERATE_GDS: Deleting the old hardmacro library.\" | tee -a \$logfile");
    push(@generate_macro_lines, "\trm -rf \$refLib");
    push(@generate_macro_lines, "fi");
    push(@generate_macro_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: GENERATE_GDS: Generating the hardmacro GDS file.\" | tee -a \$logfile");
    push(@generate_macro_lines, "module unload icc2");
    push(@generate_macro_lines, "module load icc2");
    push(@generate_macro_lines, "icc2_shell -file $fname_icc2 &> $fname_icc2.elog");
    push(@generate_macro_lines, "gdsFile=\"${hardmacro}.gds.gz\"");
    push(@generate_macro_lines, "if [[ ! -f \$gdsFile ]]; then");
    push(@generate_macro_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: GENERATE_GDS: Cannot find the macro's GDS file."
                                ." The generation of the hardmacro GDS failed!\" | tee -a \$logfile");
    push(@generate_macro_lines, "\texit 1");
    push(@generate_macro_lines, "fi");
    push(@generate_macro_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: GENERATE_GDS: Generated the hardmacro GDS file sucessfully.\" | tee -a \$logfile");
    push(@generate_macro_lines, "# Remove the sgz files as they take up a lot of space");
    push(@generate_macro_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: GENERATE_GDS: Removing extra files.\" | tee -a \$logfile");
    push(@generate_macro_lines, "rm -rf *sgz");
    if( !defined($href_hardmacros->{$hardmacro}->{'isSubmacro'}) ){
        # Create the script that generates a boundary around the hardmacro.
        my $fname_icvwb = create_boundary($hardmacro, $href_parameters->{'boundary_layer'}, $href_hardmacros);
        push(@generate_macro_lines, "# Generate the boundary");
        push(@generate_macro_lines, "module unload icvwb");
        push(@generate_macro_lines, "module load icvwb");
        push(@generate_macro_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: GENERATE_GDS: Generating a boundary around the macro as per the DEF file.\" | tee -a \$logfile");
        push(@generate_macro_lines, "icvwb -run $fname_icvwb -nodisplay -log icvwb_generate_boundary.log &> $fname_icvwb.elog");
        push(@generate_macro_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: GENERATE_GDS: Finished generating the boundary\" | tee -a \$logfile");
    }
    # Save the generate_macro script
    my $fname_generate_macro = "generate_gds.sh";
    write_file(\@generate_macro_lines, $fname_generate_macro);
    chmod(0775, $fname_generate_macro);

    print_function_footer();
    return( $fname_generate_macro );
}

#-------------------------------------------------------------------------------
sub create_pv_scripts($$$$){
    print_function_header();
    my $hardmacro       = shift;
    my $dir_results     = shift;
    my $href_parameters = shift;
    my $href_hardmacros = shift;

    my $fname_sourceme = create_sourceme($href_parameters);
    create_fill_files($hardmacro, $fname_sourceme, $dir_results, $href_parameters, $href_hardmacros);
    create_drc_files($hardmacro, $fname_sourceme, $dir_results, $href_parameters, $href_hardmacros);
    create_lvs_files($hardmacro, $fname_sourceme, $dir_results, $href_parameters, $href_hardmacros);
    # Create LVL script if the reference GDS was defined
    if( defined($href_hardmacros->{$hardmacro}->{'lvl'}) ){
        create_lvl_files($hardmacro, $dir_results, $href_hardmacros);
    }

    print_function_footer();
}

#-------------------------------------------------------------------------------
sub create_lvl_files($$$){
    print_function_header();
    my $hardmacro       = shift;
    my $dir_results     = shift;
    my $href_hardmacros = shift;

    my $dir_lvl = "$dir_results/LVL";
    my @runLvl_lines;
    push(@runLvl_lines, "#!/bin/bash");
    push(@runLvl_lines, "source /remote/cad-rep/etc/.bashrc");
    push(@runLvl_lines, "logfile=\"$hardmacro.log\"");
    push(@runLvl_lines, "lvldir=\"$dir_lvl\"");
    push(@runLvl_lines, "if [[ -e \$lvldir ]]; then");
    push(@runLvl_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: LVL: Deleting old LVL run directory\" | tee -a \$logfile");
    push(@runLvl_lines, "\trm -rf \$lvldir");
    push(@runLvl_lines, "fi");
    push(@runLvl_lines, "mkdir \$lvldir");
    push(@runLvl_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: LVL: Running LVL\" | tee -a \$logfile");
    push(@runLvl_lines, "pushd $dir_lvl");
    push(@runLvl_lines, "module unload icv");
    push(@runLvl_lines, "module load icv");
    push(@runLvl_lines, "icv_lvl $href_hardmacros->{$hardmacro}->{'gds'} ".
                        "$href_hardmacros->{$hardmacro}->{'lvl'} ".
                        "-c $hardmacro");
    push(@runLvl_lines, "popd");
    push(@runLvl_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: LVL: Finished running LVL\" | tee -a \$logfile");
    # Save the generate_macro script
    my $fname_runLvl = "pv_lvl_icv.sh";
    write_file(\@runLvl_lines, $fname_runLvl);
    chmod(0775, $fname_runLvl);

    print_function_footer();
    return( $fname_runLvl );
}

#-------------------------------------------------------------------------------
sub create_sourceme($){
    print_function_header();
    my $href_parameters = shift;

    my @sourceme_lines;
    push(@sourceme_lines, "module unload msip_cd_pv");
    if( defined($href_parameters->{'msip_cd_pv'}) ){
        push(@sourceme_lines, "module load msip_cd_pv/$href_parameters->{'msip_cd_pv'}");
    }else{ 
        push(@sourceme_lines, "module load msip_cd_pv");
    }
    push(@sourceme_lines, "setenv RUN_DIR_ROOT \$PWD/pv");

    my $fname_sourceme = "ude_sourceme";
    write_file(\@sourceme_lines, $fname_sourceme);

    print_function_footer();
    return( $fname_sourceme );
}

#-------------------------------------------------------------------------------
sub create_fill_files($$$$$){
    print_function_header();
    my $hardmacro       = shift;
    my $fname_sourceme  = shift;
    my $dir_results     = shift;
    my $href_parameters = shift;
    my $href_hardmacros = shift;

    my @fillConfig_lines;
    push(@fillConfig_lines, "set useGrid \"$href_parameters->{'grid'}\"");
    push(@fillConfig_lines, "set gridProc \"$href_parameters->{'fill_icv_grid_processes'}\"");

    my $fname_fillConfig = "pvbatch_config_fill_icv";
    write_file(\@fillConfig_lines, $fname_fillConfig);

    my $fname_fillfeol = "pv_fillfeol_icv.sh";
    my @fillfeol_lines;
    push(@fillfeol_lines, "#!/bin/bash");
    push(@fillfeol_lines, "source /remote/cad-rep/etc/.bashrc");
    push(@fillfeol_lines, "module unload msip_cd_pv");
    if( defined($href_parameters->{'msip_cd_pv'}) ){
        push(@fillfeol_lines, "module load msip_cd_pv/$href_parameters->{'msip_cd_pv'}");
    }else{ 
        push(@fillfeol_lines, "module load msip_cd_pv");
    }
    push(@fillfeol_lines, "logfile=\"$hardmacro.log\"");
    # FEOL FILL cmd
    push(@fillfeol_lines, "# Call the FEOL run");
    push(@fillfeol_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: FILLFEOL: Calling the FILLFEOL run\" | tee -a \$logfile");
    push(@fillfeol_lines, "pvbatch --projectType $href_parameters->{'project_type'} ".
                          "--projectName $href_parameters->{'project_name'} ".
                          "--releaseName $href_parameters->{'release_name'} ".
                          "--metalStack $href_parameters->{'metal_stack'} ".
                          "--type fill --prefix FILLFEOL ".
                          "--streamPath \$PWD/$href_hardmacros->{$hardmacro}->{'gds'} ".
                          "--cellName $hardmacro --layoutFormat gds --tool icv ".
                          "--config \$PWD/$fname_fillConfig ".
                          "--udeArgs \"--log \$PWD/pvbatch_fillfeol_icv.log ".
                                      "--sourceShellFile $fname_sourceme\" ".
                          "--tmpLibPath &> $fname_fillfeol.elog");
    push(@fillfeol_lines, "# Check that the filling GDS was sucessfully generated");
    push(@fillfeol_lines, "feolGds=\$(find \$PWD -maxdepth 5 -ipath \"*/fillfeol_icv/importFill.gds\" | sort -n | tail -1)");
    push(@fillfeol_lines, "if [[ -z \$feolGds ]]; then");
    push(@fillfeol_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: FILLFEOL: Failed to find the filling GDS!\" | tee -a \$logfile");
    push(@fillfeol_lines, "\texit 1");
    push(@fillfeol_lines, "fi");
    push(@fillfeol_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: FILLFEOL: Finished running successfully!\" | tee -a \$logfile");
    push(@fillfeol_lines, "# Create a symbolic for the run in the results directory");
    push(@fillfeol_lines, "feolicv=\$(find \$PWD -maxdepth 4 -ipath \"*/fillfeol_icv\" | sort -n | tail -1)");
    push(@fillfeol_lines, "ln -sfn \$feolicv $dir_results/fillfeol_icv");
    push(@fillfeol_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: FILLFEOL: Created a symbolic link for the run in the results directory\" | tee -a \$logfile");
    # Save the fillbeol script
    write_file(\@fillfeol_lines, $fname_fillfeol);
    chmod(0775, $fname_fillfeol);
    # Since the FILLBEOL script should have the same lines but with beol instead of FEOL, replace those instances directly.
    my @fillbeol_lines = @fillfeol_lines;
    foreach my $line (@fillbeol_lines){
        $line =~ s/feol/beol/g;
        $line =~ s/FEOL/BEOL/g;
    }
    # Save the fillfeol script
    my $fname_fillbeol = "pv_fillbeol_icv.sh";
    write_file(\@fillbeol_lines, $fname_fillbeol);
    chmod(0775, $fname_fillbeol);
    # Merge script
    my @merge_lines;
    push(@merge_lines, "#!/bin/bash");
    push(@merge_lines, "source /remote/cad-rep/etc/.bashrc");
    push(@merge_lines, "module unload msip_cd_pv");
    if( defined($href_parameters->{'msip_cd_pv'}) ){
        push(@merge_lines, "module load msip_cd_pv/$href_parameters->{'msip_cd_pv'}");
    }else{ 
        push(@merge_lines, "module load msip_cd_pv");
    }
    push(@merge_lines, "logfile=\"$hardmacro.log\"");
    push(@merge_lines, "# Check if the fill GDS files exist");
    push(@merge_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: MERGE: Checking that the fill GDS files exist\" | tee -a \$logfile");
    push(@merge_lines, "beolGds=\"../results/$hardmacro/fillbeol_icv/importFill.gds\"");
    push(@merge_lines, "if [[ ! -f \$beolGds ]]; then");
    push(@merge_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: MERGE: Failed to find the BEOL filling!\" | tee -a \$logfile");
    push(@merge_lines, "\texit 1");
    push(@merge_lines, "fi");
    push(@merge_lines, "feolGds=\"../results/$hardmacro/fillfeol_icv/importFill.gds\"");
    push(@merge_lines, "if [[ ! -f \$feolGds ]]; then");
    push(@merge_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: MERGE: Failed to find the FEOL filling!\" | tee -a \$logfile");
    push(@merge_lines, "\texit 1");
    push(@merge_lines, "fi");
    push(@merge_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: MERGE: Started merging the GDS with the filling.\" | tee -a \$logfile");
    push(@merge_lines, "msip_layGdsMerge -c $hardmacro $href_hardmacros->{$hardmacro}->{'gds'} ".
                       "\$beolGds \$feolGds -o ${hardmacro}_fill.gds.gz ".
                       ">& \$PWD/msip_layGdsMerge.log");
    push(@merge_lines, "mergedGds=\"${hardmacro}_fill.gds.gz\"");
    push(@merge_lines, "if [[ ! -f \$mergedGds ]]; then");
    push(@merge_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: MERGE: Failed to merged the GDS with the filling!\" | tee -a \$logfile");
    push(@merge_lines, "\texit 1");
    push(@merge_lines, "fi");
    push(@merge_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: MERGE: Finished merging the fill with the GDS successfully!\" | tee -a \$logfile");
    # Save the merge script
    my $fname_merge = "pv_merge_fill.sh";
    write_file(\@merge_lines, $fname_merge);
    chmod(0775, $fname_merge);

    print_function_footer();
    return( $fname_fillfeol, $fname_fillbeol, $fname_merge );
}

#-------------------------------------------------------------------------------
sub create_drc_files($$$$$){
    print_function_header();
    my $hardmacro       = shift;
    my $fname_sourceme  = shift;
    my $dir_results     = shift;
    my $href_parameters = shift;
    my $href_hardmacros = shift;

    my @drcConfig_lines;
    push(@drcConfig_lines, "set useGrid $href_parameters->{'grid'}");
    push(@drcConfig_lines, "set gridProc $href_parameters->{'drc_icv_grid_processes'}");
    if( $href_parameters->{'drc_icv_options_file'} ne EMPTY_STR ){
        push(@drcConfig_lines, "set optionsFile $href_parameters->{'drc_icv_options_file'}");
    }
    if( $href_parameters->{'drc_icv_runset'} ne EMPTY_STR ){
        push(@drcConfig_lines, "set runset $href_parameters->{'drc_icv_runset'}");
    }
    if( $href_parameters->{'drc_icv_unselect_rule_names'} ne EMPTY_STR ){
        push(@drcConfig_lines, "set icvUnselectRuleNames \"$href_parameters->{'drc_icv_unselect_rule_names'}\"");
    }
    if( $href_parameters->{'drc_error_limit'} ne EMPTY_STR ){
        push(@drcConfig_lines, "set errorLimitEnabled true");
        push(@drcConfig_lines, "set errorLimit $href_parameters->{'drc_error_limit'}");
    }

    my $fname_drcConfig = "pvbatch_config_drc_icv";
    write_file(\@drcConfig_lines, $fname_drcConfig);

    my $mergedGds = $href_hardmacros->{$hardmacro}->{'gds'} =~ s/.gds.gz/_fill.gds.gz/r;
    my $fname_runDrc = "pv_drc_icv.sh";
    my @drc_lines;
    push(@drc_lines, "#!/bin/bash");
    push(@drc_lines, "source /remote/cad-rep/etc/.bashrc");
    push(@drc_lines, "logfile=\"$hardmacro.log\"");
    push(@drc_lines, "module unload msip_cd_pv");
    if( defined($href_parameters->{'msip_cd_pv'}) ){
        push(@drc_lines, "module load msip_cd_pv/$href_parameters->{'msip_cd_pv'}");
    }else{ 
        push(@drc_lines, "module load msip_cd_pv");
    }
    push(@drc_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: DRC_ICV: Calling DRC_ICV.\" | tee -a \$logfile");
    push(@drc_lines, "pvbatch --projectType $href_parameters->{'project_type'} ".
                      "--projectName $href_parameters->{'project_name'} ".
                      "--releaseName $href_parameters->{'release_name'} ".
                      "--metalStack $href_parameters->{'metal_stack'} ".
                      "--type drc --prefix DRC ".
                      "--streamPath \$PWD/$mergedGds ".
                      "--cellName $hardmacro --layoutFormat gds --tool icv ".
                      "--config \$PWD/$fname_drcConfig ".
                      "--udeArgs \"--log \$PWD/pvbatch_drc_icv.log ".
                                  "--sourceShellFile $fname_sourceme\" ".
                      "--tmpLibPath &> $fname_runDrc.elog");
    # Create the symbolic link for the results
    push(@drc_lines, "drcicv=\$(find \$PWD -maxdepth 4 -ipath \"*/drc_icv\" | sort -n | tail -1)");
    push(@drc_lines, "if [[ -z \$drcicv ]]; then");
    push(@drc_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: DRC_ICV: Failed to find the DRC_ICV run directory!\" | tee -a \$logfile");
    push(@drc_lines, "\texit 1");
    push(@drc_lines, "fi");
    push(@drc_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: DRC_ICV: Finished running successfully!\" | tee -a \$logfile");
    push(@drc_lines, "ln -sfn \$drcicv $dir_results/drc_icv");
    push(@drc_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: DRC_ICV: Created a Created a symbolic link for the run in the results directory.\" | tee -a \$logfile");
    # Save the DRC run script
    write_file(\@drc_lines, $fname_runDrc);
    chmod(0775, $fname_runDrc);

    print_function_footer();
    return( $fname_runDrc );
}

#-------------------------------------------------------------------------------
sub create_lvs_files($$$$$){
    print_function_header();
    my $hardmacro       = shift;
    my $fname_sourceme  = shift;
    my $dir_results     = shift;
    my $href_parameters = shift;
    my $href_hardmacros = shift;

    my @lvsConfig_lines;
    push(@lvsConfig_lines, "set useGrid $href_parameters->{'grid'}");
    push(@lvsConfig_lines, "set gridProc $href_parameters->{'lvs_icv_grid_processes'}");
    if( $href_parameters->{'virtual_connect_icv'} ne EMPTY_STR ){
        push(@lvsConfig_lines, "set virtualConnect $href_parameters->{'virtual_connect_icv'}");
    }

    my $fname_lvsConfig = "pvbatch_config_lvs_icv";
    write_file(\@lvsConfig_lines, $fname_lvsConfig);

    my $mergedGds = $href_hardmacros->{$hardmacro}->{'gds'} =~ s/.gds.gz/_fill.gds.gz/r;
    my $fname_runLvs = "pv_lvs_icv.sh";
    my @lvs_lines;
    push(@lvs_lines, "#!/bin/bash");
    push(@lvs_lines, "source /remote/cad-rep/etc/.bashrc");
    push(@lvs_lines, "logfile=\"$hardmacro.log\"");
    push(@lvs_lines, "module unload msip_cd_pv");
    if( defined($href_parameters->{'msip_cd_pv'}) ){
        push(@lvs_lines, "module load msip_cd_pv/$href_parameters->{'msip_cd_pv'}");
    }else{ 
        push(@lvs_lines, "module load msip_cd_pv");
    }
    push(@lvs_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: LVS_ICV: Calling LVS_ICV.\" | tee -a \$logfile");
    push(@lvs_lines, "pvbatch --projectType $href_parameters->{'project_type'} ".
                      "--projectName $href_parameters->{'project_name'} ".
                      "--releaseName $href_parameters->{'release_name'} ".
                      "--metalStack $href_parameters->{'metal_stack'} ".
                      "--type lvs --prefix LVS ".
                      "--streamPath \$PWD/$mergedGds ".
                      "--cdlPath $href_hardmacros->{$hardmacro}->{'cdl'} ".
                      "--cellName $hardmacro --layoutFormat gds --tool icv ".
                      "--config \$PWD/$fname_lvsConfig ".
                      "--udeArgs \"--log \$PWD/pvbatch_lvs_icv.log ".
                                  "--sourceShellFile $fname_sourceme\" ".
                      "--tmpLibPath &> $fname_runLvs.elog");
    # Create the symbolic link for the results
    push(@lvs_lines, "lvsicv=\$(find \$PWD -maxdepth 4 -ipath \"*/lvs_icv\" | sort -n | tail -1)");
    push(@lvs_lines, "if [[ -z \$lvsicv ]]; then");
    push(@lvs_lines, "\techo \"\$(date +%F_%T_%Z): $hardmacro: LVS_ICV: Failed to find the LVS_ICV run directory!\" | tee -a \$logfile");
    push(@lvs_lines, "\texit 1");
    push(@lvs_lines, "fi");
    push(@lvs_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: LVS_ICV: Finished running successfully!\" | tee -a \$logfile");
    push(@lvs_lines, "ln -sfn \$lvsicv $dir_results/lvs_icv");
    push(@lvs_lines, "echo \"\$(date +%F_%T_%Z): $hardmacro: LVS_ICV: Created a Created a symbolic link for the run in the results directory.\" | tee -a \$logfile");
    # Save the LVS run script
    write_file(\@lvs_lines, $fname_runLvs);
    chmod(0775, $fname_runLvs);

    print_function_footer();
    return( $fname_runLvs );
}

#-------------------------------------------------------------------------------
sub get_p4_file($$){
    print_function_header();
    my $p4File    = shift;
    my $outputDir = shift;

    my $fileBasename = fileparse($p4File, qr/#\d+/ );
    my $outputFile = "$outputDir/$fileBasename";
    my $p4port = 'p4p-us01:1999';
    if( exists $ENV{P4PORT} ){
        $p4port = $ENV{P4PORT}; 
        viprint(MEDIUM, "Using ENV variable 'P4PORT': '$p4port'\n" );
    }else{ 
        wprint( "Need to set your P4PORT ENV variable, check w/your local experts."
               ." Trying default\n\t\t: 'setenv P4PORT $p4port' \n" );
    }
    my $cmd = "p4 -p $p4port print -o $outputFile $p4File";
    run_system_cmd($cmd, $VERBOSITY);
    $outputFile = abs_path($outputFile);
    if( !-e $outputFile ){
        fatal_error("Failed to print the file '$p4File'\nto '$outputFile'!");
    }

    print_function_footer();
    return( $outputFile );
}

#-------------------------------------------------------------------------------
sub create_makefile($){
    print_function_header();
    my $href_hardmacros = shift;

    my( @hardmacrosList, @submacrosList );
    foreach my $macro ( keys(%{$href_hardmacros}) ){
        if( defined($href_hardmacros->{$macro}->{'isSubmacro'}) ){
            push(@submacrosList, $macro);
        } else {
            push(@hardmacrosList, $macro);
        }
    }
    my @makefile_lines;
    push(@makefile_lines, "hardmacros = ". join(" ",@hardmacrosList) );
    push(@makefile_lines, "submacros = ". join(" ",@submacrosList) );
    push(@makefile_lines, "resultsDir = results");
    push(@makefile_lines, "drc_rpts = \$(foreach hardmacro,\$(hardmacros),\$(resultsDir)/"
                          ."\$(hardmacro)/drc_icv/\$(hardmacro).LAYOUT_ERRORS)");
    push(@makefile_lines, "lvs_rpts = \$(foreach hardmacro,\$(hardmacros),\$(resultsDir)/"
                          ."\$(hardmacro)/lvs_icv/\$(hardmacro).RESULTS)");
    push(@makefile_lines, "lvl_rpts = \$(foreach hardmacro,\$(hardmacros),\$(resultsDir)/"
                          ."\$(hardmacro)/LVL)");
    push(@makefile_lines, "fill = \$(foreach hardmacro,\$(hardmacros),\$(hardmacro)/"
                          ."\$(hardmacro)_fill.gds.gz)");
    push(@makefile_lines, "beol = \$(foreach hardmacro,\$(hardmacros),\$(resultsDir)/"
                          ."\$(hardmacro)/fillbeol_icv/importFill.gds)");
    push(@makefile_lines, "feol = \$(foreach hardmacro,\$(hardmacros),\$(resultsDir)/"
                          ."\$(hardmacro)/fillfeol_icv/importFill.gds)");
    push(@makefile_lines, "gds = \$(foreach hardmacro,\$(hardmacros),\$(hardmacro)/"
                          ."\$(hardmacro).gds.gz)");
    push(@makefile_lines, "gds += \$(foreach submacro,\$(submacros),\$(submacro)/"
                          ."\$(submacro).gds.gz)");
    push(@makefile_lines, "");
    push(@makefile_lines, "drc_path = \$(resultsDir)/\$(1)/drc_icv/\$(1).LAYOUT_ERRORS");
    push(@makefile_lines, "lvs_path = \$(resultsDir)/\$(1)/lvs_icv/\$(1).RESULTS");
    push(@makefile_lines, "fill_path = \$\$(basename \$\$(notdir \$(1)))/"
                          ."\$\$(basename \$\$(notdir \$(1)))_fill.gds.gz");
    push(@makefile_lines, "beol_path = \$(resultsDir)/\$\$(dir \$(1))fillbeol_icv/importFill.gds");
    push(@makefile_lines, "feol_path = \$(resultsDir)/\$\$(dir \$(1))fillfeol_icv/importFill.gds");
    push(@makefile_lines, "gds_path = \$\$(word 2,\$\$(subst /, ,\$(1)))/"
                          ."\$\$(word 2,\$\$(subst /, ,\$(1))).gds.gz    ");
    push(@makefile_lines, "");
    push(@makefile_lines, ".PHONY : all \$(hardmacros)");
    push(@makefile_lines, ".SECONDEXPANSION : \$(hardmacros) \$(submacros)");
    push(@makefile_lines, "");
    push(@makefile_lines, "all : \$(hardmacros)");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(hardmacros) : % : \$(call drc_path,\$\$*) \$(call lvs_path,\$\$*)");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(drc_rpts) : % : \$(call fill_path,\$\$*)");
    push(@makefile_lines, "\tcd \$(basename \$(notdir \$@)); qsub -P bnormal -cwd -V -m a -b y ./pv_drc_icv.sh");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(lvs_rpts) : % : \$(call fill_path,\$\$*)");
    push(@makefile_lines, "\tcd \$(basename \$(notdir \$@)); qsub -P bnormal -cwd -V -m a -b y ./pv_lvs_icv.sh");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(lvl_rpts) : % : \$(call gds_path,\$\$*)");
    push(@makefile_lines, "\tcd \$(word 2,\$(subst /, ,\$@)); ./pv_lvl_icv.sh");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(fill) : % : \$(call beol_path,\$\$*) \$(call feol_path,\$\$*)");
    push(@makefile_lines, "\tcd \$(dir \$@); ./pv_merge_fill.sh");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(beol) : % : \$(call gds_path,\$\$*)");
    push(@makefile_lines, "\tcd \$(word 2,\$(subst /, ,\$@)); ./pv_fillbeol_icv.sh");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(feol) : % : \$(call gds_path,\$\$*)");
    push(@makefile_lines, "\tcd \$(word 2,\$(subst /, ,\$@)); ./pv_fillfeol_icv.sh");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(gds) :");
    push(@makefile_lines, "\tcd \$(dir \$@); ./generate_gds.sh");
    push(@makefile_lines, "");
    push(@makefile_lines, "\$(submacros) : % : \$\$*/\$\$*.gds.gz");
    push(@makefile_lines, "");
    foreach my $macro ( keys($href_hardmacros) ){
        if( defined($href_hardmacros->{$macro}->{'lvl'}) ){
            push(@makefile_lines, "$macro : results/$macro/LVL");
        }
        if( defined($href_hardmacros->{$macro}->{'submacros'}) ){
            my $line = "$macro/$macro.gds.gz :";
            foreach my $submacro (@{$href_hardmacros->{$macro}->{'submacros'}}){
                $line .= " $submacro/$submacro.gds.gz"
            }
            push(@makefile_lines, $line);
        }
    }

    # Save the makefile
    my $fname_makefile = "Makefile";                                                     
    write_file(\@makefile_lines, $fname_makefile);

    print_function_footer();
    return( $fname_makefile );
}

;

__END__

=head1 NAME

 alphaCRRHMChecks.pl

=head1 VERSION

 2022ww43

=head1 ABSTRACT 

 The script will sync the release files according to the CRR file in the provided
 parameters file. Then it will create the HM according to the DEF files. The
 filling will then be generated for the HM and DRC/LVS will be run on the merged
 GDS. It can also run LVL aganist the on-the-fly GDS.

=head1 DESCRIPTION

 The script will sync the release files according to the CRR file in the provided
 parameters file into a local directory. It will only sync the files for the
 macros used. Then it will create the hardmacro according to the DEF files. The
 filling will then be generated for the haadmacro and DRC/LVS will be run on the
 merged GDS. If no CDL is provided for the hardmacro, an empty CDL will be
 generated. If a GDS is provided for the hardmacro, LVL will be run aganist the
 on-the-fly GDS. A results directory is created with the symbolic link for the
 PV/LVL runs.

=head1 PARAMETERS FILE
 The parameters file entries used by the script include necessary and optional
 entries. For any entry that expects a path, a depot path with the revision
 number can be used.

=over 4

=item B<NECESSARY>

=over 8

=item B<project_type,E<lt>project typeE<gt>>

=item B<project_name,E<lt>project nameE<gt>>

=item B<release_name,E<lt>release nameE<gt>>

=item B<metal_stack,E<lt>metal stackE<gt>>
    
=item B<icc2_techfile/icc2_gds_layer_map>

 The path for the tech files used by ICC2.

=item B<dbu,E<lt>DBUE<gt>>

 Process DBU in meters.

=item B<boundary_layer,E<lt>LPPE<gt>>

 The LPP of the layer which will be used to create the hardmacro's boundary.

=item B<def_E<lt>hardmacroE<gt>,E<lt>DEF PATHE<gt>>

 Specifies the path to a DEF file for <hardmacro>. It also accepts Perforce paths
 with revisions. The verfications are only run on the hardmacros defined by a
 DEF file.

=item B<cdl_E<lt>hardmacroE<gt>,E<lt>CDL PATHE<gt>>

 Specifies the path to a CDL file for <hardmacro>. It also accepts Perforce paths
 with revisions. The CDL is used when running LVS on the hardmacro. If no CDL
 is supplied for the hardmacro, an empty CDL is generated.

=item B<gds_E<lt>hardmacroE<gt>,E<lt>GDS PATHE<gt>>

 Specifies the path to a GDS file for <hardmacro>. It also accepts Perforce paths
 with revisions. If the GDS is supplied, LVL is run aganist the on-the-fly GDS.

=item B<crr_file,E<lt>CRR PATHE<gt>>

 The path to the CRR file. It also accepts Perforce paths with revisions. The
 DEF/GDS/CDL hardmacro files are synced according to their entries in this file.
 The parameters file entry will be used in case there is a collision between the
 two files. A local copy of the GDS and LEF files of the list of unique CKT 
 macros used throughout all of the DEF files is created to be used when
 constructing the hardmacros. 

=back

=item B<OPTIONAL>

=over 8

=item B<grid,1/0>

 Runs the DRC/LVS on the grid if set to 1.

=item B<drc_icv_processes,#>

 Specifies the number of process to use when running DRC.

=item B<drc_error_limit,#>

 Specifies the error limit when running DRC. If not set, the error limit will
 not be enabled.

=item B<drc_icv_options_file,E<lt>OPTIONS FILE PATHE<gt>>

 The path to the DRC options file. If not used, then the PCS default file will
 be used.

=item B<drc_icv_runset,E<lt>RUNSET FILE PATHE<gt>>

 The path to the DRC runset file. If not used, then the PCS default file will
 be used.

=item B<drc_icv_unselect_rule_names,E<lt>UNSELECTED RULESE<gt>>
    
 The list of unselected rules in the DRC.

=item B<lvs_icv_processes,#>

 Specifies the number of process to use when running DRC.

=item B<virtual_connect_icv,ON/OFF/FOUNNARY_DEFAULT>

 Controls how the virtual connect is handled.

=back

=back

=head1 USAGE

 alphaCRRHMChecks.pl -p <parameters_file_path> [options]

=head2 ARGS

=over 8

=item B<-debug> B<#> 
 
 Print software debug diagnostic messages. Must provide integer argument where
 higher values increase verbosity.

=item B<-Dryrun>

 Creates the hardmacros and prepares the PV scripts but does not run them.

=item B<-help> 
  
 Prints this screen.

=item B<-Hardmacros> B<E<lt>hardmacro1E<gt>,E<lt>hardmacro2E<gt>,...> 
  
 Select the hardmacros to use in the script. The hardmacros should be separated
 by a comma only.

=item B<-parameters> B<Parameters File Path>

 The path to the parameters file. If it is not supplied, the script will not run.

=item B<-verbosity> B<#>

 Print additional messages... Includes details of system calls, etc..
 Must provide integer argument where higher values increase verbosity.

=back

=cut
