use strict;
use warnings;
use Devel::StackTrace;
#use Data::Dumper::Concise;
use Data::Dumper;
#{ 
   $Data::Dumper::Terse=1;
   $Data::Dumper::Indent=0;
   $Data::Dumper::Useqq=0;
   $Data::Dumper::Deparse=0;
   $Data::Dumper::Quotekeys=0;
   $Data::Dumper::Sortkeys=1;
#}
use File::Copy;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../perl/lib";
use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
use Test2::Bundle::More;

our $PROGRAM_NAME = $RealScript; 
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
#----------------------------------#

&Main();

########  YOUR CODE goes in Main  ##############
sub Main(){
   plan(10);
   utils__process_cmd_line_args();
   my $test_status=TEST__compare_lists( );
   done_testing();
	 exit( $test_status );
}
############    END Main    ####################


#-------------------------------------------------------------------------------
sub TEST__compare_lists {

   my $href_test = {
      # Verify that null <=> null behaves as expected.
      "test1_msg"   => "Test 1 : [Null list] <=> [Null list]" ,
      "list1_ary1"  => [ ],
      "list1_ary2"  => [ ],
      # Verify that BOM w/null <=> REL/some files
      "test2_msg"   => "Test 2 : [Null list] <=> [some elements]" ,
      "list2_ary1"  => [ ],
      "list2_ary2"  => [ 0, 1, 2 ],
      # Verify that BOM w/some files <=> REL w/null
      "test3_msg"   => "Test 3 : [some elements] <=> [Null list]" ,
      "list3_ary1"  => [ 0, 1, 2, 3 ],
      "list3_ary2"  => [ ],
      # ALL match
      "test4_msg"   => "Test 4 : [1234] <=> [1234]" ,
      "list4_ary1"  => [ 0, 1, 2, 3 ],
      "list4_ary2"  => [ 0, 1, 2, 3 ],
      # Some Match, Some Don't
      "test5_msg"   => "Test 5 : [56] <=> [01234567]" ,
      "list5_ary1"  => [                5, 6,  ],
      "list5_ary2"  => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
      # Some Match, Some Don't
      "test6_msg"   => "Test 6 : [01234567] <=> [567]" ,
      "list6_ary1"  => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
      "list6_ary2"  => [                5, 6, 7 ],
      # None matching
      "test7_msg"   => "Test 7 : [0123] <=> [45678]" ,
      "list7_ary1"  => [ 0, 1, 2, 3 ],
      "list7_ary2"  => [             4, 5, 6, 7, 8 ],
      # bad args passed 
      "test8_msg"   => "Test 8 : {hash} <=> [45678]" ,
      "list8_ary1"  => { },
      "list8_ary2"  => [             4, 5, 6, 7, 8 ],
      # bad args passed 
      "test9_msg"   => "Test 9 : {string} <=> [45678]" ,
      "list9_ary1"  => "bad arg",
      "list9_ary2"  => [             4, 5, 6, 7, 8 ],
      # bad args passed 
      "test10_msg"  => "Test 10: [45678] <=> {string}" ,
      "list10_ary1" => [             4, 5, 6, 7, 8 ],
      "list10_ary2" => "bad arg",

      "num_tests" => 10,

      #Expected Results From Each test
      #      [   $status, $cnt_bom_list, $cnt_rel_list,
      #          $cnt_bom_only, $cnt_rel_only, $cnt_common, $match   ]
      #                         STAT    B    R    BO   RO   CMN   %BOM
      "expected_results1"  => [ 'ERR!', 0,   0,   0,   0,   0,   'ERR!'  ],
      "expected_results2"  => [ 'ERR!', 0,   3,   0,   3,   0,   'ERR!'  ],
      "expected_results3"  => [ 'ERR!', 4,   0,   4,   0,   0,   'ERR!'  ],
      "expected_results4"  => [ 'PASS', 4,   4,   0,   0,   4,   '100.0' ],
      "expected_results5"  => [ 'FAIL', 2,   8,   0,   6,   2,   '100.0' ],
      "expected_results6"  => [ 'FAIL', 8,   3,   5,   0,   3,   '37.5'  ],
      "expected_results7"  => [ 'FAIL', 4,   5,   4,   5,   0,   '0.0'   ],
      "expected_results8"  => [ 'ERR!', '-', '-', '-', '-', '-', 'ERR!'  ],
      "expected_results9"  => [ 'ERR!', '-', '-', '-', '-', '-', 'ERR!'  ],
      "expected_results10" => [ 'ERR!', '-', '-', '-', '-', '-', 'ERR!'  ],
   };
   
   #dprint(INSANE, "Data Structure with test content looks like this:\n"
   #              .pretty_print_href($href_test). "\n" );
   my $test_fail = FALSE;
   for( my $cnt=1; $cnt <= $href_test->{"num_tests"}; $cnt++ ){
       dprint(INSANE, "test #".$cnt."\n" );
       my $test_pass = compare__runtest( $href_test->{"test${cnt}_msg"}  ,
                         $href_test->{"list${cnt}_ary1"} , 
                         $href_test->{"list${cnt}_ary2"} ,
                         $href_test->{"expected_results${cnt}"}
                       );
       if( $test_pass == FALSE ){ $test_fail = 1; }
   }
	 # make sure return value indicates the following:
	 #     All tests PASS  => 0
	 #     Any test  FAILs => 1
	 return( $test_fail );
}


#-------------------------------------------------------------------------------
#  Check the EXPECTed result with ACTUAL result.
#-------------------------------------------------------------------------------
sub compare__runtest {
    print_function_header();
    my $test_label = shift;
    my $aref_list1 = shift;
    my $aref_list2 = shift;
    my $aref_expected_results = shift;

    my $report_msg;
    my $aref_results;
    my $test_status;
    my $aref_common;
    my $aref_list1_only;
    my $aref_list2_only;
    my $bool__lists_equiv;
    
    my $stdout=*STDOUT;
    my $sterr=*STDERR;
    do {
        local *STDOUT;
        local *STDERR;
        if( defined $ENV{DA_RUNNING_UNIT_TESTS} ){
            my $temp_stdout = "/tmp/stdout$$";
            my $temp_stderr = "/tmp/stderr$$";
            open(STDOUT, '>', $temp_stdout) || return 0;
            open(STDERR, '>', $temp_stderr) || return 0;
        }else{
           *STDOUT=*stdout;
           *STDERR=*stderr;
        }

        ($aref_common, $aref_list1_only, $aref_list2_only, 
            $bool__lists_equiv) = compare_lists( $aref_list1, $aref_list2 );

        ($report_msg, $aref_results) = report_list_compare_stats(
                  $aref_list1, $aref_list2,
                  $aref_common,
                  $aref_list1_only,
                  $aref_list2_only,
                  $bool__lists_equiv,
        );

        #print Dumper $aref_results;
        my( $skip1, $skip2, $skip3, $lists_equiv )= 
            compare_lists($aref_results, $aref_expected_results );
        if( $lists_equiv ){ 
            $test_status='PASS'; 
        }else{ 
            $test_status='FAIL'; 
        }

        # Documentation => is_deeply( $got, $expected, $test_name );
        is_deeply(  $aref_results, $aref_expected_results );

        print( "---------------------------------------\n" );
        print( " $test_status : $test_label \n" );

        if( $test_status eq "FAIL" ){
           dprint( HIGH, "Message Report =>\n" . $report_msg );
           dprint( HIGH, join " ", "List1      => " , scalar(Dumper $aref_list1      ), "\n" );
           dprint( HIGH, join " ", "List2      => " , scalar(Dumper $aref_list2      ), "\n" );
           dprint( HIGH, join " ", "List1_only => " , scalar(Dumper $aref_list1_only ), "\n" );
           dprint( HIGH, join " ", "List2_only => " , scalar(Dumper $aref_list2_only ), "\n" );
           dprint( HIGH, join " ", "Common     => " , scalar(Dumper $aref_common     ), "\n" );
           dprint( HIGH, join " ", "Results    => " , scalar(Dumper $aref_results ), "\n" );
           dprint( HIGH, join " ", "Expected   => " , scalar(Dumper $aref_expected_results ), "\n" );
        }
        print "---------------------------------------\n";
   };

   return( $test_status eq 'PASS' ? TRUE : FALSE );
}


##------------------------------------------------------------------
##  sub 'report_list_compare_stats' : 
##      requires two input lists ... 
##        1. list of files in REFERENCE/BOM <=> aref_bom
##        2. list of files in REL <=> aref_rel
##      ... and three lists derived from the sub 'compare_lists'
##        3. list of files in COMMON 
##        4. list of files in REF/BOM only 
##        5. list of files in REL only 
##      ... and a scalar capturing whether the REF=REL perfectly 
##        6. SCALAR ... TRUE / FALSE  => REF == REL / REF != REL
##      AND, this will return 2 values ... 
##        1. SCALAR = string capturing entire reporting message
##        2. ARY REF = computed values ... used for testing purposes
##------------------------------------------------------------------
sub report_list_compare_stats {
   print_function_header();
   my $aref_ref          = shift;
   my $aref_rel          = shift;
   my $aref_common       = shift;
   my $aref_ref_only     = shift;
   my $aref_rel_only     = shift;
   my $bool__lists_equiv = shift;


   my $mySubName = get_subroutine_name();
   my $bad_args_passed_to_sub = TRUE;
   my $cnt_ref_list;
   my $cnt_rel_list;

   my $cnt_common  ;
   my $cnt_ref_only;
   my $cnt_rel_only;

   unless( isa_aref( $aref_ref      ) &&
           isa_aref( $aref_rel      ) &&
           isa_aref( $aref_common   ) &&
           isa_aref( $aref_ref_only ) &&
           isa_aref( $aref_rel_only )     ){
      eprint( ("Bad argument passed to sub '$mySubName'. Expected ARRAY references.\n") ); 
      $cnt_ref_list = $cnt_rel_list = $cnt_common = $cnt_ref_only = $cnt_rel_only = 0;
      $bad_args_passed_to_sub = TRUE;
   }else{
      $bad_args_passed_to_sub = FALSE;
      dprint(FUNCTIONS, "Good arguments passed to sub '$mySubName'\n" );
      $cnt_ref_list = @{$aref_ref};
      $cnt_rel_list = @{$aref_rel};

      $cnt_common   = @{$aref_common};
      $cnt_ref_only = @{$aref_ref_only};
      $cnt_rel_only = @{$aref_rel_only};
   }

   my $status; my $match; my $rel_in_ref;
   my $total = $cnt_ref_list; 
   if( $total ==0 || $cnt_ref_list ==0 || $cnt_rel_list ==0 ){
      $status = "ERR!"; $match = "ERR!"; $rel_in_ref = "ERR!";
      if( $bad_args_passed_to_sub ){
         $cnt_ref_list = $cnt_rel_list = $cnt_common = $cnt_ref_only = $cnt_rel_only = '-';
      }
   }else{
      if( $bool__lists_equiv ){ 
         $status = "PASS"; 
      }else{
         $status = "FAIL"; 
      }
      $match = ($cnt_common*100/$total);
      $match = sprintf("%3.1f", $match);
      $rel_in_ref = 100*($cnt_rel_list - $cnt_rel_only)/$cnt_rel_list ;
      $rel_in_ref = sprintf("%3.1f", $rel_in_ref);
   }
   my $report_msg;
   $report_msg .= sprintf("-" x100 . "\n");
   $report_msg .= sprintf("%-9s%-11s%-11s%-10s%-10s%-8s%-21s%-18s\n",
                          "Status", "REF Files", "REL Files",
                          "REF Only", "REL Only", "Common", "(%REF found in REL)", "(%REL found in REF)");
   $report_msg .= sprintf("-" x100 . "\n");
   $report_msg .= sprintf("%-9s%-11s%-11s%-10s%-10s%-8s%-21s%-18s\n",
   $status, $cnt_ref_list, $cnt_rel_list,
   $cnt_ref_only, $cnt_rel_only, $cnt_common, $match, $rel_in_ref);

   return( $report_msg, [$status, $cnt_ref_list, $cnt_rel_list,
           $cnt_ref_only, $cnt_rel_only, $cnt_common, $match ]   );
}

1;
