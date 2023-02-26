#!/depot/perl-5.14.2/bin/perl -w
#!/usr/bin/env perl

use strict;
use Devel::StackTrace;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
#use Test2::Tools::Compare;
use Test2::Bundle::More;



use lib dirname(abs_path $0) . '/../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Excel;
use Util::Messaging;
use Manifest;

our $PROGRAM_NAME = $0; 
our $AUTHOR_NAME  = 'Patrick Juliano';
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
#----------------------------------#
use constant DESIGNATOR_MANDATORY => 'x';
use constant DESIGNATOR_OPTIONAL  => 'o';
use constant DESIGNATOR_INVALID   => '-';
use constant DESIGNATOR_SKIP      => 's';
use constant DESIGNATOR_CONDITIONAL=>'c';
#----------------------------------#

Main();

########  YOUR CODE goes in Main  ##############
sub Main {
   process_cmd_line_args();

#------------------------------------------------------------------------
   iprint( "Testing Manifest SPECification state space.\n" );
   my $cfg_fname = './tdata/BOM_test_content.cfg';
   TEST__supported_specs( $cfg_fname );
#------------------------------------------------------------------------

#------------------------------------------------------------------------
   iprint( "Testing search subroutines\n\t (1) column domain of a named BOM\n\t (2) release/copmonent/filespec\n" );
   TEST__index_searches();
#------------------------------------------------------------------------

#------------------------------------------------------------------------
   iprint( "Testing PASS/FAIL decision subroutine.\n" );
   TEST__decide_if_cmp_result_is_pass_or_fail();
#------------------------------------------------------------------------

#------------------------------------------------------------------------
   iprint( "Testing file interpolation methods.\n" );
   # grab all the test content available
   my $href = get_test_content();
   dprint( MEDIUM, "Here's the Content to be tested : \n" . pretty_print_href($href) ."\n" );
   foreach my $test_num ( sort keys %$href ){
      my $aref_interpolated_files = TEST__interpolate_filespecs(
                                        $href->{$test_num}{dictionary},
                                        $href->{$test_num}{filespecs}
                                    );
      # Compare the Result with what's Expected
      my $aref_expected_files = $href->{$test_num}{expected_file_list};
      is_deeply( $aref_expected_files , $aref_interpolated_files );
   }
#------------------------------------------------------------------------
    
   done_testing();
}
############    END Main    ####################
 

#-----------------------------------------------------------------
#  In order to setup these tests, gotta read in a real CFG, XLS
#     and go thru the standard parsing steps. Once the MM is in
#     a suitable data structure, can run the test sequences.
#-----------------------------------------------------------------
sub TEST__supported_specs($){
   my $cfg_fname = shift;

   our %globals;
   load_default_configs( \%globals, $cfg_fname );
   my ($cfg, $href_misc) =  $globals{$globals{'release_to_check'}}->();

   my $aref_MM  = read_sheet_from_xlsx_file( './tdata/' . $globals{'fname_MM_XLSX'}  ,
                                                     $globals{'XLSX_sheet_name'} );
   #----------------------------------------------------------------------------
   #  Find the col # of the RELEASE/PHASE name
   #----------------------------------------------------------------------------
   $globals{'CSV_index_REL'} = find_col_for_obj( $aref_MM, \%globals, $globals{'bom__phase_name'} );
    
   #----------------------------------------------------------------------------
   #  Find the col # of the the COMPONENT name
   #----------------------------------------------------------------------------
   foreach my $cell_name ( sort @{$globals{bom__cell_names}} ){
      $cfg->{$cell_name}->{'CSV_col_idx'} = find_col_for_obj( $aref_MM, \%globals, $cell_name );
   }

   #---------------------------------------------------------------------------
   # Since we only want to process lines in the MM that are tests ...
   #    grab those that are in the view 'unit_test' only.
   my $line_of_bom_start = $globals{row__bom_start};
   my $last_elem = @{$aref_MM}-1;  # scalar assignment capture size-of-list 

   my $row=-1;
   my $last_row_of_tests=-1;
   foreach $row ( $line_of_bom_start..$last_elem ){ 
      if( $aref_MM->[$row][$globals{CSV_index_VIEWS}] =~ m/^unit_test$/ ){
         $last_row_of_tests = $row;
         #print "row = $last_row_of_tests\n";
      }
   }
   my @lines_of_bomspec = @{$aref_MM}[$line_of_bom_start..$last_row_of_tests];
   #---------------------------------------------------------------------------

   #---------------------------------------------------------------------------
   #print Dumper \%globals;
   #print Dumper \@lines_of_bomspec;
   #----------------------------------------------------------------------------
      my $cell_name = 'master';  # tests are in the MASTER component column only
      foreach my $aref_csv_line ( @lines_of_bomspec ){
         my $status_checked = cross_check_manifest( $cell_name, $globals{'bom__phase_name'}, 
                            $aref_csv_line,
                            $cfg->{$cell_name}{CSV_col_idx} ,
                            $globals{CSV_index_REL},
                            $globals{CSV_index_FILES},
                            DESIGNATOR_MANDATORY  ,
                            DESIGNATOR_OPTIONAL   ,
                            DESIGNATOR_INVALID    ,
                            DESIGNATOR_SKIP       ,
                            DESIGNATOR_CONDITIONAL,
                          );
            is_deeply( $status_checked , $aref_csv_line->[$globals{CSV_index_FILES}+1] );
         if( $status_checked eq $aref_csv_line->[$globals{CSV_index_FILES}+1] ){
            #wprint( "status_checked = '$status_checked' \n" );
            #wprint( "status expected = '$aref_csv_line->[$globals{CSV_index_FILES}+1]' \n" );
            wprint( "Test Passed test label = '$aref_csv_line->[$globals{CSV_index_FILES}]'\n" );
         }else{
            wprint( "Test FAILED!\n" );
            #wprint( "status_checked = '$status_checked' \n" );
            #wprint( "status expected = '$aref_csv_line->[$globals{CSV_index_FILES}+1]' \n" );
            wprint( "test label = '$aref_csv_line->[$globals{CSV_index_FILES}]' \n" );
         }
      }
      pre_process_bom_for_optional_views_in_phase( \@lines_of_bomspec , 
                    $cfg->{$cell_name}{CSV_col_idx} ,
                    $globals{CSV_index_REL} ,
                    $globals{CSV_index_FILES} ,
                    DESIGNATOR_OPTIONAL ,
                    DESIGNATOR_MANDATORY
      );
  #----------------------------------------------------------------------------
   return();
}

#-----------------------------------------------------------------
sub TEST__decide_if_cmp_result_is_pass_or_fail(){
   my $RefFiles_href;
   my $ReleaseFiles_href;
   my $bomOnly_href;
   my $relOnly_href;
   

   #------------------------------------------
   #  Test Logic Explanation
   #  '0' - Ref an REL have same # files ... bomOnly nonzero & relOnly nonzero => expect FAIL
   #  '1' - Ref an REL have same # files ... bomOnly nonzero & relOnly empty   => expect FAIL
   #  '2' - Ref an REL have same # files ... bomOnly empty   & relOnly nonzero => expect FAIL
   #  '3' - Ref an REL have same # files ... bomOnly empty   & relOnly empty   => expect PASS
   #  '4' - Ref an REL have diff # files ... bomOnly nonzero & relOnly nonzero => expect FAIL
   #  '5' - Ref an REL have diff # files ... bomOnly nonzero & relOnly empty   => expect FAIL
   #  '6' - Ref an REL have diff # files ... bomOnly empty   & relOnly nonzero => expect FAIL
   #  '7' - Ref an REL have diff # files ... bomOnly empty   & relOnly empty   => expect FAIL
   #  '8' - Ref an REL have diff # files ... bomOnly nonzero & relOnly nonzero => expect FAIL
   #  '9' - Ref an REL have diff # files ... bomOnly nonzero & relOnly empty   => expect FAIL
   # '10' - Ref an REL have diff # files ... bomOnly empty   & relOnly nonzero => expect FAIL
   # '11' - Ref an REL have diff # files ... bomOnly empty   & relOnly empty   => expect FAIL
   #------------------------------------------
   my @test_indexes = ( qw( 0 1 2 3 4 5 6 7 8 9 10 11 ) );
   my @list_equiv_expected = ( FALSE, FALSE, FALSE, TRUE,
                               FALSE, FALSE, FALSE, FALSE, 
                               FALSE, FALSE, FALSE, FALSE, );
   my @list_equiv_got;

   $RefFiles_href = {
      '0' => [ 1, 2, 3, 4, 5 ],
      '1' => [ 1, 2, 3, 4, 5 ],
      '2' => [ 1, 2, 3, 4, 5 ],
      '3' => [ 1, 2, 3, 4, 5 ],
      '4' => [ 1, 2, 3, 4, 5 ],
      '5' => [ 1, 2, 3, 4, 5 ],
      '6' => [ 1, 2, 3, 4, 5 ],
      '7' => [ 1, 2, 3, 4, 5 ],
      '8' => [ 1, 2, 3, 4  ],
      '9' => [ 1, 2, 3, 4  ],
     '10' => [ 1, 2, 3, 4  ],
     '11' => [ 1, 2, 3, 4  ],
   };
   $ReleaseFiles_href = {
      '0' => [ 1, 2, 3, 4, 5 ],
      '1' => [ 1, 2, 3, 4, 5 ],
      '2' => [ 1, 2, 3, 4, 5 ],
      '3' => [ 1, 2, 3, 4, 5 ],
      '4' => [ 1, 2, 3, 4  ],
      '5' => [ 1, 2, 3, 4  ],
      '6' => [ 1, 2, 3, 4  ],
      '7' => [ 1, 2, 3, 4  ],
      '8' => [ 1, 2, 3, 4, 5  ],
      '9' => [ 1, 2, 3, 4, 5  ],
     '10' => [ 1, 2, 3, 4, 5  ],
     '11' => [ 1, 2, 3, 4, 5  ],
   };
   $bomOnly_href = {
      '0' => [ 1 ],
      '1' => [ 1 ],
      '2' => [ ],
      '3' => [ ],
      '4' => [ 1 ],
      '5' => [ 1 ],
      '6' => [ ],
      '7' => [ ],
      '8' => [ 1 ],
      '9' => [ 1 ],
     '10' => [ ],
     '11' => [ ],
   };
   $relOnly_href = {
      '0' => [ 1 ],
      '1' => [ ],
      '2' => [ 1 ],
      '3' => [ ],
      '4' => [ 1 ],
      '5' => [ ],
      '6' => [ 1 ],
      '7' => [ ],
      '8' => [ 1 ],
      '9' => [ ],
     '10' => [ 1 ],
     '11' => [ ],
   };
   
   foreach my $testnum ( @test_indexes ){
      push( @list_equiv_got,  decide_if_cmp_result_is_pass_or_fail( $RefFiles_href->{$testnum} , $ReleaseFiles_href->{$testnum} ,
                                                              $bomOnly_href->{$testnum} ,      $relOnly_href->{$testnum} )
      );
      # Documentation => is_deeply( $got, $expected, $test_name );
      is_deeply( $list_equiv_got[$testnum], 
              $list_equiv_expected[$testnum], "Checking PASS/FAIL decision subroutine...test \#$testnum" 
      );
   }
}


#------------------------------------------------------------------------------
#  In order to search for the RELEASE, Components, and FileSPECs that
#     are associated with a given name (i.e. a standard or custom BOM),
#     a couple subroutines are used to (1) search a line for the list of
#     columns where the named BOM exists and (2) search a different line
#     for the RELEASE and COMPONENTS and FileSPECs, but limited only to 
#     the columns where the named BOM exists.
#------------------------------------------------------------------------------
sub TEST__index_searches {
   process_cmd_line_args();

   my @ary;
      $ary[0] = [ qw( 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 ) ];
      $ary[1] = [ qw( a b b c c c d d d d e e e e e f f f f f f ) ];
      $ary[2] = [ qw( - - - - - - - - - - - - - - - - - - - - - ) ];
      $ary[3] = [ qw( - - - - - y - - - - y - - - - - - - - - - ) ];
      $ary[4] = [ qw( - - - - - - y - - - - - - - - - - - - - - ) ];
      $ary[5] = [ qw( - - - - - - - - - y - - - - - - - - - - - ) ];
      $ary[6] = [ qw( - - - - - - - - y - - - - - - - - - - - - ) ];
      $ary[7] = [ qw( - - - - - - - y y - - - - - - - - - - - - ) ];
 
   # Run the tests!
   iprint( "Running tests on sub 'get_all_indexes_in_list'\n" );
   TEST__get_all_indexes_in_list( @ary );

   iprint( "Running tests on sub 'find_obj_in_range'\n" );
   TEST__find_obj_in_range( @ary );
}

#------------------------------------------------------------------
#  TESTs for the sub 'get_all_indexes_in_list'
#------------------------------------------------------------------
sub TEST__get_all_indexes_in_list(@){
   my @ary = @_;
   #----------------------------------------------------------------------------
   # Test Inputs Structure
   # 	   inputs   => [ 'range_name' , 'row of ary' , 'num' ]
   # 	   expected => [ \d+, \d+ ...]  or if not found, then [ '' ]
   #
   # 	   So, the goal is to search for 'range_name' in 'row' starting from
   # 	       index 'num' and what is expected is the list of index where the
   # 	       named range was matched 
   my %tests_for_range_search = (
      '1' => { 
         'inputs'   =>  [ 'z', 1, 0 ],
         'expected' =>  [ '' ],
      },
      '2' => { 
         'inputs'   =>  [ 'a', 1, 1 ],
         'expected' =>  [ '' ],
      },
      '3' => { 
         'inputs'   =>  [ 'd', 1, 2 ],
         'expected' =>  [ 6,7,8,9 ],
      },
      '4' => { 
         'inputs'   =>  [ 'f', 1, 10 ],
         'expected' =>  [ 15, 16, 17, 18, 19, 20, ],
      },
   );
   foreach my $test_num ( sort keys %tests_for_range_search ){
      my $range_name  = $tests_for_range_search{$test_num}{inputs}[0];
      my $row_num     = $tests_for_range_search{$test_num}{inputs}[1];
      my $aref_offset = $tests_for_range_search{$test_num}{inputs}[2];
      my @range_vals = get_all_indexes_in_list( $ary[$row_num], $range_name, $aref_offset );
      print "-----test # $test_num\t-----\n";
      dprint( HIGH, pretty_print_aref( \@range_vals ) . "\n" );
      dprint( HIGH, pretty_print_aref( $tests_for_range_search{$test_num}{expected} ) . "\n" );
      is_deeply(  \@range_vals,
                  $tests_for_range_search{$test_num}{expected} 
               );
   }
  
}

#------------------------------------------------------------------
# TESTs for the sub 'find_obj_in_range'
#------------------------------------------------------------------
sub TEST__find_obj_in_range (@) {
   my @ary = @_;

   my %tests= (
      '1' => { 
         'inputs'   =>  [ 'd', 'y', 1, 2 ],
         'expected' =>  [ 'not found' ],
      },
      '2' => { 
         'inputs'   =>  [ 'd', 'y', 1, 3 ],
         'expected' =>  [ 'not found' ],
      },
      '3' => { 
         'inputs'   =>  [ 'd', 'y', 1, 4 ],
         'expected' =>  [ 6 ],
      },
      '4' => { 
         'inputs'   =>  [ 'd', 'y', 1, 5 ],
         'expected' =>  [ 9 ],
      },
      '5' => { 
         'inputs'   =>  [ 'd', 'y', 1, 6 ],
         'expected' =>  [ 8 ],
      },
      '6' => { 
         'inputs'   =>  [ 'd', 'y', 1, 7 ],
         'expected' =>  [ 7 ],
      },
   );

   foreach my $test_num ( sort keys %tests ){
      my $range_name = $tests{$test_num}{inputs}[0];
      my $obj_name   = $tests{$test_num}{inputs}[1];
      my $row__derive_range            = $tests{$test_num}{inputs}[2];
      my $row__search_for_obj_in_range = $tests{$test_num}{inputs}[3];
      my $got = find_obj_in_range( \@ary, $range_name, $obj_name,
                                        $row__derive_range,
                                        $row__search_for_obj_in_range
                    );
      # Documentation => is_deeply( $got, $expected, $test_name );
      is_deeply( $got, $tests{$test_num}{expected}[0] );
   }

}


#-------------------------------------------------------------------------------
sub process_cmd_line_args(){

   my %options=();
   getopts("hd:", \%options);
   my $opt_d = $options{d}; # debug verbosity setting
   my $help  = $options{h};


   if ( $help || ( defined $opt_d && $opt_d !~ m/^\d*$/ ) ){  
      my $msg  = "USAGE:  $PROGRAM_NAME -v # -h \n";
         $msg .= "... add debug statments with -v #\n";
      iprint( $msg );
      exit;
   }   

   # decide whether to alter DEBUG variable
   # '-v' indicates DEBUG value ... set based on user input
   if( defined $opt_d && $opt_d =~ m/^\d*$/ ){  
      $DEBUG = $opt_d;
   }   

}
 
 
#-------------------------------------------------------------------------------
sub TEST__interpolate_filespecs($$){
   my $href_dictionary = shift;
   my $aref_filespecs  = shift;

   my @files;
   foreach  my $filespec ( @$aref_filespecs ){
       my @interpolated_files_list = recursively_interpolate_filespec( $href_dictionary, $filespec );
       push(@files, @interpolated_files_list );
   }
   my $msg  = scalar(Dumper $aref_filespecs);
      $msg .= "------------------------------------------------------------------------\n";
      $msg .= scalar(Dumper \@files);
      $msg .= "------------------------------------------------------------------------\n";
   dprint( MEDIUM, $msg);
   return( \@files );
}

#-------------------------------------------------------------------------------
#      'mstack'      => '', # legal
#      'mstack'      => [ qw( 18M_1X_h_1Xa_v_1Ya_h_4Y_vhvh 13M_1X_h_1Xa_v_1Ya_h_4Y_vhvh ) ], # legal, all values used
#      'mstack'      => qw( 18M_1X_h_1Xa_v_1Ya_h_4Y_vhvh 19M_1X_h_1Xa_v_1Ya_h_4Y_vhvh  ),   # legal, only 1st val used, rest ignored
#      'mstack'      => qr/adsfas/ , # illegal -> this is type 'REGEXP' and disallowed
#      'mstack'      =>  qw/adsfas/, # legal -> array of length 1
sub get_test_content(){
   my $href = {
      # Check single-list expansion works
      '0' => {
          'dictionary' => {
             'viciname' => 'test0',
             'mstack'      => qr/adsfas/ , # illegal -> this is type 'REGEXP' and disallowed
             'pvt_values'  => [ qw(ff0p935v0c ss0p935v0c typical ) ],
          },
          'filespecs' => [ qw(
              timing/\@{mstack}/blah.txt
          ) ],
          'expected_file_list' => [ qw( ) ],
      },
      '1' => {
          'dictionary' => {
             'viciname' => 'test1',
             'mstack'      => [ qw(6M_1X_h_1Xa_v_1Ya_h_2Y_vh) ],
             'pvt_values'  => [ qw(ff0p935v0c ss0p935v0c typical ) ],
          },
          'filespecs' => [ qw(
              timing/\@{mstack}/lib/dwc_ddr54_${cell_name}.db
          ) ],
          'expected_file_list' => [ qw(
              timing/6M_1X_h_1Xa_v_1Ya_h_2Y_vh/lib/dwc_ddr54_${cell_name}.db
          ) ],
      },
      # Check single-list + 'named var' expansion works
      #  (where 'named var' means ... there is a list and a scalar with same name)
      '2' => {
          'dictionary' => {
             'viciname' => 'test2',
             'mstack'      => [ qw(6M_1X 7M_2X) ],
             'pvt_values'  => [ qw(ff0p935v0c ss0p935v0c ) ],
          },
          'filespecs' => [ qw(
              timing/\@{mstack}/lib/dwc_ddr54_${cell_name}_${mstack}.db
          ) ],
          'expected_file_list' => [ qw(
              timing/6M_1X/lib/dwc_ddr54_${cell_name}_6M_1X.db
              timing/7M_2X/lib/dwc_ddr54_${cell_name}_7M_2X.db
          ) ],
      },
      # Check multi-list expansion works
      '3' => {
          'dictionary' => {
             'viciname' => 'test3',
             'mstack'      => [ qw(6M_1X 7M_2X) ],
             'pvt_values'  => [ qw(ff0p935v0c ss0p935v0c ) ],
          },
          'filespecs' => [ qw(
              timing/\@{mstack}/lib/dwc_ddr54_${cell_name}_\@{pvt_values}.db
          ) ],
          'expected_file_list' => [ qw(
              timing/6M_1X/lib/dwc_ddr54_${cell_name}_ff0p935v0c.db
              timing/6M_1X/lib/dwc_ddr54_${cell_name}_ss0p935v0c.db
              timing/7M_2X/lib/dwc_ddr54_${cell_name}_ff0p935v0c.db
              timing/7M_2X/lib/dwc_ddr54_${cell_name}_ss0p935v0c.db
          ) ],
      },
      # Check to variable multiple list expansion mixed with named var works.
      #  (where 'named var' means ... there is a list and a scalar with same name
      '4' => {
          'dictionary' => {
             'viciname' => 'test4',
             'mstack'      => [ qw(6M_1X 7M_2X) ],
             'pvt_values'  => [ qw(ff0p935v0c ss0p935v0c ) ],
          },
          'filespecs' => [ qw(
              timing/\@{mstack}/lib/dwc_ddr54_${mstack}_\@{pvt_values}.db
          ) ],
          'expected_file_list' => [ qw(
              timing/6M_1X/lib/dwc_ddr54_6M_1X_ff0p935v0c.db
              timing/6M_1X/lib/dwc_ddr54_6M_1X_ss0p935v0c.db
              timing/7M_2X/lib/dwc_ddr54_7M_2X_ff0p935v0c.db
              timing/7M_2X/lib/dwc_ddr54_7M_2X_ss0p935v0c.db
          ) ],
      },
      # Verify that the behavior remains intact for the case when a variable
      #   is used in the fileSPEC does not exist in the dictionary
      '5' => {
          'dictionary' => {
             'viciname' => 'test5',
             'mstack'      => [ qw(6M_1X 7M_2X) ],
             'pvt_values'  => [ qw(ff0p935v0c ss0p935v0c ) ],
          },
          'filespecs' => [ qw(
              timing/\@{mstack}/lib/dwc_ddr54_${cell_name}_\@{pvt_values}.db
              timing/\@{var_not_in_dictionary}/lib/dwc_ddr54_${cell_name}_\@{pvt_values}.db
          ) ],
          'expected_file_list' => [ qw(
              timing/6M_1X/lib/dwc_ddr54_${cell_name}_ff0p935v0c.db
              timing/6M_1X/lib/dwc_ddr54_${cell_name}_ss0p935v0c.db
              timing/7M_2X/lib/dwc_ddr54_${cell_name}_ff0p935v0c.db
              timing/7M_2X/lib/dwc_ddr54_${cell_name}_ss0p935v0c.db
              timing/@{var_not_in_dictionary}/lib/dwc_ddr54_${cell_name}_ff0p935v0c.db
              timing/@{var_not_in_dictionary}/lib/dwc_ddr54_${cell_name}_ss0p935v0c.db
          ) ],
      },
      # Verify that the behavior remains intact for the case when a variable
      #   is used in the fileSPEC does not exist in the dictionary. This next
      #   test is a variation of the previous similar case.
      '6' => {
          'dictionary' => {
             'viciname' => 'test6',
             'cell_name'   => 'myCell',
             'mstack'      => [ qw(6M_1X 7M_2X) ],
             'pvt_values'  => [ qw(ff0p935v0c ss0p935v0c ) ],
          },
          'filespecs' => [ qw(
              timing/\@{var_not_in_dictionary}/lib/dwc_ddr54_${cell_name}_\@{pvt_values}.db
          ) ],
          'expected_file_list' => [ qw(
              timing/@{var_not_in_dictionary}/lib/dwc_ddr54_${cell_name}_ff0p935v0c.db
              timing/@{var_not_in_dictionary}/lib/dwc_ddr54_${cell_name}_ss0p935v0c.db
          ) ],
      },
   };

   return( $href );
}
