#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use Carp;
use Cwd;

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use alphaHLDepotRelease;
#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version(); 
#--------------------------------------------------------------------#
use Getopt::Long;
use File::Path;
use XML::LibXML;

#---------------------
# GLOBAL Vars
#---------------------
my $g_latest_release_required = 0;
my $tempDirectory;
my ( $drm_version, $drm_name );
#Array holds extracted information from the file for icv and calibre tools
my (%fileInfo) = (
    'icv'     => [],
    'calibre' => [],
);
#---------------------

BEGIN {
    our $AUTHOR='jfisher, juliano, ljames';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
    local $?;   ## adding this will pass the status of failure if the script
                ## does not compile; otherwise this will always return 0
    footer();
    write_stdout_log( $LOGFILENAME );
}


#------------------------------------------------------------------------------
#  START MAIN
#------------------------------------------------------------------------------
sub Main(){
    # Hashmap for storing information regarding design rule checks
    my %notes;
    my $product = NULL_VAL;
    my $version = NULL_VAL;

    my @orig_argv = @ARGV;  # keep this here cause GetOpts modifies ARGV
    my ( $opt_projSPEC, $opt_macros, $opt_p4ws,
         $opt_nousage,  $opt_help ) = process_cmd_line_args();

    unless( $opt_help || $DEBUG || defined $opt_nousage ){
        utils__script_usage_statistics( $RealScript, $VERSION, \@orig_argv);
    }

    ## Absolute path to the cad-rep directory
    my ($projType, $proj, $pcsRel) =  parse_project_spec( $opt_projSPEC, \&usage );
    my $scriptDir   = "/remote/cad-rep/msip/tools/bin";
    my $projPathAbs = "/remote/cad-rep/projects/$projType/$proj/$pcsRel/design";
    my $fname_legalRelease = "$projPathAbs/legalRelease.txt";
    my %legalRelease;
    processLegalReleaseFile( $fname_legalRelease, \%legalRelease);

    #openLegalVerifsFile( "$projPathAbs/legalVerifs.txt", \%legalRelease );
    parseLegalVerifsInfo( \%legalRelease );
    my $scriptPath  = "$scriptDir/msip_viciGenerateFdkLltechReport.pl";
    #name of the msip generated CAD file.
    my $CADDirectoryName = generateCadCompList( $proj, $pcsRel,
                                  $fname_legalRelease, $scriptPath );
    
    dprint(HIGH, "MAIN: \$CADDirectoryName='$CADDirectoryName'\n" );
    openCadGeneratedFile( \%notes, $CADDirectoryName );
       $scriptPath = "$scriptDir/msip_viciGenerateIpTagXml.pl";
    ($product, $version) = extractProductAndVersion( 'projectReleaseIpTag.xml',
                      $opt_macros, $proj, $pcsRel, $fname_legalRelease,
                      $scriptPath, $CADDirectoryName );
    createOutputFile( \%notes, $proj, $opt_macros, $product, $version );
    removeTemporaryDirectories( $CADDirectoryName );

    exit(0);
} # 



#------------------------------------------------------------------------------
# extract technology name
#------------------------------------------------------------------------------
sub extractNode($) {
    print_function_header();
    my $proj = shift;

    my @words          = split('-', $proj);
    my $length         = scalar @words;
    my $potential_node = $words[ $length - 1 ];
    my $answer         = "n/a";

    my @foundries = qw (
                        gf ss tsmc hsmc mifs fsl sony ibm hhgrace std intel
                        silterra reliability smic dongbu gsmc fjts n5 st
                        skywater huali ifx  usjc  powerchip
                       );
    foreach my $foundary (@foundries) {
        if ( $potential_node =~ /.*$foundary.*/ ) {
            $answer = $foundary;
        }
    }

    if ( $answer eq "n/a" ) {
        my $potential_node2 = $words[ $length - 2 ];
        foreach my $foundary (@foundries) {
            if ( $potential_node2 =~ /.*$foundary.*/ ) {
                return $potential_node2;
            }
        }
    }
    else {
        return $potential_node;
    }
}

#------------------------------------------------------------------------------
# Look in legalRelease file for Legal Verifications settings
# Globals:
#       %fileInfo
#------------------------------------------------------------------------------
sub parseLegalVerifsInfo($) {
    print_function_header();
    my $href_legalRelease = shift;

    my @rows;

    foreach my $report ( @{$href_legalRelease->{'icv_report_list'}} ){
        push(@rows, "icv/$report");
    }
    foreach my $report ( @{$href_legalRelease->{'calibre_report_list'}} ){
        push(@rows, "calibre/$report");
    }

    foreach my $row ( @rows ) {
        chomp $row;
        if ( $row =~ "^icv/" ) {
            my @spl = split( '/', $row, 2 );
            push @{ $fileInfo{'icv'} }, $spl[1];
        }
        if ( $row =~ "^calibre/" ) {
            my @spl = split( '/', $row, 2 );
            push @{ $fileInfo{'calibre'} }, $spl[1];
        }
    }


    #print information regarding various verification checks being performed.
    foreach my $key ( keys %fileInfo ) {
        for my $i ( 0 .. $#{ $fileInfo{$key} } ) {
            my $p = $fileInfo{$key}[$i];
            viprint(LOW, "Checking $key:$p\n" );
        }
    }

    print_function_footer();
}

#------------------------------------------------------------------------------
# Extract the latest release
#------------------------------------------------------------------------------
sub getLatestRelease($$) {
    print_function_header();
    my $filename = shift;
    my $CADDirectoryName = shift;
    my @lines;

    if ( 0 == read_file_aref($filename, \@lines, ':encoding(UTF-8)')){ 
        foreach my $line ( @lines ) {
            if ( $line =~ /^\s*set\s+vrel|^\s*set\s+vcrel/ ) {
                if ( $line =~ /"([^"]*[a-z])"/ ) {
                    iprint( "Latest realease is '$1'\n" );
                    $g_latest_release_required = 1;
                    return $1;
                }
            }
        }
    }else{
        removeTemporaryDirectories( $CADDirectoryName );
        confess "Could not open file '$filename'. \nExiting\n";
    }

    print_function_footer();
    return "None";  # returns when vrel or vcrel not found in the file
}

#------------------------------------------------------------------------------
# Extract information from the msip_*GenerateCad*.pl's output file
#------------------------------------------------------------------------------
sub generateCadCompList($$$$$) {
    print_function_header();
    my $proj        = shift;
    my $pcsRel      = shift;
    my $fname_legalRelease    = shift;
    my $scriptPath            = shift;

    my $epoc          = time();
    my $CADDirectoryName = "$epoc-$proj";

    #extract release number without the "rel" prefix.
    my  $scriptRel = substr( "$pcsRel", 3 );

    my $options = "--rt lltech --dir $CADDirectoryName";
    $scriptRel .= "a";

    viprint(LOW, "$CADDirectoryName\n" );

    iprint("Executing MSIP VC script.\n");
    my $cmd = "$scriptPath -p $proj -r $scriptRel $options";
    my ( $stdout, $retval ) = run_system_cmd($cmd, $VERBOSITY);
    viprint(LOW, $stdout );

    if( index( $stdout, "one" ) != -1 ){
        iprint "Generated CAD file successfully\n";
    }
    else {
        iprint "Trying to execute script with the latest release in legalRelease.txt.\n";
        $epoc             = time();
        $tempDirectory    = $CADDirectoryName;
        $CADDirectoryName = "$epoc-$proj";
        $scriptRel        = getLatestRelease( "$fname_legalRelease", $CADDirectoryName );
        $options          = "--rt lltech --dir $CADDirectoryName";
        my $cmd = "$scriptPath -p $proj -r $scriptRel $options";
        my ( $stdout, $retval ) = run_system_cmd($cmd, $VERBOSITY);
        viprint(LOW, $stdout );
    }

    print_function_footer();
    return( $CADDirectoryName );
}

#------------------------------------------------------------------------------
# Generate Product and Version information.
#------------------------------------------------------------------------------
sub projectReleaseIPTag($$$$$) {
    print_function_header();
    my $fname_legalRel   = shift;
    my $proj             = shift;
    my $pcsRel           = shift;
    my $scriptPath       = shift;
    my $CADDirectoryName = shift;
    #extract release number without the "rel" prefix.
    my $scriptRel;
    if( $g_latest_release_required ){
        $scriptRel = getLatestRelease($fname_legalRel, $CADDirectoryName);
    }
    else {
        $scriptRel = substr( "$pcsRel", 3 ) . "a";
    }

    iprint("Executing MSIP TAG script.\n");
    my $cmd = "$scriptPath -p $proj -r $scriptRel";
    my ( $stdout, $retval ) = run_system_cmd($cmd, $VERBOSITY);

    if( index( $stdout, "one" ) != -1 ){
        iprint "Generated IPTag file successfully\n";
        return 0;
    }
    else {
        viprint(LOW, $stdout );
    }

    print_function_footer();
    return 1;
}

#------------------------------------------------------------------------------
# Find the product and version information from the XML file.
#------------------------------------------------------------------------------
sub extractProductAndVersion($$$$$$) {
    print_function_header();
    my $filename   = shift;
    my $opt_macros = shift;
    my $proj       = shift;
    my $pcsRel     = shift;
    my $fname_legalRelease = shift;
    my $scriptPath         = shift;
    my $CADDirectoryName   = shift;


    if( projectReleaseIPTag($fname_legalRelease, $proj, $pcsRel, $scriptPath, $CADDirectoryName) ){
     	confess "Error generating IPTag file. \nExiting.\n";
    }

    # my $filename ='./output.xml';
    my $dom = XML::LibXML->load_xml( location => $filename );
    my @var = $dom->findnodes('//_Section/_Item/_Info');

    #macro index
    my $index = -1;

    #search for the Info containing the macro name
    for ( my $i = 0 ; $i < scalar @var ; $i++ ) {

        my @list = $var[$i]->findnodes('./_Item/_Sub/_Value');

        if ( $list[0]->to_literal() eq $opt_macros ) {
            viprint( LOW, $list[0]->to_literal() . ": Found at index $i.\n" );
            $index = $i;
        }
    }

    my ($product, $version) = ( NULL_VAL, NULL_VAL );
    if( $index == -1 ){
        $product = "";
        $version = "";
        return( $product, $version );
    }

    #search for the product and version
    my @subs = $var[$index]->findnodes('./_Item/_Sub');

    for ( my $i = 0 ; $i < scalar @subs ; $i++ ) {

        if ( $subs[$i]->findvalue('./_Label') eq "Version" ) {
            $version = $subs[$i]->findvalue('./_Value');

            #print $version. "\n";
        }

        elsif ( $subs[$i]->findvalue('./_Label') eq "Product" ) {
            $product = $subs[$i]->findvalue('./_Value');

            #print $product. "\n";
        }

    }

    print_function_footer();
    return( $product, $version );
}

#------------------------------------------------------------------------------
# Create output file
#------------------------------------------------------------------------------
sub createOutputFile($$$$$) {
    print_function_header();
    my $href_notes = shift;
    my $proj       = shift;
    my $opt_macros = shift;
    my $product    = shift;
    my $version    = shift;

    my $file = "$proj-WAIVER.txt";
    my $FILE;
    my @waivers;
    unless( open $FILE, '>' , $file ){ #nolint open>
        removeTemporaryDirectories();
        confess "\nUnable to create $file\n";
    } 
    close( $FILE );

    my @manual_output = ("Process Information", "Design Rule Manual", "Waiver request", "IP", "Vendor", "Project", "Product", "Version" );;
    my %params = map { $_ => 1 } @manual_output;
   
    my %finalOutput = compileOutput( $href_notes, $proj, $opt_macros, $product, $version );
    foreach my $i (@manual_output){
        push(@waivers, "$i: $finalOutput{$i}\n" );
    }

    foreach my $key (sort keys %finalOutput) {
        if(! exists($params{$key})){
            push(@waivers, "$key: $finalOutput{$key}\n" );
        }
    }

    write_file( \@waivers, $file );
    iprint "File created: $file\n";

    print_function_footer();
}

#------------------------------------------------------------------------------
# prepare data to be written to the file
#------------------------------------------------------------------------------
sub compileOutput($$$$) {
    print_function_header();
    my $href_notes = shift;
    my $proj       = shift;
    my $opt_macros = shift;
    my $product    = shift;
    my $version    = shift;

    my ( %finalOutput, %notes, @keys_to_check );  
    my ( $drm_filename, $drm_package_name, $drm_package_version ) = ( NULL_VAL, NULL_VAL, NULL_VAL );

    #find all keys that are from the legalVerifs file
    for my $tool ( keys %fileInfo ){
        for my $i ( 0 .. $#{ $fileInfo{$tool} } ){
            #intialise loop counter
            my $p      = 0;
            my $length = scalar keys %notes;
            for my $key ( keys %notes ) {
                $p++;
                
                my $upperCaseCheck = uc( $fileInfo{$tool}[$i] );

                #check for newer dumps
                my $searchString   = ".*$tool $upperCaseCheck.*";
                #check for older dumps
                my $searchString2   = ".*$upperCaseCheck $tool.*";
                
                if ( $key =~ /$searchString/i || $key =~ /$searchString2/i ) {                    
                    push @keys_to_check, $key;
                    last;
                }

                #print N/A if the check was not found.
                if( $p == $length ){
                    iprint "$tool $upperCaseCheck: N/A\n";
                }
            }
        }
    }   

    #extract the deck filenames, or package names
    foreach my $check ( @keys_to_check ){
        my $filename;
        my $package_name;
        my $package_version;

        foreach  my $key (keys $notes{$check}) {
            if ($key =~ /.*file.*name.*/i){                   
                $filename = $notes{$check}{$key};
            } 
            elsif ($key =~ /.*package.*name.*/i){                   
                $package_name = $notes{$check}{$key};
            } 
            elsif ($key =~ /.*version.*/i){                   
                $package_version = $notes{$check}{$key};
            }            
        }
        
        # assemble the final output
        $finalOutput{$check} = ($filename =~ /na/i) ? $package_name : "$filename $package_version";

    }    

    # extract the design rule manual name
    foreach my $key ( keys %notes ){
        if( $key =~ /.*design.*rule.*/i ){

            foreach  my $item (keys $notes{$key}) {                
                if ($item =~ /.*file.*name.*/i ){                     
                    $drm_filename = $notes{$key}{$item};
                } 
                elsif ($item =~ /.*package.*name.*/i ){                       
                    $drm_package_name = $notes{$key}{$item};
                }  
                elsif ($item =~ /.*version.*/i ){                       
                    $drm_package_version = $notes{$key}{$item};
                }      
            }
            last;
        }
    }
    
    $href_notes = \%notes;

    # assemble the final output
    $finalOutput{"Design Rule Manual"}  = ($drm_filename =~ /na/i) ? $drm_package_name : "$drm_filename $drm_package_version";
    $finalOutput{"Process Information"} = extractNode( $proj );
    $finalOutput{"Waiver request"} = "IP";    
    $finalOutput{"Project"} = $proj;
    $finalOutput{"IP"}      = $opt_macros;
    $finalOutput{"Vendor"}  = "Synopsys, Inc.";
    $finalOutput{"Product"} = ($product eq "") ? "N/A (not found)" : $product;
    $finalOutput{"Version"} = ($version eq "") ? "N/A (not found)" : $version;  

    print_function_footer();
    return( %finalOutput );
}

#------------------------------------------------------------------------------
# open CadGenerated File and extract information
#------------------------------------------------------------------------------
sub openCadGeneratedFile($$) {
    print_function_header();
    my $href_notes       = shift;
    my $CADDirectoryName = shift;

    my $directory = "./$CADDirectoryName";
    #my $directory = "./directory";
    opendir( DIR, $directory ) or confess "Failed to open dir '$directory': $!";

    my $latestFile;
    while ( my $file = readdir(DIR) ) {
        if ( index( $file, "Latest" ) >= 0 ) {
            $latestFile = $file;
        }
    }

    my $location = "$directory/$latestFile";

    my @lines;
    my $status = read_file_aref( $location, \@lines, ':encoding(UTF-8)' );

    my $lastKey = "";
    for my $line ( @lines ){
        next if( $line =~ /^\#/ );
        my @matches = ( $line =~ /([^:]+)/ig );

        #this check ensures that we get 3 different matches from the regex
        if( scalar(@matches) == 3 ){
            if( length( trim $matches[0]) == 0 ){
                my $key   = trim $matches[1] ;
                my $value = trim $matches[2] ;
                $href_notes->{$lastKey}{$key} = $value;
            }
            else {
                $lastKey  = trim $matches[0] ; 
                my $key   = trim $matches[1] ;
                my $value = trim $matches[2] ;
                $href_notes->{$lastKey}{$key} = $value;             
            }
        }
    }
    print_function_footer();
}

#------------------------------------------------------------------------------
sub removeTemporaryDirectories($) {
    print_function_header();
    my $CADDir = shift;

    if( defined $CADDir && -e $CADDir && $CADDir ne "" ){ rmtree $CADDir; }
    unless( defined $tempDirectory && -e $tempDirectory && $tempDirectory eq "" ){ rmtree $tempDirectory; }
    run_system_cmd("rm -rf projectReleaseIpTag.xml", $VERBOSITY);
}

#------------------------------------------------------------------------------
sub process_cmd_line_args() {
    ## get specified args
    my($opt_p4ws,     $opt_nocosim, $opt_macros, $opt_hspice, $opt_ibis,
       $opt_projSPEC, $opt_nousage, $opt_help,   $opt_debug,  $opt_verbosity);

    my $success = GetOptions(
       "help!"       => \$opt_help,
       "p=s"         => \$opt_projSPEC,
       "macros=s"    => \$opt_macros,
       "p4ws=s"      => \$opt_p4ws,
       "nousage"     => \$opt_nousage,
       "debug=i"     => \$opt_debug,
       "verbosity=i" => \$opt_verbosity,
    );

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    &usage(1) unless( defined $opt_projSPEC );

    return( $opt_projSPEC, $opt_macros, $opt_p4ws, $opt_nousage, $opt_help );
}


#-----------------------------------------------------------------------------
sub usage($) {
    my $exit_status = shift;

    print << "EOP" ;

USAGE : $PROGRAM_NAME [options] -p <projSPEC> -macro <arg>
EXAMPLE: $PROGRAM_NAME  -p ddr43/d528-ddr43-ss11lpp18/rel1.00 -macro dwc_ddrphy_utility_cells

------------------------------------
Required Args:
------------------------------------
-p          <projSPEC>   <project_type>/<project>/<CD_rel>
-macro      <arg>        macro to release


------------------------------------
Optional Args:
------------------------------------
-help              print this screen
-p4ws       <arg>  Overrides path to your personal Perforce work area (default: \$HOME/p4_ws)
-nousage           do not report the usage of this script
-verbosity  <#>    print additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    print additional diagnostic messagess to debug script


EOP
    exit($exit_status);
}


1;
