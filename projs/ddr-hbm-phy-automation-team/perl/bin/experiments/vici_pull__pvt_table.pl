#!/depot/perl-5.14.2/bin/perl

#-------------------------------------------------------------------------------
# Author : Patrick Juliano
# Date   : Mar 2020
# Copyright : Synopsys Corp
#
# Primary purpose of this script is query ViCi to obtain the  
#   the information necessary to generate a BOM file list.
#   This includes the following:
#       component {names, orientations, versions, metal stack, PVTs}
#
# As of today, the MSIP script used to grab information from ViCi doesn't
#       include in the XML file the following, so the same is true of this script:
#           'version' , 'orientation' , 'metal stack'
#
# Cmd Line Example: 
#    vici_pull__pvt_table.pl -product hbm2 -project d714-hbm2e-tsmc7ff18 \
#                            -vcrel 1.00a_intcEW -rel 1.00a_EWHardened -d 1
#-------------------------------------------------------------------------------

use strict;
use Devel::StackTrace;
use Data::Dumper;
use File::Copy;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use XML::Simple qw(:strict);
use Getopt::Long;

use lib dirname(abs_path $0) . '/../../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

our $DIRNAME = dirname(abs_path $0);
our $PROGRAM_NAME = $0; 
our $AUTHOR_NAME  = 'Patrick Juliano'; 

#----------------------------------#
our $DEBUG = NONE;
#----------------------------------#

BEGIN { header(); } 
   Main();
END { footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
   print_function_header();

   unless( defined $ENV{REPO_PATH} ){
      # set a dummy val, cause MSIP scripts used below barf otherwise
      $ENV{REPO_PATH}="/dev/null";
   }
   my ( $product, $vcrel ) = process_cmd_line_arg();
   ## Cmd to generate an example file:
   #  msip_viciGenerateProjSummaryAdvancedXml.pl -p d714-hbm2e-tsmc7ff18 -r 1.00a_EWHardened --out d714-hbm2e-tsmc7ff18__1.00a_EWHardened.xml
   #my $xml_fname = 'd714-hbm2e-tsmc7ff18__1.00a_EWHardened.xml';
   #my @vici_dump = `cat d714-hbm2e-tsmc7ff18__1.00a_EWHardened.xml`;
    
   my $xml_fname = "${product}_summary.xml";
   my @vici_dump   = grab_vici_summary__write_xml(  $xml_fname, $product, $vcrel );
   my  @components         = parse_vici_xml_for_component_names     ( $xml_fname, $product, $vcrel );
   my @pvt_in_vici         = parse_vici_xml_for_pvt                 ( $xml_fname, $product, $vcrel );
   my ($foundry_metal_opt) = parse_vici_xml_for_foundry_metal_option( $xml_fname, $product, $vcrel );
   my ($phy_metal_opt)     = parse_vici_xml_for_PHY_metal_option    ( $xml_fname, $product, $vcrel );

   dprint( HIGH, "\@components  = " . scalar(Dumper \@components)  . "\n" );
   dprint( HIGH, "\@pvt_in_vici = " . scalar(Dumper \@pvt_in_vici) . "\n" );
   dprint( HIGH, "\$foundry_metal_opt = $foundry_metal_opt \n" );
   dprint( HIGH, "\$phy_metal_opt = $phy_metal_opt \n" );
   

   print "components = [ " . join(" ", sort @components) . " ]\n";
   print "Metal Options[ Foundry,PHY ] = [ $foundry_metal_opt, $phy_metal_opt ]\n";
   print "+-------------" x10 . "\n";
   print $pvt_in_vici[0];
   print "+-------------" x10 . "\n";
   print @pvt_in_vici[1..$#pvt_in_vici];
   print "+-------------" x10 . "\n";
   exit(0);
}

############    END Main    ####################
#
#

#------------------------------------------------------------------------------#
# Searched thru array ref of scalars & arrays to find those components that
#     are unique. Assumes no HASH present.
#------------------------------------------------------------------------------#
sub find_aref_in_data_structure($){
   print_function_header();
   my $aref_components = shift;

   my @elements;
   foreach my $elem ( @$aref_components ){
      if( ref($elem) eq "ARRAY" ){
         dprint( HIGH, get_subroutine_name() . ": Found ARRAY ... recurse.\n" );
         push( @elements, find_aref_in_data_structure( $elem ) );
      }elsif( ref($elem) eq "" ){
         dprint( HIGH, get_subroutine_name() . ": Found SCALAR ...: '$elem'\n" );
         push( @elements, $elem );
      }
   }
   return( @elements );
}

#------------------------------------------------------------------------------#
#  Traverse thru the XML data structure (consisting of hash/array combinations.
#     and find the [name,value] pair. Once found, return the value field ...
#------------------------------------------------------------------------------#
sub find_in_xml {
   ##  Find a hash element with name (_Name) equal to that name provided.
   my $obj       = shift;
   my $nameField = shift;
   my $name      = shift;
   my $valField  = shift;

   my @matches;

   my $ref = ref $obj;
   if( $ref eq "ARRAY" ){
	    foreach my $subObj ( @$obj ){
	       my $x = find_in_xml($subObj, $nameField, $name, $valField);
	       #orig if ($x) {return $x}
	       if( $x ){ push(@matches, $x); }
	    }
	    if( scalar(@matches) > 0 ){
         return( \@matches )
      }else{
	       return 0;
      }
   }

   if( $ref eq "HASH" ){
	    ## Test the hash.  $nameField should point to a 1-element list, the element being the string matching the name
	    if( $obj->{$nameField}->[0] eq $name ){
	       ##  Match
	       return $obj->{$valField};
	    }else{
	       foreach my $key ( keys %$obj ){
		        my $subObj = $obj->{$key};
		        my $x = find_in_xml($subObj, $nameField, $name, $valField);
		        if( $x ){ return $x }
	       }
	    }
	    return 0;
   }
   return 0;
}

#------------------------------------------------------------------------------#
# Look in the "IP Tag" table of the XML for the "Foundry Metal Option"
#------------------------------------------------------------------------------#
sub parse_vici_xml_for_PHY_metal_option(){
   print_function_header();
   my $xml_fname = shift;
   my $product   = shift;
   my $vcrel     = shift;

   my $top = XMLin($xml_fname, ForceArray => 1, KeyAttr => {item => 'name'});
   my $ref = ref $top;

   my $IPTagArray;
   my $version;

   $IPTagArray = find_in_xml($top, "_Name", "Technology Process", "_Item");

   my $aref_components = find_in_xml($IPTagArray, "_Header", "PHY Metal Option", "_Value");
   dprint( HIGH, "Foundry Metal Option : \$aref_components = " . scalar(Dumper $aref_components) . "\n" );
   my @elements = find_aref_in_data_structure( $aref_components );
   my @components  = unique_scalars( \@elements );

   return( @components );
}

#------------------------------------------------------------------------------#
# Look in the "IP Tag" table of the XML for the "Foundry Metal Option"
#------------------------------------------------------------------------------#
sub parse_vici_xml_for_foundry_metal_option(){
   print_function_header();
   my $xml_fname = shift;
   my $product   = shift;
   my $vcrel     = shift;

   my $top = XMLin($xml_fname, ForceArray => 1, KeyAttr => {item => 'name'});
   my $ref = ref $top;

   my $IPTagArray;
   my $version;

   $IPTagArray = find_in_xml($top, "_Name", "Technology Process", "_Item");

   my $aref_components = find_in_xml($IPTagArray, "_Header", "Foundry Metal Option", "_Value");
   dprint( HIGH, "Foundry Metal Option : \$aref_components = " . scalar(Dumper $aref_components) . "\n" );
   my @elements = find_aref_in_data_structure( $aref_components );
   my @components  = unique_scalars( \@elements );

   return( @components );
}

#------------------------------------------------------------------------------#
# Look in the "IP Tag" table of the XML for the list of componnents.
#------------------------------------------------------------------------------#
sub parse_vici_xml_for_component_names(){
   print_function_header();
   my $xml_fname = shift;
   my $product   = shift;
   my $vcrel     = shift;

   my $top = XMLin($xml_fname, ForceArray => 1, KeyAttr => {item => 'name'});
   my $ref = ref $top;

   my $IPTagArray;
   my $version;

   $IPTagArray = find_in_xml($top, "_Name", "IP TAG", "_Item");

   my $aref_components = find_in_xml($IPTagArray, "_Label", "Component", "_Value");
   #foreach my $component ( @$aref_components ){
   #   my $array = find_in_xml($top, "_Name", "IP TAG", "_Item");
   #}
   #my $aref_components = find_in_xml($IPTagArray, "_Label", "Version", "_Value");
   dprint( HIGH, "Component Names : \$aref_components = " . scalar(Dumper $aref_components) . "\n" );
   my @elements = find_aref_in_data_structure( $aref_components );
   my @components  = unique_scalars( \@elements );

   return( @components );
}


#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
sub parse_vici_xml_for_pvt($$$){
   print_function_header();
   my $xml_fname = shift;
   my $product   = shift;
   my $vcrel     = shift;

   my $top = XMLin($xml_fname, ForceArray => 1, KeyAttr => {item => 'name'});
   my $ref = ref $top;

   my $pvtArray = find_in_xml($top, "_Name", "PVT Corners", "_Item");
   if( !$pvtArray ){
       eprint( "PVT information not found in $product/$vcrel\n" );
       exit;
   }
   my   @pvtStuff;
   push @pvtStuff, "Corner Type\tCorner Case\tCore Voltage (V)\tPLL Voltage (V)\tIO Voltage (V)\tTemperature (C)\tExtraction Corner\n";
   
   $pvtArray = $pvtArray->[0][0]->{_Info};
   foreach my $pvt ( @$pvtArray ){
       my $cornerType    = find_pvt_value($pvt, "Corner Type");
       my $cornerCase    = find_pvt_value($pvt, "Case");
       my $coreVoltage   = find_pvt_value($pvt, "Core Voltage (V)");
       my $pllVoltage    = find_pvt_value($pvt, "PLL Voltage (V)");
       my $ioVoltage     = find_pvt_value($pvt, "IO Voltage (V)");
       my $temp          = find_pvt_value($pvt, "Temperature (C)");
       my $extractCorner = find_pvt_value($pvt, "Extraction Corner");
       
       push @pvtStuff, "$cornerType\t$cornerCase\t$coreVoltage\t$pllVoltage\t$ioVoltage\t$temp\t$extractCorner\n";
   }

   return( @pvtStuff );
}


#------------------------------------------------------------------------------#
#  Look in the ViCi DB and grab summary of information.
#     use the MSIP utility 'msip_viciGenerateProjSummaryAdvancedXml.pl'
#------------------------------------------------------------------------------#
sub grab_vici_summary__write_xml($$$){
   print_function_header();
   my $xml_fname = shift;
   my $product   = shift;
   my $vcrel     = shift;

   my $cmd = "msip_vici_or_vc.pl -p $product -r $vcrel";
   my @output = run_script( $cmd, "viciOrVc");
   my $type = lc( $output[0] );
   chomp $type;

   if( $type =~ m/^vici|vc$/ ){
       my $cmd = "msip_${type}GenerateProjSummaryAdvancedXml.pl -p $product -r $vcrel --out $xml_fname";
       @output = run_script( $cmd, "viciGenerateProjSummary");
   }elsif( $type eq "NA" ){
       ##  Returns this if the product is not found.
       eprint( "Project $product/$vcrel was not found" );
       exit;
   }else{
       eprint( "Unrecognized value \"$type\" returned from msip_vici_or_vc.pl" );
       exit;
   }
   return( @output );
}



#------------------------------------------------------------------------------#
sub find_pvt_value {
    my $pvtObj = shift;
    my $name   = shift;

    my $valArray = find_in_xml( $pvtObj, "_Header", $name, "_Value" );
    return $valArray->[0][0];
}

#------------------------------------------------------------------------------#
sub run_script {
   print_function_header();
    my $cmd = shift;
    my $id  = shift;

    print "$cmd\n";
    my $script = "$id.csh";
    open SCR, ">$script";
      print SCR "#!/bin/csh\n";
      print SCR "module unload msip_shell_vc_utils\n";
      print SCR "module load msip_shell_vc_utils\n";
      print SCR "\n";
      print SCR "$cmd\n";
    close SCR;
	  my $cmd = "chmod +x $script; ./$script";
	  my ($stdout, $retval) = run_system_cmd( $cmd, $DEBUG );
    my @output = split(/\n/,$stdout);
    unlink "$script";

    return( @output );
}

#------------------------------------------------------------------------------#
sub showUsage {
   print_function_header();
    print "Usage:  $PROGRAM_NAME\\\n";
    print "    -product <product-type> -vcrel <vc-rel-name> -rel <unix-rel-name>\n\n";
    print "Description:\n";
    print "    Looks up the \"PVT Corners\" section in the specified product vc page and writes the information\n";
    print "    to a csv file in the project pcs/design directory\n";
    exit;
}

#------------------------------------------------------------------------------#
sub process_cmd_line_arg(){
   print_function_header();
   my ( $project, $product, $rel, $vcrel );

   my $result = GetOptions(
       "product=s" => \$product,
       "vcrel=s"   => \$vcrel,
       "debug=i"   => \$DEBUG,
   );

   my $OK = 1;
   if( !(defined $product) ){ eprint( "product is undefined\n" ); $OK=0}
   if( !(defined $vcrel  ) ){ eprint( "vcrel is undefined\n"   ); $OK=0}
   if( $DEBUG !~ m/^\d*$/  ){ eprint( "debug is not integer\n" ); $OK=0}  
   unless( $OK ){
      showUsage();
   }
   return ( $product, $vcrel );
}

