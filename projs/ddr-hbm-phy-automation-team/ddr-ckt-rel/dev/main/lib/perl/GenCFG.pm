package GenCFG;

use strict;
use warnings;
use Carp;
use Cwd 'abs_path';
use File::Basename;
use lib dirname(abs_path $0);
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Data::Dumper;
$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };

use Exporter qw( import );
our @EXPORT_OK = qw(
   map_legal_verifs
   extract_list_of_macros
   create_log_of_bad_lines
   slurp_p4_file_content
   get_manifest_file
   parse_legalRelease_hash 
);


#----------------------------------#
my $RETVAL_IF_NO_MATCH = 'N/A';
#----------------------------------#

#-------------------------------------------------------------------------------
# See test content in TEST scripts area for more details.
# Sample of the Contents found in 
# 
#       ##  topcells file created from /remote/cad-rep/projects/ddr54/d809-ddr54-tsmc7ff18/rel1.00_cktpcs/design/legalMacros.txt
#       ##  topcells file created from /remote/cad-rep/projects/ddr54/d809-ddr54-tsmc7ff18/rel1.00_cktpcs/design_unrestricted/legalMacros.txt
#       [LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdq_ew/layout
#       [SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdq_ew/schematic
#       [LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdqs_ew/layout
#       [SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdqs_ew/schematic
#       [SCH]dwc_ddrphycover_hdmim/dwc_ddrphycover_dwc_ddrphydbyte_decapvddq_adjcoil_ew/schematic
#       [SCH]dwc_ddrphycover_hdmim/dwc_ddrphycover_dwc_ddrphydbyte_decapvddq_adjcoil_ew/layout
#       ...
#    
#-------------------------------------------------------------------------------
sub extract_list_of_macros($$$$) {
   my $stdout     = shift;
   my $regex_mac  = shift;
   my $regex_proj = shift;
   my $regex_refs = shift;
   
   my %href_mac;
   my %href_proj;
   my @uniq_macro_names;

   my @lines = (split(/\n/, $stdout));
   my @bad_lines;
   my @list;
   foreach my $line ( @lines ){
      next if( $line =~ m/^#/ );
      chomp($line);
      dprint(HIGH, "Line = $line\n");
      if( $line =~ $regex_proj ) {      
         my ($refNum, $projName) = ($line =~ $regex_proj);    
         $href_proj{$refNum} = $projName;
      }elsif( $line =~ $regex_mac ){
         my ($mac) = ($line =~ $regex_mac);
         dprint(HIGH, "Adding '$mac' to list ...\n" );
         #addded $ at the end of $mac$ as some topcells were matching cells with extensions and omitted 
         push( @{$href_mac{DEFAULT}}, $mac) if( !grep{/$mac$/} @{$href_mac{DEFAULT}} );   
      }elsif( $line =~ $regex_refs ){
         my ($refNum, $mac) = ($line =~ $regex_refs);  
         my $tKey = $href_proj{$refNum};    
         push(@{$href_mac{$tKey}}, $mac) if( !grep{/$mac/} @{$href_mac{$tKey}} );         
      }else{
         dprint(HIGH, "Bad line ... skipping.\n" );
         push( @bad_lines, $line );
      }
      #dprint(CRAZY, "\@list = " . join( ",", @list) . "\n" );
   }

   dprint(MEDIUM,"Macro Name list extracted from topcells.txt: \n" . scalar(Dumper \%href_mac) . "\n");
   return( \@bad_lines, %href_mac );
}

#-------------------------------------------------------
# bad lines contains the lines in the topcells.txt where regex used to find 
#    macros failed. since each failure may translate into a new use case
#    I save them as samples for improving the algo at a later time.
#-------------------------------------------------------
sub create_log_of_bad_lines($$$){
   my $fname = shift;
   my $cmd   = shift;
   my $aref_bad_lines = shift;

   open(my $fh, '>>', $fname ) || confess "Couldn't open file '$fname'\n"; #nolint
   foreach my $line ( @$aref_bad_lines ){
      my ($day,$month,$date,$time,$year) = get_the_date();
      my $msg = "$month/$date/$year $time : $cmd : $line\n";
      print $fh $msg;
      vwprint(LOW, $msg );
   }
   close( $fh );

   return();
}

# P10020416-38799 create parse_legalRelease_hash
#
# Arguments:
#   (1) reference to hash obtained via processLegalReleaseFile()
#   (2) the keys in legalRelease that we want to gather
#   (3) reference to a hash to translate the keys in legalRelease to
#       the key that ckt_variables returns. This is so we don't have to
#       make as many code modifications.
#
sub parse_legalRelease_hash ($$$){
    print_function_header();
    my $href_legalRelease = shift;
    my $href_wanted       = shift;  # ( ckt_name, legalrelease_name, ...)
    my $href_translated   = shift;  # ( legalrelease_name,  ckt_keys, ...)

    dprint_dumper(LOW, "href_legalRelease:", $href_legalRelease);
    dprint_dumper(LOW, "href_wanted", $href_wanted);
    dprint_dumper(LOW, "href_translated", $href_translated);

    my %ckt_variables;
    my %returns_array = ( 
        'mstack_ip' =>1,  
        'mstack_fdy'=>1,
        'mstack_cvr'=>1,
        'def_macros'=>1 
    );
    foreach my $wanted_cktkey ( keys %$href_wanted ){
        my $lrkey = $href_wanted->{$wanted_cktkey}; # legalRelease keys
        if ( exists $href_legalRelease->{$lrkey} ){
            my $lrvalue = $href_legalRelease->{$lrkey};
            # So, we expect array refs returned for some keys
            if ( exists $returns_array{$wanted_cktkey} ) {
                $ckt_variables{$wanted_cktkey} = [split( /\s/, $lrvalue)];
            }
            else {
                $ckt_variables{$wanted_cktkey} = $lrvalue;
            }
        }else{
            wprint("Unable to locate '$wanted_cktkey:$lrkey' from the legalRelease file\n");
            $ckt_variables{$wanted_cktkey} = NULL_VAL;
        }
    }

    dprint_dumper(MEDIUM, "Variables extracted from legalRelease:",
        \%ckt_variables);

    print_function_footer();
    return(%ckt_variables);
}

#-------------------------------------------------------------------------------
#  Sometimes, the file contents are simply a pointer to another file that
#     contains the actual content that needs to be parsed and extracted.
#     This procedure deals with slurping the content from the right location.
#     If the p4 file pointer is not valid, abort.
#-------------------------------------------------------------------------------
sub slurp_p4_file_content($$){
   print_function_header();
   my $cmd   = shift;
   my $fname = shift;

   my $ABORT = FALSE;
	 my ($stdout, $retval) = run_system_cmd( $cmd, $main::DEBUG );

   if( $retval || $stdout =~ m/no such file/ ){
      eprint( "Error in return val from p4 cmd :\n\t$cmd\n" );
      $ABORT = TRUE;
   }else{
      dprint(HIGH, "--STDOUT-- $stdout\n" );
      #if( $stdout =~ m|.*/legalRelease.txt| ){
      if( $stdout =~ m|\n((?:/\S+)+$fname)$| ){
         # Push one level in and open the file. Won't do recursion until
         # we have a need for it.
         my $msg = "Found a file path in the $fname: '$1' !\n";
         wprint( $msg );
         my $cmd = "cat $1";
	       ($stdout, $retval) = run_system_cmd( $cmd, $main::DEBUG );
         dprint(HIGH, "--STDOUT-- $stdout\n" );
         if( $retval || $stdout =~ m/no such file/ ){
            eprint( "Error in return val from p4 cmd :\n\t$cmd\n" );
            $ABORT = TRUE;
         }
      }else{
         my $msg = "Parsing contents of the '$fname' file!\n";
         wprint( $msg );
      }
   }
   if( $ABORT == TRUE ){ fatal_error( "Fix errors reported above before continuing.\n" ); }
   return( $stdout );
}

#----------------------------------------------------------
# Generate the appropriate name of the manfist file,
#    which is effectively hard-codeded.
#----------------------------------------------------------
sub get_manifest_file($$){
   my $opt_proj     = shift;
   my $opt_manifest = shift;

   my $fname_ckt_mm = "";

   if( defined($opt_manifest) ){
      $fname_ckt_mm = $opt_manifest;
   }elsif( $opt_proj =~ m/lpddr54/i ){
      $fname_ckt_mm = "CKT--lp54-bom-in-p4.xlsx";
   }elsif( $opt_proj =~ m/ddr54/i ){
      $fname_ckt_mm = "CKT--ddr54-bom-in-p4.xlsx";
   }elsif( $opt_proj =~ m/hbm/i ){
      $fname_ckt_mm = "CKT--hbm-bom-in-p4.xlsx";
   }else{
      eprint( "Main manifest not available for '$opt_proj'. Use cmd line opt -manifest to define MM\n" );
   }

   return( $fname_ckt_mm );
}
#---- extract pvts from legalVcCorners.csv Jira P80001562-217093
sub gencfg_process_corners_file($$){
   print_function_header();
   my $fname_relCornersFile   = shift;
   my $href_corners_vc_params = shift;
   my $relCornersHeaderBase = "Corner Type\tCase\tCore Voltage (V)\tPLL Voltage (V)\tIO Voltage (V)\tTemperature (C)\tExtraction Corner";
   ## open release corners files
   open(*CFH, $fname_relCornersFile) ||
         confess "I/O ERROR: Failed to open corners file '$fname_relCornersFile': '$!'\n";
   iprint( "Reading release corners file: '$fname_relCornersFile'\n" );
   ## grab header and check it is expected
   my $relCornersHeader = <CFH>;
   chomp( $relCornersHeader );
   $relCornersHeader =~ s/\#.*//;
   ## if first header is comment or empty, grab next line
   while( $relCornersHeader =~ /^\s*$/ ){
      $relCornersHeader = <CFH>;
      chomp( $relCornersHeader );
      $relCornersHeader =~ s/\#.*//;
   }
   
   ## now that comment and empty lines are gone, should have the real header
   if( $relCornersHeader ne $relCornersHeaderBase ){
      fatal_error( "Release corners file header is not as expected ".
              "(exactly 7 fields with tab delimiting).\n".
              "  Found: $relCornersHeader\n".
              "  Expected: $relCornersHeaderBase\n" );
   }

   my @corners_vc;
   ## loop through release corners
   while( <CFH> ){
      ## grab and split fields
      my @fields = split '\t';
      ## validate the number of fields of each line
      if( $#fields != 6 ){
         fatal_error( "'$fname_relCornersFile' VC release corners file".
                 " must have 7 fields and has ".($#fields+1).".\n$_\n" );
      }
      ## store fields
      my $procs_field = lc($fields[1]);
      my $vdds_field  = $fields[2];
      my $vaa         = $fields[3];
      my $vddq        = $fields[4];
      my $temps_field = $fields[5];
      my $rcxts_field = $fields[6];  # not used outside this subroutine (legacy?)
      ## check for empty fields
      my $common = "'$fname_relCornersFile' VC release corners file must have non-empty";
      if( $procs_field eq '' ){ fatal_error( $common ." Case field.\n$_\n"        ); }
      if( $vdds_field  eq '' ){ fatal_error( $common ." Voltage field.\n$_\n"     ); }
      if( $vaa         eq '' ){ fatal_error( $common ." PLL Voltage field.\n$_\n" ); }
      if( $vddq        eq '' ){ fatal_error( $common ." IO Voltage field.\n$_\n"  ); }
      if( $temps_field eq '' ){ fatal_error( $common ." Temperature field.\n$_\n" ); }
      if( $rcxts_field eq '' ){ fatal_error( $common ." Extractions field.\n$_\n" ); }
      ## split fields into units and prep special characters
      $procs_field =~ s/[\s\/\,]+/,/g;
      $vdds_field  =~ s/[\s\/\,]+/,/g;
      $temps_field =~ s/[\s\/\,]+/,/g;
      $rcxts_field =~ s/[\s\/\,]+/,/g;
      my @procs = split ',',$procs_field;
      my @vdds  = split ',',$vdds_field;
      my @temps = split ',',$temps_field;
      my @rcxts = split ',',$rcxts_field;
      $vddq  =~ s/\s*([\d\.]+)v?\s*\(?.*\)?\s*$/$1/i;
      $vaa   =~ s/\s*([\d\.]+)v?\s*\(?.*\)?\s*$/$1/i;
      #---------------------------------------------
      ## generate corners for each line
      foreach my $proc ( @procs ){
         foreach my $vdd ( @vdds ){
            foreach my $temp ( @temps ){
               ## validate voltages
               my $suffix = "voltage is expected to be #.# only.\n$_ \n";
               if( !($vdd  =~ /^\d+\.\d+$/) ){ fatal_error( $common ." '$vdd' core $suffix" ); }
               if( !($vddq =~ /^\d+\.\d+$/) ){ fatal_error( $common ." '$vddq' IO $suffix"  ); }
               if( !($vaa  =~ /^\d+\.\d+$/) ){ fatal_error( $common ." '$vaa' PLL $suffix"  ); }
               if( !($temp =~ /^\-?\d+$/  ) ){ fatal_error( $common ." '$temp' temperature is expected to be # only.\n$_ \n"   ); }
               ## create text strings
               my $vdd_txt = $vdd;
               $vdd_txt  =~ s/(\.\d+)0+$/$1/;
               $vdd_txt  =~ s/\./p/;
               my $temp_txt = $temp;
               $temp_txt =~ s/\-/n/;
               $temp_txt =~ s/\.0+$//;
               $temp_txt =~ s/(\.\d+)0+$/$1/;
               $temp_txt =~ s/\./p/;
               #$corner = "${proc}${vdd_txt}v${temp_txt}c_${rcxt}";
               my $corner = "${proc}${vdd_txt}v${temp_txt}c";
               ## store corner info
               $href_corners_vc_params->{$corner}{'temp'} = $temp;
               $href_corners_vc_params->{$corner}{'VSS'}  = 0;
               $href_corners_vc_params->{$corner}{'VDD'}  = $vdd;
               $href_corners_vc_params->{$corner}{'VDDQ'} = $vddq;
               $href_corners_vc_params->{$corner}{'VAA'}  = $vaa;
               push @corners_vc, $corner;
            } # end 'for temp'
         } # end 'for vdds'
      } # end 'for procs'
   } ## end  while(<CFH>)
   ## close release corners
   close(CFH);

   return( @corners_vc );
}

#+
# map_legal_verifs
#
# Description:
#   Will look in legalRelease hash table and fill in the
#   ckt_variables that are required. These would be things
#   that used to be in the legalVerif text file.
#
# Arguments:
#   href_legalRelease:
#       A pre-populated hash table of legalRelease data.
#
#   href_xlate:
#       To translate the names contained in the legalRelease hash
#       to what is expected by the calling routine. The caller for
#       example would be gen_ckt_cell_cfgs.pl
#
# Returns:
#    legalVerifs:
#       Hash-table containing just what is needed by legalVerifs original
#       code as read by gen_ckt_cell_cfgs.pl 
#-
sub map_legal_verifs($){
    my $href_legalRelease = shift;
    my $href_xlate        = shift;

    # now gather up the legal verif info from the legalRelease info
    my %legalVerifs;

    my @props = ( "calibre", "icv" );
    my $lr_prop;  # the key name in legalRelease hashtable
    my $lv_prop;  # the key name used in legalVerifs hash table
    foreach my $prop ( @props ){
        if ( $prop eq "calibre" ){
            $lr_prop = "calibre_report_list";
            $lv_prop = "calibre";
        }elsif( $prop eq "icv" ){
            $lr_prop = "icv_report_list";
            $lv_prop = "icv";
        }else{
            my $package = __PACKAGE__;
            my $line    = __LINE__;
            wprint("'$prop' is not handled in the $package code line $line.\n");
            next; # go on to the next prop_name we need to handle
        }

        if ( exists $href_legalRelease->{"$lr_prop"} ){
            my $lr_value = $href_legalRelease->{"$lr_prop"};
            $legalVerifs{"$lv_prop"} = $lr_value; 
        }else{
            wprint("Did not find legalVerif name '$lr_prop' in the legalRelease file\n");
        }
    }

    return(%legalVerifs);
}

1;
