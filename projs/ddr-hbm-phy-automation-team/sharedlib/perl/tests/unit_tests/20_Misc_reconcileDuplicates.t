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
use Util::DS;
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
   my $test_status=TEST__reconcileDuplicates( );
   done_testing();
   # exit( $test_status );
}
############    END Main    ####################


#-------------------------------------------------------------------------------
sub TEST__reconcileDuplicates {

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
      "expected_results1"  => [],
      "expected_results2"  => [],
      "expected_results3"  => [ 0, 1, 2, 3 ],
      "expected_results4"  => [ ],
      "expected_results5"  => [ ],
      "expected_results6"  => [ 0, 1, 2, 3, 4 ],
      "expected_results7"  => [ 0, 1, 2, 3 ],
      "expected_results8"  => [ ],
      "expected_results9"  => [ ],
      "expected_results10" => [ 4,5,6,7,8],

      "expected_failed1"  => FALSE, 
      "expected_failed2"  => FALSE, 
      "expected_failed3"  => FALSE, 
      "expected_failed4"  => FALSE, 
      "expected_failed5"  => FALSE, 
      "expected_failed6"  => FALSE, 
      "expected_failed7"  => FALSE, 
      "expected_failed8"  => TRUE, 
      "expected_failed9"  => TRUE, 
      "expected_failed10" => TRUE, 
   };
   
   #dprint(INSANE, "Data Structure with test content looks like this:\n"
   #              .pretty_print_href($href_test). "\n" );
   my $test_fail = FALSE;
   for( my $cnt=1; $cnt <= $href_test->{"num_tests"}; $cnt++ ){
       dprint(INSANE, "test #".$cnt."\n" );
       my $aref_test = $href_test->{"list${cnt}_ary1"};
       #next if (! isa_aref( $aref_test ));

       my $test_pass = compare__runtest( 
            $href_test->{"test${cnt}_msg"}  ,
            $href_test->{"list${cnt}_ary1"} , 
            $href_test->{"list${cnt}_ary2"} ,
            $href_test->{"expected_results${cnt}"},
            $href_test->{"expected_failed${cnt}"} ,
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
    my $expected_fail = shift;

    my $aref_results;
    my $test_status;
    
    my $temp_stdout = "/tmp/reconcileDuplicates_stdout$$";
    my $temp_stderr = "/tmp/reconcileDuplicates_stderr$$";
    my $stdout=*STDOUT;
    my $sterr=*STDERR;
    my $debug_verbosity = NONE;
    do {
        local *STDOUT;
        local *STDERR;
        unless( $DEBUG ){
            if( defined $ENV{DA_RUNNING_UNIT_TESTS} ){
                open(STDOUT, '>', $temp_stdout) || return 0;
                open(STDERR, '>', $temp_stderr) || return 0;
                $debug_verbosity = HIGH;
            }else{
               *STDOUT=*stdout;
               *STDERR=*stderr;
            }
        }

#------------------------------------------------------------------------------#
# These subroutines 'arrayContains'/'reconcileDuplicates' were surgically
#     extracted from alphaPinCheck.pl by Patrick Oct 2022.
#     And unit tests proved following three lines are equivalent:
#             @$aref = reconcileDuplicates( $aref_list1, $aref_list2 );
#             @$aref = simple_difference(   $aref_list1, $aref_list2 );
#    (undef, $aref ) = compare_lists(       $aref_list1, $aref_list2 );
# Given a reference to an array of scalars, will return unique elements only. 
# The behavior is similar to unix's 'uniq' command. But this function will
# only allow an array of scalers and will issue an error if you pass it something
# else. 
#------------------------------------------------------------------------------#
        dprint($debug_verbosity, "NOT AREF list1: $test_label\n") if ( ! isa_aref( $aref_list1));
        dprint($debug_verbosity, "NOT AREF list2: $test_label\n") if ( ! isa_aref( $aref_list2));

        (undef, $aref_results) = compare_lists(       $aref_list1, $aref_list2 );
        @$aref_results         = simple_difference(   $aref_list1, $aref_list2 );
        @$aref_results         = reconcileDuplicates( $aref_list1, $aref_list2 );
        dprint($debug_verbosity, join " ", "Results    => " , scalar(Dumper $aref_results    ), "\n" );

        #print Dumper $aref_results;
        my( $skip1, $skip2, $skip3, $lists_equiv )= 
            compare_lists($aref_results, $aref_expected_results );
        if( $lists_equiv ){ 
            $test_status='PASS'; 
        }else{ 
            $test_status='FAIL'; 
        }

   }; # end do block

    my $fail_stderr = 0;
    if ( -e $temp_stdout && ! -z $temp_stdout ){
        my @insides = read_file( $temp_stdout);
        my $contents = join "\n", @insides; 
        unlink $temp_stdout;
        $fail_stderr = 1 if ( $contents =~ m/-E-/);
    }

    if ( -e $temp_stderr && ! -z $temp_stderr ) {
        my @insides = read_file( $temp_stderr);
        my $contents = join "\n", @insides; 
        unlink $temp_stderr;
        $fail_stderr = 1 if ( $contents =~ m/-E-/);
    }

    # Documentation => is_deeply( $got, $expected, $test_name );
    if ( $fail_stderr ){
        $test_status = "FAIL";
        ok( $expected_fail, "$test_label expected fail '$expected_fail'" );
    }else{
        is_deeply(  $aref_results, $aref_expected_results, $test_label );
    }

    print( "---------------------------------------\n" );
    print( " $test_status : $test_label \n" );

    if( $test_status eq "FAIL" ){
       dprint( HIGH, join " ", "List1      => " , scalar(Dumper $aref_list1      ), "\n" );
       dprint( HIGH, join " ", "List2      => " , scalar(Dumper $aref_list2      ), "\n" );
       dprint( HIGH, join " ", "Results    => " , scalar(Dumper $aref_results    ), "\n" );
       dprint( HIGH, join " ", "Expected   => " , scalar(Dumper $aref_expected_results ), "\n" );
    }
    print "---------------------------------------\n";

   return( $test_status eq 'PASS' ? TRUE : FALSE );
}



1;
