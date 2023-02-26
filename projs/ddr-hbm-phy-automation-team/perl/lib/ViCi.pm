package ViCi;

use strict;


use Exporter;

our @ISA   = qw(Exporter);
# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
    grab_vici_info
    get_vici_mstack
    get_vici_version
    get_vici_orientation
    get_vici_pvt_corners
    TEST__vici_utils
    TEST__expected_cfg_with_vici 
    TEST__setup_cell_cfg
);

use Data::Dumper;
$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };

use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);

use lib dirname(abs_path $0) . '/../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
print "-PERL- Loading Package: 'ViCi.pm'\n";

#----------------------------------#
our $REGEX_COMPONENTS_VERSION_HARD = ' :[^:]+: (\d\.\d+\w+)$';
our $REGEX_COMPONENTS_VERSION_SOFT = ' :[^:]+: (\S+-\S+-\S+)$';
our $REGEX_ORIENTATION             = ' : (_\w+)\+*(_\w+)* : ';
our $REGEX_MSTACK                  = '^PHY Metal Option: (.*)$';
our $REGEX_PVT                     = 'PVT options : (.*)$';
our $REGEX_PVT_ONLY                = '^([^_]*).*';
our $REGEX_CORNER_ONLY             = '^[^_]*_(.*)';

#------------------------------------------------------------------------------
#  Call the fucnctions necesary to collect information needed for the 
#     BOM generation scripts. All information collected from ViCi is
#     stored in the '$cfg' hash-ref.
#------------------------------------------------------------------------------
sub grab_vici_info($$$){
   print_function_header();
   my $component       = shift;
   my $cfg             = shift;
   my $aref_vici_info  = shift;

   my @ary_pvt_only;
   my @ary_cnr_only; 



   my $vici_name = $cfg->{$component}{viciname};
   #------------------------------------------------------------------------------------------
   # Setup default REGEX for extract (1) Metal Stack info (2) PVT info  (3) orientation info 
   #------------------------------------------------------------------------------------------
   # _VERSION version_regex requires some code to get right ... 
   $cfg->{$component}{mstack_regex}       = $REGEX_MSTACK      
                                    unless( defined $cfg->{$component}{mstack_regex}      );
   $cfg->{$component}{PVT_regex}          = $REGEX_PVT         
                                    unless( defined $cfg->{$component}{PVT_regex}         );
   if( defined $cfg->{$component}{orientation_regex} ){
      $cfg->{$component}{orientation_regex} = "^$vici_name" . $cfg->{$component}{orientation_regex};
   }else{
      $cfg->{$component}{orientation_regex} = "^$vici_name" . $REGEX_ORIENTATION;
   }
   #---------------------------------------------------------------------------

   if( defined $cfg->{$component}{mstack_regex} && $cfg->{$component}{mstack_regex} ne NULL_VAL ){
       $cfg->{$component}{mstack}  = get_vici_mstack     ( $cfg->{$component}{mstack_regex},
                                                           $aref_vici_info );
   }else{
       $cfg->{$component}{mstack}  = [ NULL_VAL ];
   }
   $cfg->{$component}{version}     = get_vici_version    ( $cfg->{$component}{viciname}, 
                                                           $cfg->{$component},
                                                           $aref_vici_info );
   if( defined $cfg->{$component}{orientation_regex} && $cfg->{$component}{orientation_regex} ne NULL_VAL ){
   $cfg->{$component}{orientation} = get_vici_orientation( $cfg->{$component}{orientation_regex},
                                                           $aref_vici_info );
   }else{
       $cfg->{$component}{orientation}  = NULL_VAL ;  # must avoid creating an AREF and using 'N/A' as a value
   }

   #---------------------------------------------------------------------------
   # Don't define any PVT related key/value pairs unless the component
   #     has a regex defined to search for the PVT info
   if( defined $cfg->{$component}{PVT_regex} && $cfg->{$component}{PVT_regex} ne NULL_VAL ){
      $cfg->{$component}{pvt_combos}  = get_vici_pvt_corners( $cfg->{$component}{PVT_regex} , $aref_vici_info );
      foreach my $pvt ( sort @{$cfg->{$component}{pvt_combos}} ){
          push( @ary_pvt_only, ($pvt =~ m/$REGEX_PVT_ONLY/   ) );
          push( @ary_cnr_only, ($pvt =~ m/$REGEX_CORNER_ONLY/) );
      }
      @ary_pvt_only = unique_scalars( \@ary_pvt_only );
      @ary_cnr_only = unique_scalars( \@ary_cnr_only );
      $cfg->{$component}{pvt_values}  = \@ary_pvt_only;
      $cfg->{$component}{pvt_corners} = \@ary_cnr_only;
   }else{
       $cfg->{$component}{pvt_combos}  = [ NULL_VAL ];
       $cfg->{$component}{pvt_corners} = [ NULL_VAL ];
       $cfg->{$component}{pvt_values}  = [ NULL_VAL ];
   }
}

#------------------------------------------------------------------------------
#  grab the metal stack name(s) and assign to appropriate component.
#      This should be improved ... recommend either (1) create object for each
#      component and it knows how to find it's metal stack or (2) use a sub ref
#------------------------------------------------------------------------------
sub get_vici_mstack ($$){
   print_function_header();
   my $regex     = shift;
   my $aref_vici = shift;

   my @metals = split( /\s+/, get_value_from_regex_in_lines( $regex , $aref_vici ) );
   return( \@metals );
}

#------------------------------------------------------------------------------
sub get_vici_pvt_corners ($$){
   print_function_header();
   my $regex     = shift;
   my $aref_vici = shift;
   
   my @corners = split( /\s+/, get_all_values_from_regex_in_lines( $regex , $aref_vici ) );
   return( \@corners );
}

#-------------------------------------------------------------------------------
#  Example Versions
#      ... from HBM : 1.12a 1.16a_amd 0.50a_intc 0.50a_intc 0.80a_rtl 0.90a_pre1 
#      ... from DDR SoftIP :  'phyinit_horizon : A-2020.02-BETA' 
#      ... from DDR SoftIP :  'firmware_horizon : A-2020.02-BETA',
#      ... from DDR SoftIP :  'pub : 1.04a_amdsow2680',
#-------------------------------------------------------------------------------
sub get_vici_version ($$$){
   print_function_header();
   my $vici_name  = shift;
   my $cfg = shift;
   my $aref_vici = shift;

   my $cell_regex = $cfg->{version_regex};
   my $regex;
   my $vici_version;
   if( defined $cell_regex ){
      $regex = $cell_regex;
      $regex = "^$vici_name".$cell_regex;
      $vici_version = get_value_from_regex_in_lines( $regex , $aref_vici );
      # Record final regex used so it's recorded in the HASH debug file
      $cfg->{version_regex} = $regex;
   }else{
      # if the regex for hard components fails, then the soft component regex should find the value
      #   So, must provide 3rd argument as '' to avoid default retval = NULL_VAL
      my $notfound_keyword = NULL_VAL;
      my $regex_hard = "^$vici_name" . $REGEX_COMPONENTS_VERSION_HARD;
      $vici_version = get_value_from_regex_in_lines( $regex_hard , $aref_vici , $notfound_keyword );
      if( $vici_version eq $notfound_keyword ){
         # Check failed using regex for HARD COMPONENT versions
         my $regex_soft = "^$vici_name" . $REGEX_COMPONENTS_VERSION_SOFT;
         $vici_version  = get_value_from_regex_in_lines( $regex_soft, $aref_vici );
         if( $vici_version eq $notfound_keyword ){
            # Check failed using regex for SOFT COMPONENT versions
            $cfg->{version_regex} = "Default REGEX's for 'ViCi Versions' failed:\n\tHARD=$regex_hard\n\tSOFT=$regex_soft";
         }else{
            # SOFT regex worked ... store it 
            $cfg->{version_regex} = $regex_soft;
         }
      }else{
         # HARD regex worked ... store it 
         $cfg->{version_regex} = $regex_hard;
      }
   }
 
   if( isa_aref($vici_version) ){
      return( $vici_version->[0] );
   }else{
      return( $vici_version );
   }
}

#-------------------------------------------------------------------------------
sub get_vici_orientation ($$){
   print_function_header();
   my $regex     = shift;
   my $aref_vici = shift;
   
   # Here's 2 unique line samples regex is designed to deal with properly 
   #  master_ns only : 2.00a
   #  awordx2 _ew : 1.12a
   #  ctb_horizon : A-2020.02-BETA   <---- horizon is in the orientation field, 
   #                                       so expect user to override it
   
   my $vici_orientation = get_value_from_regex_in_lines( $regex , $aref_vici );

   # If you get NULL_VAL , don't create an AREF 
   # If you get an AREF, nothing to do
   # otherwise, build an AREF so it gets expanded as a list
   unless( $vici_orientation eq NULL_VAL || isa_aref($vici_orientation) ){
      $vici_orientation = [ $vici_orientation ];
   }
   return( $vici_orientation );
}


#-------------------------------------------------------------------------------
sub TEST__vici_utils($$){
   print_function_header();
   my $cfg = shift;
   my $vici_info = shift;

   my (@vici_info) = split( /\n/, $vici_info );
   foreach my $component_name ( keys %$cfg ){
      dprint(SUPER, "Parsing ViCi info for component '$component_name'\n" );
      grab_vici_info( $component_name, $cfg , \@vici_info);
   }

   print_function_footer();
   return( $cfg );
}

################################
# A package must return "TRUE" #
################################
1;

__END__

