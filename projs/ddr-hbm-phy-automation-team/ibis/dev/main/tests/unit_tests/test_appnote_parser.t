#!/depot/perl-5.14.2/bin/perl
###############################################################################
# Name    : test_ibis_quality.pl
# Author  : Harsimrat Singh Wadhawan
# Date    : 14 February, 2022
# Purpose : Test the IBIS Quality script on different inputs.
###############################################################################
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use List::Util qw(shuffle); 
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);
# use Switch;
use Test2::Bundle::More;


use lib "$FindBin::Bin/../../lib/perl";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
# use utilities;
use parsers;

#----------------------------------#
#our $STDOUT_LOG  = undef;    # Log msg to var => OFF
our $STDOUT_LOG  ='';   # Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = 1.00;
our $file_name    = "";
our $file_name_txt= "";
#----------------------------------#

BEGIN { our $AUTHOR='Harsimrat Singh Wadhawan'; header(); } 
    Main();
END {
   if( defined( $main::STDOUT_LOG) ){
      if( $main::STDOUT_LOG ne '' ){ 
         write_file( [split(/\n/, $STDOUT_LOG)], "${PROGRAM_NAME}.log");
      }
   }
   my ($out, $ret) = run_system_cmd("rm -rf $file_name $file_name_txt", $VERBOSITY);
   footer(); 
}

########  YOUR CODE goes in Main  ##############
sub Main {

    # plan 2 tests
    plan(2); 

    my @reports   = (
        "//depot/products/lpddr5x_mphy/project/d900-lpddr5xm-tsmc5ff12/ckt/rel/HSPICE_model_app_note/1.00a/HSPICE_model_app_note_lpddr5xm.pdf",                        
    );

    my @cal_code_array_expected = (

        {
        'NCODE' => '427',
        'PCODE' => '285',
        'PVT' => 'ss',
        'TEMP' => '-40',
        'VDD' => '0.675',
        'VDDQ' => '1.067'
        },
        {
        'NCODE' => '454',
        'PCODE' => '293',
        'PVT' => 'ss',
        'TEMP' => '125',
        'VDD' => '0.675',
        'VDDQ' => '1.067'
        },
        {
        'NCODE' => '335',
        'PCODE' => '241',
        'PVT' => 'tt',
        'TEMP' => '25',
        'VDD' => '0.75',
        'VDDQ' => '1.10'
        },
        {
        'NCODE' => '276',
        'PCODE' => '208',
        'PVT' => 'ff',
        'TEMP' => '-40',
        'VDD' => '0.825',
        'VDDQ' => '1.166'
        },
        {
        'NCODE' => '372',
        'PCODE' => '230',
        'PVT' => 'ss',
        'TEMP' => '-40',
        'VDD' => '0.675',
        'VDDQ' => '0.47'
        },
        {
        'NCODE' => '397',
        'PCODE' => '137',
        'PVT' => 'ss',
        'TEMP' => '125',
        'VDD' => '0.675',
        'VDDQ' => '0.47'
        },
        {
        'NCODE' => '286',
        'PCODE' => '66',
        'PVT' => 'tt',
        'TEMP' => '25',
        'VDD' => '0.75',
        'VDDQ' => '0.50'
        },
        {
        'NCODE' => '237',
        'PCODE' => '33',
        'PVT' => 'ff',
        'TEMP' => '-40',
        'VDD' => '0.825',
        'VDDQ' => '0.57'
        }
    );

    my %vddq_hash_pdf_expected = (
          '0.47' => [
                      {
                        'NCODE' => '372',
                        'PCODE' => '230',
                        'PVT' => 'ss',
                        'TEMP' => '-40',
                        'VDD' => '0.675',
                        'VDDQ' => '0.47'
                      },
                      {
                        'NCODE' => '397',
                        'PCODE' => '137',
                        'PVT' => 'ss',
                        'TEMP' => '125',
                        'VDD' => '0.675',
                        'VDDQ' => '0.47'
                      }
                    ],
          '0.50' => [
                      {
                        'NCODE' => '286',
                        'PCODE' => '66',
                        'PVT' => 'tt',
                        'TEMP' => '25',
                        'VDD' => '0.75',
                        'VDDQ' => '0.50'
                      }
                    ],
          '0.57' => [
                      {
                        'NCODE' => '237',
                        'PCODE' => '33',
                        'PVT' => 'ff',
                        'TEMP' => '-40',
                        'VDD' => '0.825',
                        'VDDQ' => '0.57'
                      }
                    ],
          '1.067' => [
                       {
                         'NCODE' => '427',
                         'PCODE' => '285',
                         'PVT' => 'ss',
                         'TEMP' => '-40',
                         'VDD' => '0.675',
                         'VDDQ' => '1.067'
                       },
                       {
                         'NCODE' => '454',
                         'PCODE' => '293',
                         'PVT' => 'ss',
                         'TEMP' => '125',
                         'VDD' => '0.675',
                         'VDDQ' => '1.067'
                       }
                     ],
          '1.10' => [
                      {
                        'NCODE' => '335',
                        'PCODE' => '241',
                        'PVT' => 'tt',
                        'TEMP' => '25',
                        'VDD' => '0.75',
                        'VDDQ' => '1.10'
                      }
                    ],
          '1.166' => [
                       {
                         'NCODE' => '276',
                         'PCODE' => '208',
                         'PVT' => 'ff',
                         'TEMP' => '-40',
                         'VDD' => '0.825',
                         'VDDQ' => '1.166'
                       }
                     ]
    );
    
    foreach my $report (@reports){

        ######### -Download File- #############    
        $file_name     = time()."appnote.pdf";
        
        $file_name_txt =  $file_name;
        $file_name_txt    =~ s/\.pdf/\.txt/ig;

        my ($out, $ret) = run_system_cmd("p4 -q print $report > $file_name", $VERBOSITY);
        
        ######### -Test file- #############
        ($out, $ret) = run_system_cmd("pdftotext -layout $file_name", $VERBOSITY);
        iprint ($out."\n");

        my (@cal_code_array, %vddq_hash_pdf);
        my @values = read_file($file_name_txt);
        my $answer = parse_lpddr5xm_app_note (\@values, \@cal_code_array, \%vddq_hash_pdf);

        dprint (LOW, Dumper(@cal_code_array)."\n");
        dprint (LOW, Dumper(@cal_code_array_expected)."\n");

        is_deeply(\@cal_code_array, \@cal_code_array_expected);
        is_deeply(%vddq_hash_pdf_expected, %vddq_hash_pdf);

        # ######### -Remove file- #############
        ($out, $ret) = run_system_cmd("rm -rf $file_name $file_name_txt", $VERBOSITY);

    }    

}
############    END Main    ####################


