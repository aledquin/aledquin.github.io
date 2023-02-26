#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : defCompare.pl
# Author  : Ahmed Hesham(ahmedhes)
# Date    : 07/28/2022
# Purpose : Compares the latest versions of the DI and CKT DEFs on the depot
#           (mapped to the user's perforce)
#
# Modification History
#     000 ahmedhes 07/28/2022
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
use File::Basename qw( dirname basename );
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
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
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
    my ( $opt_nousage, $opt_path, $opt_macrosList, $opt_useOldSubmacros,
         $opt_namingMode ) = process_cmd_line_args();

    # A call to the usage statistics
    unless( defined $opt_nousage ){
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@args ); 
    }

    # Check that the argument is in the correct form. Get the path for the 
    # legalRelease file.
    my( $fname_projRelFile, $projInfo ) = parse_argv($ARGV[0]);

    my ( %legalRelease );
    # Call processLegalReleaseFile that reads the project legal release file 
    # for the project and do some processing using the items read.
    processLegalReleaseFile($fname_projRelFile, \%legalRelease);

    my ( @fname_defFiles );
    # Get the path of the new def files to compare.
    my $defPath = get_def_files($opt_path, $opt_macrosList, $projInfo, \@fname_defFiles);
    
    # Get the CKT and DI release paths on the user's p4
    my( $cktPath, $diPath ) = get_ckt_di_path(\%legalRelease, $opt_useOldSubmacros);

    my( %unmatchedCells, @unparsedFiles );
    foreach my $fname_def (@fname_defFiles){
        my $macro = basename($fname_def, ".def");
        hprint("Checking $macro DEF files...");
        
        # Parse the DEF file
        my( $status, %defCells);
        if( defined($opt_useOldSubmacros) ){
            $status = parse_def($fname_def, $cktPath, \%defCells, $opt_namingMode);
        }else{
            $status = parse_def($fname_def, $defPath, \%defCells, $opt_namingMode);
        }
        if( $status != 0 ){
            eprint("Failed to parse the DEF, skipping $macro!");
            push(@unparsedFiles, $fname_def);
            next;
        }

        my %macroUnmatchedCells;
        # Parse the CKT file and compare it to the DEF
        if( $cktPath ne EMPTY_STR ){
            parse_and_compare_ckt($cktPath, $macro, \@unparsedFiles, \%defCells,
                                  \%macroUnmatchedCells, $opt_namingMode);
        }

        # Parse the DI file and compare it to the DEF
        if( $diPath ne EMPTY_STR ){
            parse_and_compare_di($diPath, $macro, \@unparsedFiles, \%defCells,
                                 \%macroUnmatchedCells, $opt_namingMode);
        }

        # If there are unmached cells for the macro, add the macro to the 
        # unmatched hash
        if( %macroUnmatchedCells ){
            $unmatchedCells{$macro} = \%macroUnmatchedCells;
        }
    }
    hprint("Done!");

    print_report(\@unparsedFiles, \%unmatchedCells);

    exit(0);  
}
############    END Main    ####################
 
#------------------------------------------------------------------------------
sub process_cmd_line_args(){
    my ( $opt_verbosity, $opt_debug, $opt_help, $opt_nousage );
    my ( $opt_path, $opt_macrosList, $opt_useOldSubmacros, $opt_namingMode );
    GetOptions(
          "verbosity=i"     => \$opt_verbosity,
          "debug=i"         => \$opt_debug,
          "help"            => \$opt_help, 
          "nousage"         => \$opt_nousage,
          "path:s"          => \$opt_path,
          "macro:s"         => \$opt_macrosList,
          "oldsubmacros"    => \$opt_useOldSubmacros,
          "NamingMode=i"    => \$opt_namingMode,
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

    # If the namingMode has not been set, set it to 0. If it was set, check that
    # it's within range.
    my $nNamingModes = 2;
    if( !defined($opt_namingMode) ){
        $opt_namingMode = 0;
    }elsif( $opt_namingMode < 0 || $opt_namingMode > $nNamingModes ){
        fatal_error("The naming mode '$opt_namingMode' should be within ".
               "the range 0..$nNamingModes");
    }

    return( $opt_nousage, $opt_path, $opt_macrosList, $opt_useOldSubmacros,
            $opt_namingMode );
}

#-------------------------------------------------------------------------------
sub parse_argv($){
    print_function_header();
    my $projInfo = shift;
    
    # Check that the input is in the correct format
    if( $projInfo !~ /^[^\/]+\/[^\/]+\/[^\/]+$/ ){
       fatal_error( "Command line arguments '$projInfo' was expected to be ".
               "<project_type>/<project>/<CD_rel>\n" );
    }

    my $projPathAbs       = "/remote/cad-rep/projects/$projInfo";
    my $fname_projRelFile = firstAvailableFile(
       "$projPathAbs/design/legalRelease.yml",
       "$projPathAbs/design/legalRelease.txt",
       "$projPathAbs/design_unrestricted/legalRelease.yml",
       "$projPathAbs/design_unrestricted/legalRelease.txt");
    if( $fname_projRelFile eq EMPTY_STR ){
       $fname_projRelFile = "$projPathAbs/design/legalRelease.yml";
    }

    print_function_footer();
    return ( $fname_projRelFile, $projInfo );
}

#-------------------------------------------------------------------------------
sub get_ckt_di_path($$){
    print_function_header();
    my $href_legalRelease   = shift;
    my $opt_useOldSubmacros = shift;

    # Get the CKT release path
    my $cktPath = "/u/$ENV{'USER'}/p4_ws/$href_legalRelease->{'p4ReleaseRoot'}/".
                  "ckt/rel/floorplans/$href_legalRelease->{'rel'}";
    if( !-d $cktPath ){
        # If the CKT release path doesn't exist, and the use old submacros switch
        # was set, then the cells cannot be flattened and the DEF cannot be compared
        # with the DI. Abort.
        if( defined($opt_useOldSubmacros) ){
            fatal_error("The path for the CKT DEF files '$cktPath' does not exist!\n".
                   "Cannot flatten using the old submacros DEF files. Aborting.");
        }else{
            eprint("The path for the CKT DEF files '$cktPath' does not exist!");
            $cktPath = EMPTY_STR;
        }
    }
    # Get the DI release path
    my $diPath = "/u/$ENV{'USER'}/p4_ws/$href_legalRelease->{'p4ReleaseRoot'}/".
                 "di/rel";
    if( !-d $diPath ){
        eprint("The path for the DI DEF files '$diPath' does not exist!");
        $diPath = EMPTY_STR;
    }
    # If neither path exist, then there is nothing to compare. Abort.
    if( $cktPath eq EMPTY_STR && $diPath eq EMPTY_STR ){
        fatal_error("The path for the CKT and DI DEF files couldn't be found.");
    }

    print_function_footer();
    return( $cktPath, $diPath );
}

#-------------------------------------------------------------------------------
sub get_def_files($$$$){
    print_function_header();
    my $opt_path           = shift;
    my $opt_macrosList     = shift;
    my $projInfo           = shift;
    my $aref_fname_defFiles = shift;

    # The default path for the DEF generated from the LEF_GEN tool
    my $path = "/u/$ENV{'USER'}/cd_lib/$projInfo/design";
    if( defined($opt_path) ){
        if( -d $opt_path ){
            #Non-destructively remove the last / from the path
            $path = $opt_path =~ s/\/$//r;
        }else{
            fatal_error("The path '$opt_path' does not exist!");
        }
    }elsif( !-d $path ){
        fatal_error("The project path '$path' does not exist!");
    }
    # Look for the DEF files for the macroslist passed, or get all of the DEF
    # files in the directory. Abort if no files were found.
    if( defined($opt_macrosList) ){
        my @macros = split(/\,|\s+/,$opt_macrosList);
        foreach my $macro (@macros){
            my $fname_def = (glob("$path/$macro.def*"))[0];
            if( !defined($fname_def) || !-e $fname_def ){
                eprint("The DEF file '$path/$macro.def' does not exist!");
            }else{
                push(@{$aref_fname_defFiles}, $fname_def);
            }
        }
        if( !@{$aref_fname_defFiles} ){
            fatal_error("No DEF files found for the macros list '$opt_macrosList' in '$path'!");
        }
    }else{
        @{$aref_fname_defFiles} = glob("$path/*.def");
        if( !@{$aref_fname_defFiles} ){
            fatal_error("No DEF files found in '$path'!");
        }
    }

    print_function_footer();
    return( $path );
}

#-------------------------------------------------------------------------------
sub get_latest_di_files($$$){
    print_function_header();
    my $diPath         = shift;
    my $macro          = shift;
    my $aref_diDefList = shift;

    foreach my $rel ( reverse(glob("$diPath/*")) ){
        @{$aref_diDefList} = glob("$rel/$macro/views/def/*/$macro.def*");
        if( @{$aref_diDefList} ){
            last;
        }
    }
    print_function_footer();
}

#-------------------------------------------------------------------------------
sub parse_and_compare_ckt($$$$$$){
    print_function_header();
    my $cktPath                  = shift;
    my $macro                    = shift;
    my $aref_unparsedFiles       = shift;
    my $href_defCells            = shift;
    my $href_macroUnmatchedCells = shift;
    my $opt_namingMode           = shift;

    my $fname_cktDef = "$cktPath/${macro}.def";
    if( !-e $fname_cktDef ){
        wprint("The CKT DEF file '$fname_cktDef' does not exist!");
        push(@{$aref_unparsedFiles}, $fname_cktDef);
    }else{
        my %cktCells;
        my $status = parse_def($fname_cktDef, EMPTY_STR, \%cktCells, $opt_namingMode);
        if( $status != 0 ){
            eprint("Failed to parse the CKT DEF, ".
                   "can not compare with '$fname_cktDef'!");
            push(@{$aref_unparsedFiles}, $fname_cktDef);
        }else{
            compare_ckt_def($href_defCells, \%cktCells, $href_macroUnmatchedCells);
        }
    }
    print_function_footer();
}

#-------------------------------------------------------------------------------
sub parse_and_compare_di($$$$$$){
    print_function_header();
    my $diPath                   = shift;
    my $macro                    = shift;
    my $aref_unparsedFiles       = shift;
    my $href_defCells            = shift;
    my $href_macroUnmatchedCells = shift;
    my $opt_namingMode           = shift;

    my @diDefList;
    my $diMacroName = get_di_macro_name($macro, $opt_namingMode);
    get_latest_di_files($diPath, $diMacroName, \@diDefList);
    if( !@diDefList ){
        wprint("Could not find a DI DEF file for '$macro'!");
        push(@{$aref_unparsedFiles}, "$diPath/*/$diMacroName/views/def/*/".
                                     "$diMacroName.def*");
    }else{
        foreach my $fname_diDef (@diDefList){
            my %diCells;
            my $status = parse_def($fname_diDef, EMPTY_STR, \%diCells,
                                   $opt_namingMode);
            if( $status != 0 ){
                eprint("Failed to parse the DI DEF '$fname_diDef'!");
                push(@{$aref_unparsedFiles}, $fname_diDef);
            }else{
                iprint("Comparing the DEF against the DI file '$fname_diDef'!");
                compare_di_def($href_defCells, \%diCells, $href_macroUnmatchedCells);
            }
        }
    }
    print_function_footer();
}

#-------------------------------------------------------------------------------
sub get_di_macro_name($$){
    print_function_header();
    my $macro          = shift;
    my $opt_namingMode = shift;

    my( $diMacroName );
    # 0: No change
    if( $opt_namingMode == 0 ){
        $diMacroName = $macro;
    }
    # 1: Add _top before the orientation (ew|ns)
    elsif( $opt_namingMode == 1 ){
        $diMacroName = $macro =~ s/(_ew$|_ns$)/_top$1/r;
    }
    # 2: Remove _inst, add _top before the orientation (ew|ns)
    elsif( $opt_namingMode == 2 ){
        $diMacroName = $macro =~ s/_inst//r;
        $diMacroName =~ s/(_ew$|_ns$)/_top$1/;
    }
    viprint(LOW, "The DI macro name for the CKT macro '$macro' is '$diMacroName'!");

    print_function_footer();
    return( $diMacroName );
}

#-------------------------------------------------------------------------------
sub get_ckt_macro_name($$){
    print_function_header();
    my $macro          = shift;
    my $opt_namingMode = shift;

    my( $cktMacroName );
    # 0: No change
    if( $opt_namingMode == 0 ){
        $cktMacroName = $macro;
    }
    # 1: Remove _top
    elsif( $opt_namingMode == 1 ){
        $cktMacroName = $macro =~ s/_top_/_/r;
    }
    # 2: Remove _top, append _inst
    elsif( $opt_namingMode == 2 ){
        $cktMacroName = $macro =~ s/_top_/_/r;
        $cktMacroName .= "_inst"
    }
    viprint(LOW, "The CKT macro name for the DI macro '$macro' is '$cktMacroName'!");

    print_function_footer();
    return( $cktMacroName );
}

#-------------------------------------------------------------------------------
sub parse_def($$$$){
    print_function_header();
    my $fname_def      = shift;
    my $submacrosPath  = shift;
    my $href_cellsList = shift;
    my $opt_namingMode = shift;

    my( $DFH );
    if( $fname_def =~ /\.gz$/ ){
        open($DFH, "-|", "zcat $fname_def") || confess("Failed to open '$fname_def':$!");  # nolint
    }else{
        open($DFH, "<", $fname_def) || confess("Failed to open '$fname_def':$!");  # nolint
    }
    my @content = <$DFH>;
    close($DFH);

    my( @topLevelCells, @flattenedCells );
    my $unitsDistance = 0;

    # Extract the components block, and read the units distance.
    my $unitsDistanceLine = (grep{/^UNITS DISTANCE MICRONS/} @content)[0];
    ($unitsDistance) = $unitsDistanceLine =~ /(\d+)/ if( defined($unitsDistanceLine) );
    my $status = "before";
    my $componentsLines = EMPTY_STR;
    foreach my $line (@content){
        if( $line =~ /END COMPONENTS/ ){
            last;
        }elsif( $status eq "COMPONENTS" ){
            $componentsLines .= trim($line);
        }elsif( $line =~ /^COMPONENTS/ ){
            $status = "COMPONENTS";
        }
    }

    # If the units distance was not found, skip the DEF.
    if( $unitsDistance == 0 ){
        eprint("Failed to find the units distance property in '$fname_def'!\n");
        $href_cellsList->{'unitsDistance'} = $unitsDistance;
        return( -1 );
    }
    $href_cellsList->{'unitsDistance'} = $unitsDistance;

    # Get the placement property for each component.
    my @components = split(";",$componentsLines);
    foreach my $comp (@components){
        # Split the component properties string at '+'
        my @properties = split("\\+", $comp);
        # Get the cell name and remove the first entry from the properties array 
        my $cellName = shift(@properties) =~ s/.*\s+(\w+)\s*/$1/r;
        # Get the placement details of the cell
        foreach my $prop (@properties){
            if( $prop =~ /^\s*COVER|^\s*PLACED|^\s*FIXED/ && $prop=~ /\s*\w+\s+\(\s+(\d+)\s+(\d+)\s+\)\s+(\w+)/ ){
                # x = $1, y = $2, $orient = $3
                push(@topLevelCells,[$cellName,$1,$2,$3]);
                last;
            }elsif( $prop =~ /^\s*UNPLACED/ ){
                eprint("The '$cellName' cell has a placement status of UNPLACED in ".
                       "'$fname_def'!");
                last;
            }
        }
    }
    # If the cells array is empty, skip the DEF
    if( @topLevelCells ){
        $href_cellsList->{'topLevel'} = \@topLevelCells;
    }else{
        eprint("No cells found in '$fname_def'!");
        return -1;
    }
    # Flatten the cells if possible, for the comparison with the DI files.
    # This is done only for the DEF files, and skipped for the DI/CKT files.
    if( defined($submacrosPath) && $submacrosPath ne EMPTY_STR ){
        flatten_def($submacrosPath, $fname_def, $unitsDistance, \@topLevelCells,
                    \@flattenedCells, $opt_namingMode);
        $href_cellsList->{'flattened'} = \@flattenedCells;
    }

    print_function_footer();
    return( 0 );
}

#-------------------------------------------------------------------------------
sub flatten_def($$$$){
    print_function_header();
    my $submacrosPath       = shift;
    my $fname_def           = shift;
    my $unitsDistance       = shift;
    my $aref_topLevelCells  = shift;
    my $aref_flattenedCells = shift;
    my $opt_namingMode      = shift;

    foreach my $aref_cellPlacement (@{$aref_topLevelCells}){
        my $cellName = $aref_cellPlacement->[0];
        # Get the submacro existing DEF files list (should only be one, but 
        # just in case there is a zipped and a non-zipped versions).
        my $cktSubmacroName = get_ckt_macro_name($cellName, $opt_namingMode);
        my $fname_submacroDef = (glob("$submacrosPath/${cktSubmacroName}.def*"))[0];
        # If there is a submacro DEF, flatten the cell
        if( defined($fname_submacroDef)  ){
            # Check if the orientation of the cell is N. Flatten the cell if so,
            # leave it as it is otherwise.
            if( $aref_cellPlacement->[3] ne "N" ){
                eprint("Could not flatten the cell '$cellName' because its orientation".
                       " is not R0(N). Currently, only R0(N) is supported.");
                push(@{$aref_flattenedCells}, $aref_cellPlacement);
                next;
            }
            my %submacroCellsList;
            # Recusrively get the list of cells within the submacro 
            my $status = parse_def($fname_submacroDef, $submacrosPath, \%submacroCellsList,
                                   $opt_namingMode);
            # If the units distance is missing from the submacro, leave it
            # as it is.
            if( $status != 0 ){
                wprint("Could not parse the file '$fname_submacroDef'!\n".
                       "Keeping the cell as it is.");
                push(@{$aref_flattenedCells}, $aref_cellPlacement);
            }
            # If the flattened array of the submacro is not defined or empty, 
            # then there is an issue.
            elsif( !defined($submacroCellsList{'flattened'}) 
                   || !@{$submacroCellsList{'flattened'}} ){
                wprint("The flattened cells list for '$cellName' is empty!\n".
                       "The parsed file is '$fname_submacroDef'\n".
                       "Keeping the cell as it is.");
                push(@{$aref_flattenedCells}, $aref_cellPlacement);
            }
            # Otherwise, flatten the cell. Since the orientation of the cell in 
            # the top view is always N, we only need to move the subcells
            # according to the cell position. Append the cells to the flattened
            # array with the updated position, and don't append the original cell.
            else{
                my $factor = $unitsDistance/$submacroCellsList{'unitsDistance'};
                if( $unitsDistance != $submacroCellsList{'unitsDistance'} ){
                    wprint("There is a disparency in the unit distance definition ".
                           "across the files!\n\t$fname_def\n\t$fname_submacroDef");
                }
                foreach my $aref_subcell (@{$submacroCellsList{'flattened'}}){
                    my $subcellX = $factor*$aref_subcell->[1] + $aref_cellPlacement->[1];
                    my $subcellY = $factor*$aref_subcell->[2] + $aref_cellPlacement->[2];
                    push(@{$aref_flattenedCells},[$aref_subcell->[0],$subcellX,
                                          $subcellY,$aref_subcell->[3]]);
                }
            }
        }else{
            push(@{$aref_flattenedCells}, $aref_cellPlacement);
        }
    }
    print_function_footer();
}

#-------------------------------------------------------------------------------
sub compare_ckt_def($$$){
    print_function_header();
    my $href_defCells  = shift;
    my $href_cktCells  = shift;
    my $href_unmatchedCells = shift;

    iprint("Comparing the DEF against the CKT file!");
    # Compare the toplevel only
    my @defTopCell = @{$href_defCells->{'topLevel'}};
    my @cktTopCell = @{$href_cktCells->{'topLevel'}};

    for( my $defIndex = $#defTopCell; $defIndex >= 0; $defIndex-- ){
        for( my $cktIndex = $#cktTopCell; $cktIndex >= 0; $cktIndex-- ){
            # Check if the cells match. If so, remove both elements.
            if(@{$defTopCell[$defIndex]} ~~ @{$cktTopCell[$cktIndex]}){
                splice(@defTopCell,$defIndex,1);
                splice(@cktTopCell,$cktIndex,1);
                last;
            }
        }
    }

    # Check if there are unmatched DEF/CKT cells.
    if( @defTopCell ){
        $href_unmatchedCells->{'CKT'}->{'DEF'} = \@defTopCell;
        wprint("\tThere are ".scalar(@defTopCell)." unmatched DEF cells!");
    }else{
        iprint("\tThere are no unmatched DEF cells");
    }
    if( @cktTopCell ){
        $href_unmatchedCells->{'CKT'}->{'CKT'} = \@cktTopCell;
        wprint("\tThere are ".scalar(@cktTopCell)." unmatched CKT cells!");
    }else{
        iprint("\tThere are no unmatched CKT cells");
    }

    print_function_footer();
}

#-------------------------------------------------------------------------------
sub compare_di_def($$$){
    print_function_header();
    my $href_defCells  = shift;
    my $href_diCells   = shift;
    my $href_unmatchedCells = shift;

    # Compare the DEF flattened againist the DI toplevel
    my @defTopCell = @{$href_defCells->{'flattened'}};
    my @diTopCell  = @{$href_diCells->{'topLevel'}};

    for( my $defIndex = $#defTopCell; $defIndex >= 0; $defIndex-- ){
        for( my $diIndex = $#diTopCell; $diIndex >= 0; $diIndex-- ){
            # Check if the cells match. If so, remove both elements.
            if(@{$defTopCell[$defIndex]} ~~ @{$diTopCell[$diIndex]}){
                splice(@defTopCell,$defIndex,1);
                splice(@diTopCell,$diIndex,1);
                last;
            }
        }
    }

    # Check if there are unmatched DEF cells. DI will always have extra cells
    # which will be ignored.
    if( @defTopCell ){
        $href_unmatchedCells->{'DI'}->{'DEF'} = \@defTopCell;
        wprint("\tThere are ".scalar(@defTopCell)." unmatched DEF cells!");
    }else{
        iprint("\tThere are no unmatched DEF cells");
    }

    print_function_footer();
}

#-------------------------------------------------------------------------------
sub print_report($$){
    print_function_header();
    my $aref_unparsedFiles  = shift;
    my $href_unmatchedCells = shift;

    hprint("Issues summary:");
    # Print unparsed files
    if( @{$aref_unparsedFiles} ){
        eprint("Some files were missing or could not be parsed:\n\t".
               join("\n\t",@{$aref_unparsedFiles}));
    }else{
        hprint("There are no missing/unparsed files!");
    }

    # Print mismatches
    if( %{$href_unmatchedCells} ){
        foreach my $macro (sort(keys(%{$href_unmatchedCells}))) {
            eprint("There are unmatched cells in '$macro'!");
            foreach my $type (sort(keys(%{$href_unmatchedCells->{$macro}}))){
                foreach my $file (sort(keys(%{$href_unmatchedCells->{$macro}->{$type}}))){
                    my $unmatchedCellsMsg = EMPTY_STR;
                    foreach my $aref_cell (@{$href_unmatchedCells->{$macro}->{$type}->{$file}}){
                        $unmatchedCellsMsg .= "\n\t\t".join(" ",@{$aref_cell});
                    }
                    wprint("\tUnmatched cells in the $file file in the comparsion with $type:".
                           $unmatchedCellsMsg);
                }
            }
        }
    }else{
        hprint("There are no unmatched cells!");
    }

    print_function_footer();
}
;

__END__

=head1 NAME

 defCompare.pl

=head1 VERSION

 2022ww31

=head1 ABSTRACT

 Compares the DI and CKT DEF files on the user's P4 against the newly generated
 DEF files. 

=head1 DESCRIPTION

 The script compares the CKT and the DI DEF files found on the user's P4 against
 newly generated DEF files. 

=head2 CKT/DI Versions

 The release version for the CKT files depened on the legalRelease file. While 
 the latest versions available for each DI DEF file is used.

=head2 Comparsion (Toplevel/Flatten)

 When comparing with the CKT DEF, only the toplevel cells will be compared. While
 when comparing with the DI DEF, the cells within the new DEF files will be
 flattened using the DEF files in the same directory. Only cells with orientation
 R0(N) can be flattened. In case the DEF for the submacros are not generated,
 the option -o should be used to flatten the cells using the DEF files in the CKT
 release directory.

=head2 CKT/DI Naming Discrepancy

 In case the CKT and the DI macro file names do not match, the -N option with the 
 appropriate value should be used.

=head1 USAGE

defCompare.pl <project_type>/<project>/<CD_rel> [options]

=head2 ARGS

=over 8

=item B<-help> 
  
 Prints this screen.

=item B<-verbosity> B<#>

 Print additional messages... Includes details of system calls, etc..
 Must provide integer argument where higher values increase verbosity.

=item B<-debug> B<#> 
 
 Print software debug diagnostic messages. Must provide integer argument where
 higher values increase verbosity.

=item B<-path> 
 
 Changes the path for the new DEF files. The default path is 
    ~/cd_lib/<project_type>/<project>/<CD_rel>/design

=item B<-macro> 

 Takes a comma separated list with CKT macros names. The script will only compare
 the macros found in this list. Otherwise, it will compare all macros found in 
 the directory.

=item B<-old> 

 When flattening, the DEF files in the CKT release directory will be used for the
 submacros definition.

=item B<-NamingMode> B<#> 

 Changes the expected DI macro name depending on value passed. The new DEF files
 are assumed to have the same naming convention as the CKT files.
    0: No change (Default)
    1: Add _top before the orientation (_ew|_ns)
    2: Remove the trailing _inst, and add _top before the
       orientation (_ew|_ns)

=back

=cut
