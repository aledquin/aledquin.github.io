#!/depot/perl-5.14.2/bin/perl
#################################################################################
#
#  Name    : gen_ckt_cell_cfgs.pl
#  Author  : Patrick Juliano
#  Date    : Oct 2020
#  Purpose : Automation used to capture components & metal stacks from CKT rel
#            infrastructure in p4.  Assumption here is that the user is always
#            using the latest file version of topcells.txt and legalRelease.txt
#
#################################################################################

use strict;
use warnings;
use Devel::StackTrace;
use Data::Dumper;
use File::Copy;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Cwd;
use Carp qw(cluck confess croak);
use FindBin;
use Capture::Tiny qw/capture/;
use FindBin qw($RealBin $RealScript);
#------
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use alphaHLDepotRelease;  # firstAvailableFile,
use GenCFG qw( extract_list_of_macros 
               create_log_of_bad_lines
               slurp_p4_file_content 
               map_legal_verifs
               get_manifest_file 
               parse_legalRelease_hash);

#---- GLOBAL VARs------------------#
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
#----------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $TESTMODE  = NONE;
#----------------------------------#

#----------------------------------
# Use remote disk mirror of P4 server
#----------------------------------
use constant P4BASE     => '/remote/cad-rep/projects/';
use constant CMD_EXTRCT => 'cat ';
use constant P4PCS      => '';
#----------------------------------
# Use P4 SERVER --> use lines below 
#----------------------------------
#use constant P4BASE      => '//wwcad/msip/projects/';
#use constant CMD_EXTRCT  => 'p4 print ';
#use constant P4PCS       => '/pcs/';
#----------------------------------
# Global Definitions
#----------------------------------
# nolint [ValuesAndExpressions::ProhibitConstantPragma]
use constant RETVAL_IF_NO_MATCH => 'N/A';
use constant P4LGL        => 'legalRelease.txt'; 
use constant P4TOP        => 'topcells.txt';
use constant P4LV         => 'legalVerifs.txt'; #list of icv and calibre PV reports needed Jira P80001562-226745
use constant RELVER       => 'relver';
use constant UTILITY      => 'utility';
use constant HSPICE       => 'hspice';
use constant REPEATER     => 'repeater';
use constant IBIS         => 'ibis';
use constant TESTCHIP     => 'testchip';
use constant IGNORE       => 'ignore';
use constant DEF          => 'def_macros'; #added for floorplans Jira P80001562-217084
use constant CTL          => 'ctl_macros';
use constant MSTACK_FDY   => 'mstack_fdy';
use constant MSTACK_IP    => 'mstack_ip';
use constant MSTACK_CVR   => 'mstack_cvr';
use constant TIMING_CASES => 'timing_cases';
use constant ROOT         => 'root';
use constant REGEX_MACROS => '^\[(?:SCH|LAY)\]\S+/(\S+)/(?:schematic|layout)';
use constant REGEX_REFS   => '^\[(REF.*)\]\[(?:SCH|LAY)\]\S+/(\S+)/(?:schematic|layout)';
use constant REGEX_PROJ   => '^\[(REF[0-9]+)\]([a-z].*)';
use constant REF_GDS      => 'reference_gds';
#----------------------------------

BEGIN {
    our $AUTHOR  = 'challa, golnaz, juliano';
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


sub Main {
   my @orig_argv = @ARGV; # keep this here cause GetOpts modifies ARGV
   my %legalRelease;      # P10020416-38799 filled in by call to processLegalReleaseFile 
   my %list_legalRelease = (  # P10020416-38799 , things this script needs; the values of these are what we expect
                              # to be returned in the legalRelease hash table.
      RELVER      ,  'rel',
      MSTACK_FDY  ,  'metalStack',
      MSTACK_IP   ,  'metalStackIp',
      MSTACK_CVR  ,  'metalStackCover',
      TIMING_CASES,  'timingLibs',
      ROOT,          'p4ReleaseRoot',
      UTILITY,       'utilityMacro',
      REPEATER,      'repeaterMacro',
      DEF,           'releaseDefMacro', # for extracting def macros for floorplans Jira P80001562-217084
      CTL,           'releaseCtlMacro', # for extracting macros that require a ctl view Jira P80001562-217438
      TESTCHIP,      'releaseTCMacro',
      IGNORE,        'releaseIgnoreMacro',
      REF_GDS,       'referenceGdses',   # regex for extracting extra reference gds files needed Jira P80001562-226758
   );
   my %list_translated = ( # P10020416-38799 to translate processLegalRelease keys to original keys used in ckt_variables
        # legalRelease key,   ckt_variables Key
        'relver',             RELVER,
        'metalStack',         'metal_stack',
        'metalStackIp',       MSTACK_IP,
        'metalStackMinIp',    'metal_stack_minimum', # same thing as MSTACK_IP
        'metalStackCover',    MSTACK_CVR,
        'timingLibs',         TIMING_CASES,
        'p4ReleaseRoot',      ROOT,
        'utilityMacro',       UTILITY,
        'repeaterMacro',      REPEATER,
        'releaseDefMacro',    'releaseDefMacro', # for extracting def macros for floorplans Jira P80001562-217084
        'releaseCtlMacro',    'releaseCtlMacro', # for extracting macros that require a ctl view Jira P80001562-217438
        'releaseTCMacro',     'releaseTCMacro',
        'releaseIgnoreMacro', 'releaseIgnoreMacro',
        'referenceGdses',     REF_GDS,   # regex for extracting extra reference gds files needed Jira P80001562-226758
   );

   my ($fname_ckt_cfg, $fname_ckt_mm);
   my %opts = process_cmd_line_args();
   if( defined($opts{output}) ){
      $fname_ckt_cfg = "$opts{output}";
   }else{
      $fname_ckt_cfg = "ckt_config_content.cfg";
   }

   unless( defined($opts{debug}) || defined($opts{nousage}) ){
      &utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_argv );
   }

   $fname_ckt_mm = get_manifest_file( $opts{proj}, $opts{manifest} );

   #--- Parse file: topcells.txt -------------------------------------------
   my @all_macros;
   my $cmd = CMD_EXTRCT . "$opts{+P4TOP}";
   my $stdout = slurp_p4_file_content( $cmd , P4TOP );
   my ( $aref_bad_lines, %components) =  extract_list_of_macros( $stdout, REGEX_MACROS, REGEX_PROJ, REGEX_REFS );
   #my $fname = "/u/juliano/GitLab/perl/test/topcells-bad-line-examples.txt";
   #create_log_of_bad_lines( $fname, $cmd, $aref_bad_lines );

   #-------------------------------------------------------
   # Combine all category of macros into single list
   foreach my $key ( keys %components ){
       push(@all_macros, @{$components{$key}} ); 
   }
   dprint_dumper(HIGH, "List '\@all_macros:\t", \@all_macros );
   prompt_before_continue(SUPER);
   my @ordered_list_of_uniq_components = @{$components{DEFAULT}};

   #---------------------------------------------------------------------------------------------------
   #----assigning a short_cell name to the macros that require an ibis/hspice view for every product family
   #--- Note: these macros are predetermined and constant per product family ------------
   #------ Jira P80001562-216939 ---------------
 
   my %LPDDR54_HSPICE_IBIS_COMPONENTS_CELL_LIST = ( 
         'dwc_ddrphy_sec_io'  ,   'sec',
         'dwc_ddrphy_diff_io' ,   'diff',
         'dwc_ddrphy_se_io'   ,   'se',
         );
   my %DDR54_HSPICE_IBIS_COMPONENTS_CELL_LIST = ( 
         'dwc_ddrphy_memreset'  ,   'memreset',
         'dwc_ddrphy_txrxac'    ,   'ac',
         'dwc_ddrphy_txrxdq'    ,   'dq',
         'dwc_ddrphy_txrxdqs'   ,   'dqs',
         );
   my %LPDDR5X_HSPICE_IBIS_COMPONENTS_CELL_LIST = ( 
         'dwc_lpddr5xphy_txrxac'   ,   'ac',
         'dwc_lpddr5xphy_txrxcmos' ,   'cmos',
         'dwc_lpddr5xphy_txrxcs'   ,   'cs',
         'dwc_lpddr5xphy_txrxdq'   ,   'dq',
         'dwc_lpddr5xphy_txrxdqs'  ,   'dqs',
         );
   my %DDR5_HSPICE_IBIS_COMPONENTS_CELL_LIST = ( 
         'dwc_ddr5phy_txrxac'   ,   'ac',
         'dwc_ddr5phy_txrxcmos' ,   'cmos',
         'dwc_ddr5phy_txrxcs'   ,   'cs',
         'dwc_ddr5phy_txrxdq'   ,   'dq',
         'dwc_ddr5phy_txrxdqs'  ,   'dqs',
         );

   my %hspice_ibis_full_list = ();
     
   #----- gen_hspice_ibis_hash subroutine will return a hash table which stores the short_cell and orientation for every macro that exists in topcell.txt (@all_macros) ---- 
   if( $opts{proj} =~ m/lpddr54/i ){
      %hspice_ibis_full_list = gen_hspice_ibis_hash (\%LPDDR54_HSPICE_IBIS_COMPONENTS_CELL_LIST, \@all_macros);
   }elsif( $opts{proj} =~ m/ddr54/i ){
      %hspice_ibis_full_list = gen_hspice_ibis_hash (\%DDR54_HSPICE_IBIS_COMPONENTS_CELL_LIST, \@all_macros);
   }elsif( $opts{proj} =~ m/lpddr5x/i ){
      %hspice_ibis_full_list = gen_hspice_ibis_hash (\%LPDDR5X_HSPICE_IBIS_COMPONENTS_CELL_LIST, \@all_macros);
   }elsif( $opts{proj} =~ m/ddr5/i ){
      %hspice_ibis_full_list = gen_hspice_ibis_hash (\%DDR5_HSPICE_IBIS_COMPONENTS_CELL_LIST, \@all_macros);
   }
   my @hspice = keys %hspice_ibis_full_list;
   my @ibis = keys %hspice_ibis_full_list;   

#--- Parse file: legalRelease.txt----------------------------------------
   my $legalRelease_filename = $opts{+P4LGL};
   # processLegalReleaseFile will parse everything in the legalRelease.txt file and store the
   # results into the given hash table 'legalRelease'.
   processLegalReleaseFile( $legalRelease_filename, \%legalRelease );

   # parse_legalRelease_hash goes thru the legalRelease hash and plucks out the
   # items listed in list_legalRelease
   my %ckt_variables = parse_legalRelease_hash( 
       \%legalRelease,       # legalRelease hash table
       \%list_legalRelease,  # What we are looking for {cktkey, lrkey}...
       \%list_translated     # {lrkey, cktKey}...
   );

   # P10020416-38799 - remove this code (replaced by the above code)
   # $cmd = CMD_EXTRCT . "$opts{+P4LGL}";
   # $stdout = slurp_p4_file_content( $cmd, P4LGL );
   # my %ckt_variables = parse_legalRelease_file( \%regexes_legalRelease, 
   #         split(/\n+/, $stdout) );
   
   #------------------------------------------------------------------------
  
   dprint_dumper(LOW, "ckt_variables:", \%ckt_variables);
   
   if( defined($opts{release}) ){  
        # Note: In Perl, to use a constant and not have it treated as a string,
        # like "UTILITY"; a plus-sign can prefix the constant name to prevent
        # that from happening.

        my @utility  = split_ckt_var( \%ckt_variables, UTILITY );
        my @repeater = split_ckt_var( \%ckt_variables, REPEATER);
        my @testchip = split_ckt_var(\%ckt_variables, TESTCHIP);
        my @ignoreMacro = split_ckt_var(\%ckt_variables, IGNORE);
        if    ($opts{release} =~ /hspice/i)   { (@ordered_list_of_uniq_components) = (@hspice,'HSPICE_model_app_note') ;} #adding hspice and ibis release check Jira P80001562-216939
        if    ($opts{release} =~ /ibis/i)     { (@ordered_list_of_uniq_components) = (@ibis);     }  #adding hspice and ibis release check Jira P80001562-216939
        elsif ($opts{release} =~ /utility/i)  { (@ordered_list_of_uniq_components) = (@utility);  }
        elsif ($opts{release} =~ /repeater/i) { (@ordered_list_of_uniq_components) = (@repeater); }
        elsif ($opts{release} =~ /tc/i)       { (@ordered_list_of_uniq_components) = (@testchip); }
        #added floorplans Jira P80001562-217084
        #updated to not remove hspice macros from the list as they are still needed for the main run, however the hspice and ibis views are waived in the ref for the main run and included in hspice and ibis separete runs
        elsif ($opts{release} =~ /main/i )    { 
            (@ordered_list_of_uniq_components) =( remove_array_from_array(
                    \@ordered_list_of_uniq_components, \@utility, \@repeater, 
                    \@testchip, \@ignoreMacro), 'floorplans');
        }
   } 
   
   @{$components{DEFAULT}} = @ordered_list_of_uniq_components;
   
   my @complete_cell_list;
   foreach my $key ( keys %components ){ 
        @{$components{$key}} = unique_scalars(\@{$components{$key}}); 
        push(@complete_cell_list, @{$components{$key}});
   }
   dprint_dumper(MEDIUM, "Final list of Cell Names:\n\t", \%components);

   my $pvt_config;
   #---- For utility and repeater cells pvt corners will need to be picked up from legalVcCorners.csv Jira P80001562-217093
   if ($opts{release} =~ /utility/i or $opts{release} =~ /repeater/i){
      $pvt_config = firstAvailableFile(P4BASE.$opts{proj}.'/design/legalVcCorners.csv',P4BASE.$opts{proj}.'/design_unrestricted/legalVcCorners.csv');
   }else{
      $pvt_config = firstAvailableFile(P4BASE.$opts{proj}.'/design/timing/nt/ntFiles/alphaNT.config',P4BASE.$opts{proj}.'/design_unrestricted/timing/nt/ntFiles/alphaNT.config') ;
   }
   my $pvt_values = get_pvt_values($pvt_config);

   #-------------------------------------------------------
   #--- Parse file: legalVerifs.txt -------------------------------------------
   #--- Jira P80001562-226745 ---

   #--- Jira P10020416-38799 
   #
   #$cmd = CMD_EXTRCT . "$opts{+P4LV}";
   #$stdout = slurp_p4_file_content( $cmd , P4LV );
   # P10020416-38799 .. gather the legalVerifs data from the legalRelease hash table
   my %legalVerifs =  map_legal_verifs( \%legalRelease);

   #-------------------------------------------------------------------------------
   #  Using info from topcells + legalRelease, construct the ckt CFG content
   #-------------------------------------------------------------------------------
   my @cfg_content = build_ckt_cfg_content( $pvt_values, 
       \%ckt_variables, \%components, \@complete_cell_list, $opts{proj}, 
       $fname_ckt_mm, $opts{phase}, \%hspice_ibis_full_list, $opts{release}, 
       \%legalVerifs);
   write_file( \@cfg_content, $fname_ckt_cfg );
   exit(0);
}
############    END Main    ####################

sub remove_array_from_array() {
   print_function_header();
#  my @main = @{@_[0]}; # CHANGED @_[0] to $_[0] as suggested by perl compiler - ljames
   my @main = @{$_[0]};
   my %tempHash;
   foreach my $aref_type (@_[1..$#_]) {
        @tempHash{@{$aref_type}} = undef;
        @main = grep {not exists $tempHash{$_}} @main;
    }
    return @main;
}

#-------------------------------------------------------------------------------
#  Create the ckt CFG content required for a given release defined by the
#     circuit team's existing infrastructure.
#     using content parsed from topcells.txt and legalRelease.txt
#-------------------------------------------------------------------------------
sub build_ckt_cfg_content($$$$$$$){
   print_function_header();
   my $pvt_values       = shift;
   my $href_cktvars     = shift;
   my $href_components  = shift;
   my $aref_cells       = shift;
   my $proj             = shift;
   my $ckt_mm           = shift;
   my $rel_phase        = shift;
   my $href_hspice_ibis_full_list = shift;
   my $release          = shift;
   my $href_legalVerifs = shift;

   my %hspice_ibis_full_list = %$href_hspice_ibis_full_list;
   my ($refWaiv, $relWaiv, $refRepl, $relRepl);
   my $projName = (split(/\//,$proj))[1];
   my $libgz = '';
   
   my $timing_cases_name = TIMING_CASES;
   my $def_macro_name = DEF;
   my $m_fdy_name    = MSTACK_FDY;
   my $m_ip_name     = MSTACK_IP;
   my $m_cvr_name    = MSTACK_CVR;
   my $version       = $href_cktvars->{+RELVER};


   my $mstack_fdy     = scalar( Dumper $href_cktvars->{+MSTACK_FDY} );
   my $mstack_ip      = scalar( Dumper $href_cktvars->{+MSTACK_IP}  );
   my $mstack_cvr     = scalar( Dumper $href_cktvars->{+MSTACK_CVR} );
   my $timing_cases   = scalar( Dumper $href_cktvars->{+TIMING_CASES} );
   my $def_macros     = scalar( Dumper $href_cktvars->{+DEF} );
   my @ctl_macros     = split_ckt_var( $href_cktvars, CTL);
   my %ref_gds_macros;
   unless( $href_cktvars->{+REF_GDS} eq RETVAL_IF_NO_MATCH ){
      %ref_gds_macros = %{$href_cktvars->{+REF_GDS}};
   }
   my $pdvs_calib;
   my $pdvs_icv;
   my @mstack_ip = @{$href_cktvars->{+MSTACK_IP}};
   my @mstack_fdy = @{$href_cktvars->{+MSTACK_FDY}};
   if (defined $href_legalVerifs->{'calibre'} ){
       $pdvs_calib = scalar(Dumper $href_legalVerifs->{'calibre'});
   }else{ 
       $pdvs_calib = "[]";
   }
   if (defined $href_legalVerifs->{'icv'} ){
       $pdvs_icv = scalar(Dumper $href_legalVerifs->{'icv'});
   }else{ 
       $pdvs_icv = "[]";
   }

   my @p4_roots      = split(/\s+/,$href_cktvars->{+ROOT}) ;
   my @aref_cells    = @$aref_cells;
   $mstack_fdy       =~ s/\$VAR1 = |\n+|;//g;
   $mstack_ip        =~ s/\$VAR1 = |\n+|;//g; 
   $mstack_cvr       =~ s/\$VAR1 = |\n+|;//g;
   $timing_cases     =~ s/\$VAR1 = |\n+|;//g;
   $def_macros       =~ s/\$VAR1 = |\n+|;//g;
   $pdvs_calib       =~ s/\$VAR1 = |\n+|;//g;
   $pdvs_icv         =~ s/\$VAR1 = |\n+|;//g;

   $def_macros       =~ s/\s+/ /g;
   $mstack_ip        =~ s/\s+/ /g;
   $mstack_fdy       =~ s/\s+/ /g; 
   $mstack_cvr       =~ s/\s+/ /g;
   $timing_cases     =~ s/\s+/ /g;
   $pdvs_calib       =~ s/\s+/ /g;
   $pdvs_icv         =~ s/\s+/ /g;
   $def_macros       =~ s/(\S+\/)/'/g; 
   $timing_cases     =~ s/_nldm//g;
   
   my (@cfg_content, $phase);
   push(@cfg_content,"# Project $proj\n");
   my $prefix;
   $prefix = $1 if( $aref_cells[0] =~ /([^_]*_[^_]*)/ );
   my ($projNum) = ( $proj =~ /\S+\/([a-z][0-9]+)\-.*\// );

   my $product = (split /\//, $proj)[0];
   my ($cfgStart, $cfgEnd, $href_start, $sub_end) = static_config($ckt_mm, $projNum, $product, $prefix);
   push(@cfg_content, $cfgStart);

   my $relName   = "$projNum-$version";
   my $rel2Check = '    $globals{\'release_to_check\'} = \''."$relName".'\';';
   my $line      = '    $globals{\'bom__cell_names\'}  = [ qw( '. join(" ", @aref_cells) . ' ) ];';
   
   $phase = '    $globals{\'bom__phase_name\'}  = \'Final\';';
   if( defined $rel_phase ){
      if ($rel_phase =~ /pre/i and $rel_phase =~ /final/i){$rel_phase = 'Pre-Final'}
      elsif ($rel_phase =~ /prelim/ ){ $rel_phase = "Prelim"}
      else { $rel_phase = ucfirst ($rel_phase)}
      $phase = '    $globals{\'bom__phase_name\'}  = \''."$rel_phase".'\';';
   }

   my $ctl_refWaiv = '';
   my $mstack_waive = '';
   foreach my $stack ( @mstack_fdy ){
        if( grep{/^$stack$/} @mstack_ip ){ 
           $mstack_waive .= "
            
            #------ Waiver for metal stack simlinks --------------
            # In the case that the ip and foundary metal stack are the same we do not need a simlink from foundry to ip matal stack for netlist/gds/lef/timing
            #-----------------------------------------------------
            '\\/$stack\$',";
        } 
   } 
   my $ctl_comment1 = "#---------CTL View Waiver Jira P80001562-217438 ------------
            # Waive every ctl view except for macros that require a ctl view extracted from releaseCtlMacro in the legalRelease.txt:
            # Extracted: releaseCtlMacro{@ctl_macros}
            #-----------------------------------------------------------";
   my $ctl_comment2 = "#---------CTL View Waiver Jira P80001562-217438 ------------
            # Waive all ctl views as there was no macros defined in releaseCtlMacro{} in the legalRelease.txt file that require a ctl view";
   my $main_comments = "#---------main release specific waivers--------------------
            # Waive all utility cells, repeater cells, hspice and ibis views as they are released separetely
            #-----------------------------------------------------------";
   if ($ctl_macros[0] ne RETVAL_IF_NO_MATCH ){
      $ctl_refWaiv = "
            $ctl_comment1
            '\^\(\?!\.\*\(".join("\\/\|", @ctl_macros)."\\/\)\)\.\*ctl'";
   }else{
      $ctl_refWaiv = "
            $ctl_comment2
            '\\/.ctl'";
   }
   my $Waive_common ="
            $main_comments
            '\\/.*utility.*\\/',
            '\\/.*repeater.*\\/',
            '\\/hspice\\/',
            '\\/ibis\\/',
            '\\/HSPICE_',
            '\\/IBIS_',"; 
   my $hspice_comments = "#------------ Hspice waiver -------------------
            # waive all other views except hspice or HSPICE 
            #----------------------------------------------";
   my $ibis_comments = "#------------ IBIS waiver ------------------
            # waive all other views except ibis 
            #-------------------------------------------";
   
   if($release =~ /hspice/i ){
        $refWaiv = "
            $hspice_comments
            '^(?!.*(hspice|HSPICE)).*',";
        $relWaiv = "";
   }elsif( $release =~ /ibis/i ){
        $refWaiv = "
            $ibis_comments
            '^(?!.*(ibis|IBIS)).*',";
        $relWaiv = "";

   }elsif( $release =~ /main/i ){
        $refWaiv ="$Waive_common
            $ctl_refWaiv," ;
        $relWaiv =$Waive_common; 
   }else{
        $refWaiv ="$ctl_refWaiv,";
        $relWaiv ="";
   }
   $refWaiv .= $mstack_waive; 
   my $lib_comment ="#--------- lib/lib.gz waiver Jira P80001562-217094--------------
            # For new projects .lib.gz format is required however for old projects can still be .lib 
            # For now replacing both reference and released lib/lib.gz with lib.EXT only for DDR54 and LPDDR54 to accept both formats
            #---------------------------------------------------------------"; 
   if($proj =~ m/lpddr54/i or $proj =~ m/ddr54/i){
      #for lpddr54 and ddr54 accept both .zipped and non zipped libs Jira P80001562-217094 
      $libgz = "
            $lib_comment
            '\\.lib.*\$' => \".lib.EXT\",";
   }else{
      $libgz = '';
   }
   my $ver_common_comments = "#---------Version Replacement Jira P80001562-216933 ------------
            # replacing the release version in both reference and release as macros can be released with different versions
            #---------------------------------------------------------------";  
   my $Repl_common ="
            $ver_common_comments
            '\\/\\w.\\w+\\/macro\\/' => \"/VER/macro/\",
            'floorplans\\/\\w.\\w+\\/' => \"floorplans/VER/\",
            'HSPICE_model_app_note\\/\\w.\\w+\\/' => \"HSPICE_model_app_note/VER/\",  
            'IBIS_model_app_note\\/\\w.\\w+\\/' => \"IBIS_model_app_note/VER/\",
            $libgz";
 
      
   $refRepl = $Repl_common;
   my $ver_hl_comments = "#--------- HipreLynx Version Replacement -------------- 
            # The version in HipreLynx reports summary file is not standardized, replacing with variable VER to capture any version
            #------------------------------------------------------";
   $relRepl = "
            $ver_hl_comments
            '-\\w.\\w+.hiprelynx_sum' => \"-VER.hiprelynx_sum\",
            $Repl_common";

   if( $proj =~ m/hbm/i ){
        $refWaiv = "";
        $relWaiv = "";
        $refRepl = "";
        $relRepl = "";   
   }

   push(@cfg_content, $rel2Check);
   push(@cfg_content, $line);
   push(@cfg_content, $phase);
                                                #In cases where there are
                                                #extra dashes in projName 
   push(@cfg_content, misc_config($relName,(grep{($projName=~ s/-//gi)} @p4_roots)[0],$refWaiv, $relWaiv, $refRepl, $relRepl, $pvt_values, $m_fdy_name,$mstack_fdy, $m_ip_name, $mstack_ip, $m_cvr_name, $mstack_cvr,$timing_cases_name,$timing_cases, $def_macro_name, $def_macros, $pdvs_calib, $pdvs_icv));
   push(@cfg_content, $href_start);
   my $short_cell = '';
   my $orient = '';
   my $ref_gds = '';
   foreach my $key ( keys %$href_components ){
      foreach my $component ( sort @{$href_components->{$key}} ){
         #For IBIS and HSPICE views short_cell and orient local varibales will be added to every macro in the config file to account for the specifc naming conventions Jira P80001562-216939
         if( grep{/^$component$/} keys %hspice_ibis_full_list ){
             $short_cell = "\'short_cell\' => \'$hspice_ibis_full_list{$component}{short_cell}\',";  
             $orient     = "\'orient\'     => \'$hspice_ibis_full_list{$component}{orient}\',";
         }else{
             $short_cell = '';
             $orient  = '';
         }
         if( grep{/^$component$/} keys %ref_gds_macros ){ #if the cell is one that requires a reference gds as stated in legalRelease.txt Jira P80001562-226758
             $ref_gds = "#----- extracted reference gds for ($component) => {$ref_gds_macros{$component}} from legalRelease.txt file Jira P80001562-226758 ----
               \'ref_gds\'     => \[qw($ref_gds_macros{$component})\],"; #add the list of needed gds to the macro
        }else{
             $ref_gds = "\'ref_gds\'     => \[\],";;
        }
     my $cfg = <<EOF;
         '$component'  => {
            'overrides'   => { 
               'version'     => '$version',
               $ref_gds
               $short_cell
               $orient

            },
         },
EOF
         if( $key !~ /DEFAULT/i ){
            my $ref_proj   = (split(/\//, $key))[1];
            my $local_root = ( grep{/$ref_proj/} @p4_roots )[0];
            if( !defined($local_root) ){ 
               wprint( "Topcells has cells from reference projects but p4 root not found in legalRelease.txt!"); 
               wprint( "Using default p4 root");
            }else{
               $local_root = "//depot/$local_root/ckt/rel";
               dprint(MEDIUM, "Found p4_root for $ref_proj\n");
               dprint(MEDIUM, "Using $local_root as base_path override for $component\n");
               my $ref_version = get_ref_version($key); ## Get rel variable from reference project instead of using default
               if($ref_version eq RETVAL_IF_NO_MATCH ){
                  wprint( "rel version not found for reference project '$key'. Using default rel version '$version'\n" );
                  $ref_version = $version; 
               }
               $cfg = <<EOF;
         '$component'  => {
            'overrides'   => { 
               'base_path'   => '$local_root',
               'version'     => '$ref_version',
               $ref_gds
               $short_cell
               $orient

            },
         },
EOF
            }
         }
         dprint(SUPER, "$cfg\n" );
         push(@cfg_content, $cfg);
      }
   }
   push(@cfg_content, $sub_end);
   push(@cfg_content, $cfgEnd);
   return( @cfg_content );
}


#------------------------------------------------------------------------------
sub process_cmd_line_args(){
   my ( %opts, $config, $opt_debug, $optHelp, $opt_verbosity, $opt_testmode );
    GetOptions( 
          "proj=s"     => \$opts{proj},       # project path in p4
          "p4legal=s"  => \$opts{+P4LGL},     # config files for check
          "p4top=s"    => \$opts{+P4TOP},     # config files for check
          "p4top=s"    => \$opts{+P4LV},      # legal Verifs for icv and calibre reports Jira P80001562-226745
          "debug=i"    => \$opt_debug,        # debug level
          "phase=s"    => \$opts{phase},      # release phase
          "output=s"   => \$opts{output},     # output to specific path
          "manifest=s" => \$opts{manifest},   # Manifest path/name
          "release=s"  => \$opts{release},    # Main/Utility/IBIS/HSPICE/Repeater/TC - only for buildmacro script
          "nousage"    => \$opts{nousage},    # Set this to bypass the utils__script_usage_statistcs call
          "verbosity=i"=> \$opts{verbosity},  # verbosity level
          "testmode"   => \$opts{testmode},   # enable testmode
          "help"       => \$optHelp,          # Prints help
    );

   # decide whether to alter DEBUG variable
   # '--debug' indicates DEBUG value ... set based on user input
   if( defined $opt_debug && $opt_debug =~ m/^\d+$/ ){  
      $main::DEBUG = $opt_debug;
   } else{
       $opt_debug = 0;
   }

   if( defined $opt_verbosity && $opt_verbosity =~ m/^\d+$/ ){  
      $main::VERBOSITY = $opt_verbosity;
   }
   if( defined $opt_testmode ){
      $main::TESTMODE = $opt_testmode;
   }
   if( defined $optHelp || !defined $opts{proj} ){
      my $proj_opt = defined $opts{proj} ? $opts{proj} : 'undefined';
      my $msg  = "$PROGRAM_NAME -d $opt_debug -proj $proj_opt \n\n";
      wprint( $msg );
      $msg = "USAGE:  $PROGRAM_NAME -proj <p4path> \n";
      $msg .= "optional args : -debug     # \n";
      $msg .= "              : -verbosity # \n";
      $msg .= "              : -testmode    \n";
      $msg .= "              : -release  <> \n";
      $msg .= "              : -manifest <> \n";
      $msg .= "              : -phase    <> (typical vals: initial, Prelim, Pre-Final, Final)\n";
      $msg .= "              : -help        \n";
      $msg .= "Example: \t\t$PROGRAM_NAME -proj ddr54/d810-ddr54-tsmc5ffp12/rel1.00 -rel Prelim -d 2 \n";
      eprint( $msg );
      my $return_status = defined $optHelp ? 0 : ($proj_opt eq 'undefined') ? 1 : 0;
      exit($return_status);
   }else{
      #-------------------------------------------------------------------------------
      # P4BASE         => //wwcad/msip/projects/
      # Example arg supplied at cmd line:
      #           -proj ddr54/d810-ddr54-tsmc5ffp12/rel1.00/
      #-------------------------------------------------------------------------------
      my $remote_path = P4BASE . $opts{proj} . P4PCS; 
      $opts{+P4LGL} = firstAvailableFile($remote_path.'/design/legalRelease.txt',$remote_path.'/design_unrestricted/legalRelease.txt'); 
      $opts{+P4TOP} = firstAvailableFile($remote_path.'/design/topcells.txt',$remote_path.'/design_unrestricted/topcells.txt');
      $opts{+P4LV}  = firstAvailableFile($remote_path.'/design/legalVerifs.txt',$remote_path.'/design_unrestricted/legalVerifs.txt'); #Jira P80001562-226745
      $opts{+P4LGL} =~ s|(\S)//|$1/|g; # strip out any of the double forward slashes add by user's input
      $opts{+P4TOP} =~ s|(\S)//|$1/|g; # strip out any of the double forward slashes add by user's input
   }
   return( %opts );
};

#------------------------------------------------------------------------------
sub get_pvt_values() {
   print_function_header();
   my $fname = shift;

   my $pvtCorners;
   my @corners = ();
   my %corners_params;
   if ($fname =~ /alphaNT/i){ 

      my @fileContent = read_file( $fname );
      if( @fileContent ){
         $pvtCorners = ( grep{/^set\s+pvtCorners/i} @fileContent )[0];
         chomp($pvtCorners);
         $pvtCorners =~ s/.*pvtCorners\s+\{(.*)\}/\[\'$1\'\]/ig;
         $pvtCorners =~ s/\s+/\'\,\'/ig;
         $pvtCorners = RETVAL_IF_NO_MATCH if( $pvtCorners eq "" );
      }else{
         eprint( "Unable to read alphNT config file:  '$fname'\n" );
         $pvtCorners = RETVAL_IF_NO_MATCH;
      }
      if( $pvtCorners eq RETVAL_IF_NO_MATCH ){
         wprint( "PVT values were NOT extracted from alphaNT config file, so BOM creation may be impacted.\n" );
      }
   }else{
      my $relCornersHeaderBase = "Corner Type\tCase\tCore Voltage (V)\tPLL Voltage (V)\tIO Voltage (V)\tTemperature (C)\tExtraction Corner";
      @corners = process_corners_file($relCornersHeaderBase, $fname, 
          \%corners_params );
      $pvtCorners = "['".join("','", @corners)."']";

   }
   return( $pvtCorners );
}

sub split_ckt_var($$){
    my $href_ckt_variables = shift;
    my $ckt_key            = shift;  # REPEATER, TESTCHIP, etc...

    if ( exists $href_ckt_variables->{$ckt_key} ){
        my @array_out = split(/\s+/, $href_ckt_variables->{$ckt_key});
        return @array_out;
    }

    wprint("Missing '$ckt_key' from ckt_variables\n");
    return ();

}

#------------------------------------------------------------------------------
sub static_config() {
   print_function_header();
    my $MM_XLSX = shift;
    my $proj = shift;
    my $product = shift;
    my $prefix = shift || NULL_VAL;
    my $configStart = "
#------------------------------------------------------------------------------
# CMD to dump the rel content from P4
#------------------------------------------------------------------------------
# BOM OWNER RELATED
#------------------------------------------------------------------------------
   \$globals{'fname_MM_XLSX'}           = \"$MM_XLSX\";
   \$globals{'fname_BOM_TXT'}           = \"MM.filenames.txt\";
   \$globals{'fname_optional_BOM_TXT'}  = \"MM.filenames.optional.txt\";
   \$globals{'XLSX_sheet_name'}         = \"MM\";
   \$globals{'manifest__name'}          = 'p4';

   #------------------------------------------------------------------------------
   #  Setup a dictionary that defines the LEXICON allowed for file SPECs 
   #      There's two scopes ... global => applies uniformly across all components
   #                         ... local  => applies in context of single component
   #------------------------------------------------------------------------------
   \$globals{'global_dictionary'} = {
        'allowed_literals' =>  [ qw( phyPrefix uniqPrefix process cktrel product proj ) ],
        'allowed_lists'    =>  [ qw( pdvs_calib pdvs_icv mstack_ip mstack_fdy mstack_cvr timing_cases pvt_values def_macros ) ],
        };
   \$globals{'local_dictionary'} = {
        'allowed_literals' =>  [ qw( cell_name version suffix short_cell orient ) ],
        'allowed_lists'    =>  [ qw( pvt_combos pvt_corners ref_gds) ],
        };
   \$globals{'file_SPEC_variables'} = {
   	'proj' => '$proj',
	'product' => '$product',
	'phyPrefix' => '$prefix',

   	};

#------------------------------------------------------------------------------
# The following parameters are setting that control parsing of the MM itself.
#     The general concept of what's needed is information that defines 
#     where to look for critical pieces of information.
#
#     CSV_index_REL  => defines the column # to use for the release phase
#          Example : user wants to check a 'Pre-Final' release defined
#               by column 30
#     CSV_index_FILES  => the col number where the file specs are defined
#     CSV_index_VIEWS  => the col number where the view names are defined
#     CSV_index_COND   => the col number where conditionals are defined
#------------------------------------------------------------------------------
   \$globals{'CSV_index_FILES'}   =  6;   # used in MM-2-bc.pl  # col number -  file names
   \$globals{'CSV_index_VIEWS'}   =  5;   # used in MM-2-bc.pl  # col number -  view names
   \$globals{'CSV_index_REL'}     =  3;   # used in MM-2-bc.pl  # col number -  phase/release to use
   \$globals{'CSV_index_COND'}    =  4;   # used in MM-2-bc.pl  # col number -  \"condition\" (in row with cell names)

   # enter row # where we expect the \"manifest_name\" labels 
   \$globals{'row__manifest_names'}= '7';   # used in MM-2-bc-.pl # row number -  row with manifest names (i.e. BOM, d714, d812, etc)
   \$globals{'row__bom_start'}    = '10';   # used in MM-2-bc.pl  # row number -  1st row of the bom details
   \$globals{'row__cell_names'}   =  '8';   # used in MM-2-bc.pl  # row number -  row where cell names listed


#------------------------------------------------------------------------------
# USER BASED CONFIG
#------------------------------------------------------------------------------\n\n";

    my $configEnd = "\n\n";

    my $hrefStart = "      my \$href_cells =  \{\n";
    my $subEnd    = "      } ;  # END href_cells

      return( \$href_cells, \$misc );
   };  # END sub\n\n";

    return ($configStart, $configEnd, $hrefStart, $subEnd);
    
}
    

#-------------------------------------------------------------------------------
sub misc_config () {
   print_function_header();
   my $rel2check         = shift;
   my $p4Root            = shift;
   my $refWaiv           = shift;
   my $relWaiv           = shift;
   my $refRepl           = shift;
   my $relRepl           = shift;
   my $pvt_values        = shift;
   my $m_fdy_name        = shift;
   my $mstack_fdy        = shift;
   my $m_ip_name         = shift;
   my $mstack_ip         = shift;
   my $m_cvr_name        = shift;
   my $mstack_cvr        = shift;
   my $timing_cases_name = shift;
   my $timing_cases      = shift;
   my $def_macro_name    = shift;
   my $def_macros        = shift;
   my $pdvs_calib        = shift;
   my $pdvs_icv          = shift;

    
   $p4Root =~ s/(\S+)\s+(\S+)/$1/;
   my $base_path  = "//depot/$p4Root/ckt/rel/";
   my $miscConfig = "   #------------------------------------------------------------------------------
   # $rel2check
   # Globally define the project variable configurations Jira P80001562-206618
   #------------------------------------------------------------------------------
   \$globals{'$rel2check'} =  sub {
      my \$misc = {
	       'vars_that_get_inherited_by_cells'   => [ 'vici_url', 'mstack_regex', 'PVT_regex', 'pdvs_calib', 'pdvs_icv', 'mstack_ip', 'mstack_fdy', 'mstack_cvr', 'timing_cases', 'pvt_values', 'def_macros' ],
	       'base_path'   => '$base_path',
               'pdvs_calib'  => $pdvs_calib,
               'pdvs_icv'    => $pdvs_icv, 
               '$def_macro_name'  => $def_macros, 
               'pvt_values'  => $pvt_values,
               '$m_fdy_name' => $mstack_fdy,
               '$m_ip_name'  => $mstack_ip,
               '$m_cvr_name' => $mstack_cvr,
               '$timing_cases_name' => $timing_cases,
         #------------------------------------------------------------------------------
         # User can specify REGEX to use that will waiver (filter out) files from
         #   the lists being compared. User can also search for a REGEX and replace it
         #   with a value as well, which was found useful for comparing two releases.
         #------------------------------------------------------------------------------
         'inspector__REF_waivers' => [ 
            $refWaiv
         ],
         'inspector__REL_waivers' => [ 
            $relWaiv
         ],
         'inspector__REF_find_n_replace' => { 
            $refRepl
         },
         'inspector__REL_find_n_replace' => { 
            $relRepl         
         },
      };  # END MISC\n\n";
   return( $miscConfig );
}

## Bhuvan : added this to get rel version from legalRelease.txt file
##   when it's not the default version specified in original legalRelease
sub get_ref_version ($) {
   print_function_header();
    my $proj = shift;
    my $legalPath = P4BASE . $proj . '/design/legalRelease.txt';
    my @content = read_file( $legalPath );
    my $rel_ver = ( grep{/set\s+rel\s+/ && !/\#/} @content )[0];
    $rel_ver =~ s/.*\"(.*)\"/$1/g;
    if( $rel_ver eq "" ){ $rel_ver = RETVAL_IF_NO_MATCH; }
    chomp($rel_ver);
    return($rel_ver);
}

#----- gen_hspice_ibis_hash subroutine will return a hash table which stores the short_cell and orientation for every macro that exists in topcell.txt----
sub gen_hspice_ibis_hash ($$){
   print_function_header();
   my $hspice_ibis_hash = shift;
   my $macros = shift;

   my %hspice_ibis_hash = %$hspice_ibis_hash;
   my @macros = @$macros;
   my %hspice_ibis_hash_expanded;
   my @orient = ('', '_ew', '_ns');
   foreach my $macro (keys %$hspice_ibis_hash){
      foreach my $orientation (@orient){
         my $mac = $macro.$orientation;
         if( grep {/^$mac$/} @macros ){
            $hspice_ibis_hash_expanded{$mac}{short_cell} = $hspice_ibis_hash{$macro};
            $hspice_ibis_hash_expanded{$mac}{orient} = $orientation;
         }
      }
   } 
   return %hspice_ibis_hash_expanded;
}

