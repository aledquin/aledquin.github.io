############################################################
#Parsing functions
#
#  Author : Patrick Juliano
#  Author : Bhuvan Challa
#  Author : Harsimrat Singh Wadhawan
############################################################
package parsers;

use strict;
use warnings;
use Term::ANSIColor;
use Data::Dumper;

use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../../lib/perl";

use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
use Util::DS;

print "-PERL- Loading Package: ". __PACKAGE__ ."\n";
use Exporter;

our @ISA   = qw(Exporter);
# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
  parse_lpddr5xm_app_note 
  get_ibis_summary_cal_codes
  get_ibis_summary_vio_values
);

################################
# HSPICE APP Note Parsers #
################################

# Method to extract calibration code table from a LPDDR5XM App note.
sub parse_lpddr5xm_app_note {  

  my $file_contents_ref = shift;
  my $cal_code_array_ref = shift;
  my $vddq_hash_pdf_ref = shift;
  my @file_contents = @{$file_contents_ref};

  my $index = -1;    
  my @indices = ();
  
  # Find all the lines where the Calibration Code table exists.
  for (my $i = 0; $i < @file_contents; $i++) {

      my $line = trim  $file_contents[$i];  
      
      if ($line =~ /table.*:.*Calibration.*Code/i and index ($line, ".") == -1){
          my @split = split /\s+/, trim($line) ;

          if (@split <= 5) {
            $index = $i;
            push @indices, $index;
          }
          elsif ($line =~ /tcoil/i){
            $index = $i;
            push @indices, $index; 
          }
          else {
            $index = $i;
            push @indices, $index; 
          }
      }

  }
  
  dprint(HIGH, "Indices from the HSPICE App Note:\n");
  dprint(HIGH, Dumper(\@indices)."\n");

  if (@indices > 0) {

    foreach my $index (@indices) {
      
      for (my $i = $index; $i < @file_contents; $i++) {

        my $line = trim $file_contents[$i];

        if ($line =~ /notes/ig or $line =~ /confidential/ig){					     
          last;	            
        }

        else {
          
          my @array = split /\s+/, $line;

            if (@array >= 7) {
            
                my $last_index = @array - 1;
            
                my $PVT = $array[$last_index-4];
                $PVT =~ s/\*|\s+//ig;

                my $TEMP = $array[$last_index-2];
                $TEMP =~ s/[^0-9.-]//g;

                my $VDDQ = $array[$last_index-6];
                $VDDQ =~ s/[^0-9.-]//g;

                my $VDD = $array[$last_index-5];
                $VDD =~ s/[^0-9.-]//g;

                my $PCODE = trim $array[$last_index];
                my $NCODE = trim $array[$last_index-1];			    			    
                
                my %hash;
                $hash{"PVT"} = $PVT;
                $hash{"TEMP"} = $TEMP;
                $hash{"VDDQ"} = $VDDQ;
                $hash{"VDD"} = $VDD;
                $hash{"PCODE"} = $PCODE;
                $hash{"NCODE"} = $NCODE; 
                
                if (Scalar::Util::looks_like_number($PCODE) and Scalar::Util::looks_like_number($NCODE) and not(trim($VDD) eq '') ) {			      
                push $cal_code_array_ref, \%hash;
                insert_at_key $vddq_hash_pdf_ref, $hash{'VDDQ'}, \%hash;
            }			    			    
          
          }			
          
        }

      }

    }	    	    	    
    
    return 0;
    
  }

  else {return -1;}

}

################################
# IBIS Summary File Helpers #
################################

# Determine the convention for reporting Ncodes and Pcodes. Whether it's Ncode,Pcode or Pcode,Ncode
# Returns 0 if Ncode,Pcode
# Return 1 if Pcode, Ncode
sub determine_cal_code_convention($) {

  my $array_ref = shift;
  my @array = @{$array_ref};

  my $answer = 'N/A';

  foreach my $line (@array){

    if ($line =~ /(ncode|pcode)/i) {

      if ($line =~ /ncode.*,.*pcode/i){
        $answer = 0;
      }

      elsif ($line =~ /pcode.*,.*ncode/i){
        $answer = 1;
      }

      last;

    }  

  }

  return $answer;
  
}

# Determine the convention for reporting VDD and VDDQ values. Whether it's VDD,VDDQ or VDDQ,VDD
# Returns 0 if VDD,VDDQ
# Returns 1 if VDDQ,VDD
sub determine_vio_convention($) {

  my $array_ref = shift;
  my @array = @{$array_ref};

  my $answer = 'N/A';

  foreach my $line (@array){

    if ($line =~ /(vdd.*,)/i) {

      if ($line =~ /vdd\s?,.*vddq/i){
        $answer = 0;
      }

      elsif ($line =~ /vddq\s?,.*vdd/i){
        $answer = 1;
      }

      else {
        $answer = NULL_VAL;
      }

      last;

    }  

  }

  return $answer;
  
}

################################
# IBIS Summary File Parsers #
################################

# Method to extract calibration code table from a DDR54 Summary.
sub get_ibis_summary_cal_codes($) {

  my @summary_codes;  
  my $ibis_summary_ref = shift;  
  my @ibis_summary = @{$ibis_summary_ref};  
  my $convention = determine_cal_code_convention $ibis_summary_ref;  

  foreach my $line (@ibis_summary) {
    
    $_ = $line;    
    
    # Special regular expression for detecting calibration codes. Assuming that the cal_codes listed
    # in the summary file are valid for all PVTs.

    #           (TYP, TYP)           |     (MIN,MIN)        |        (MAX,MAX)
    if ($_ =~ /(\s+[0-9]+,\s+[0-9]+).*(\s+[0-9]+,\s+[0-9]+).*(\s+[0-9]+,\s+[0-9]+)/) { 
      
      my $a = trim $1;
      my $b = trim $2;
      my $c = trim $3;        

      $a =~  s/\,//g;
      $b =~  s/\,//g;
      $c =~  s/\,//g;                

      my @arr1 = split '\s+', $a; # Can be either Pcode,Ncode or Ncode,Pcode
      my @arr2 = split '\s+', $b; # Can be either Pcode,Ncode or Ncode,Pcode
      my @arr3 = split '\s+', $c; # Can be either Pcode,Ncode or Ncode,Pcode      

      my @split_array = split /\s+/, $_;
      my $model_name = $split_array[0];

      # Always put the Pcode as the first element in an array.      
      if ( $convention ) {

        push @summary_codes, [$arr1[0], $arr1[1], $model_name];
        push @summary_codes, [$arr2[0], $arr2[1], $model_name];
        push @summary_codes, [$arr3[0], $arr3[1], $model_name];

      } 

      elsif ( ! $convention ) {

        push @summary_codes, [$arr1[1], $arr1[0], $model_name];
        push @summary_codes, [$arr2[1], $arr2[0], $model_name];
        push @summary_codes, [$arr3[1], $arr3[0], $model_name];

      }     

      else {

        wprint "N/A found.\n";

      }

    }

  }

  return (\@summary_codes);

}

# Method to extract VDD/VDDQ from a DDR54 Summary.
sub get_ibis_summary_vio_values($){
  
  my %summary_codes;
  my $ibis_summary_ref = shift;  
  my @ibis_summary     = @{$ibis_summary_ref};  
  my $convention       = determine_vio_convention($ibis_summary_ref);  

  if ($convention eq NULL_VAL){
    wprint("Could not determine summary file convention for VDDQ/VDD.\n");
    $convention = 0;
  }

  foreach my $line (@ibis_summary) {

    # Special regular expression for detecting calibration codes. Assuming that the cal_codes listed
    # in the summary file are valid for all PVTs.
    #                VDD, VDDQ                                     
    # TYP/TT/25C  | MIN/SS/125C | MAX/FF/-40C

    if ( $line =~ /(\d\.\d+,\s+\d\.\d+).*(\d\.\d+,\s+\d\.\d+).*(\d\.\d+,\s+\d\.\d+)/ ){

      my $a = trim ($1);
      my $b = trim ($2);
      my $c = trim ($3);        

      $a =~  s/\,//g;
      $b =~  s/\,//g;
      $c =~  s/\,//g;                

      my @arr1 = split ('\s+', $a); # Can be either Pcode,Ncode or Ncode,Pcode
      my @arr2 = split ('\s+', $b); # Can be either Pcode,Ncode or Ncode,Pcode
      my @arr3 = split ('\s+', $c); # Can be either Pcode,Ncode or Ncode,Pcode      

      my @split_array = split (/\s+/, $line);
      my $model_name  = $split_array[0];

      # Always put the VDD as the first element in an array.      
      if ( ! $convention ) {

        insert_at_key (\%summary_codes, $model_name, [$arr1[0], $arr1[1]]);
        insert_at_key (\%summary_codes, $model_name, [$arr2[0], $arr2[1]]);
        insert_at_key (\%summary_codes, $model_name, [$arr3[0], $arr3[1]]);

      } 

      elsif ( $convention ) {

        insert_at_key (\%summary_codes, $model_name, [$arr1[1], $arr1[0]]);
        insert_at_key (\%summary_codes, $model_name, [$arr2[1], $arr2[0]]);
        insert_at_key (\%summary_codes, $model_name, [$arr3[1], $arr3[0]]);

      }     

      else {

        wprint "N/A found for VDDQ/VDD convention.\n";

      }

    }

  }

  return \%summary_codes;

}

################################
# A package must return "TRUE" #
################################
1;