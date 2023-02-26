use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
#use Test2::Tools::Compare;
use Test2::Bundle::More;

use lib dirname(abs_path $0) . '/../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;



our $PROGRAM_NAME = $0; 
our $AUTHOR_NAME  = 'Patrick Juliano';
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $DEBUG_LOG = undef;
#----------------------------------#


&Main();

########  YOUR CODE goes in Main  ##############
sub Main() {
   utils__process_cmd_line_args();
   # Current planned test count
   plan(33);
   #-------------------------------------------------------------------------
   #  Test 'append_arrays'
   #-------------------------------------------------------------------------
      setup_tests__append_arrays();
      setup_tests__unique_scalars();
      setup_tests__trim();
      hprint( "Running script because it tests code in Util modules\n" );
      run_system_cmd( './TEST__compare.pl', $VERBOSITY);
   #-------------------------------------------------------------------------
   #
   done_testing();
   exit(0);
}
############    END Main    ####################
 
#-------------------------------------------------------------------------
#  Setup tests to exercise the trim subroutine
#-------------------------------------------------------------------------
sub setup_tests__trim(){

    my $subname = 'trim';        
    my $cnt = 1;

    #-------------------------------------------------------------------------
    #  Test 'trim'
    #-------------------------------------------------------------------------
    my %tests = (
         '1' => {
             'test'     => "",
             'expected' => "" ,
         },
         '2' => {
             'test'     => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         },
         '3' => {
             'test'     => "ABCDEFGHIJKLMNOPQRSTUVWXYZ  ",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         },
         '4' => {
             'test'     => "  ABCDEFGHIJKLMNOPQRSTUVWXYZ",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         },
         '5' => {
             'test'     => "  ABCDEFGHIJKLMNOPQRSTUVWXYZ  ",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         },
         '6' => {
             'test'     => "ABCDEFGHIJKLMNOPQRSTUVWXYZ\n",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '7' => {
             'test'     => "\nABCDEFGHIJKLMNOPQRSTUVWXYZ",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '8' => {
             'test'     => "\nABCDEFGHIJKLMNOPQRSTUVWXYZ\n",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         },         
         '9' => {
             'test'     => "\tABCDEFGHIJKLMNOPQRSTUVWXYZ",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '10' => {
             'test'     => "ABCDEFGHIJKLMNOPQRSTUVWXYZ\t",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '11' => {
             'test'     => "\tABCDEFGHIJKLMNOPQRSTUVWXYZ\t",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '12' => {
             'test'     => "\rABCDEFGHIJKLMNOPQRSTUVWXYZ",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '13' => {
             'test'     => "ABCDEFGHIJKLMNOPQRSTUVWXYZ\r",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '14' => {
             'test'     => "\rABCDEFGHIJKLMNOPQRSTUVWXYZ\r",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '15' => {
             'test'     => "\rABCDEFGHIJKLMNOPQRSTUVWXYZ\r\t\n\f",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
         }, 
         '16' => {
             'test'     => "\rABCDEFGHIJKLMNOPQRSTUVWXYZ VWXYZ VWXYZ 123 456\r\t\n\f",
             'expected' => "ABCDEFGHIJKLMNOPQRSTUVWXYZ VWXYZ VWXYZ 123 456",
         }, 
         '17' => {
             'test'     => "\r\r\t\n\f",
             'expected' => "",
         }, 
         '18' => {
             'test'     => "                ",
             'expected' => "",
         }, 
      );

    foreach my $cnt ( sort {$a<=>$b} keys %tests ){
        my ($computed_content) = trim( $tests{$cnt}{test} );
        is_deeply( $computed_content , $tests{$cnt}{expected}, "$subname : test$cnt" );
        dprint(SUPER, "test content : "   .( $tests{$cnt}{test}     )."\n" );
        dprint(SUPER, "expected content: ".( $tests{$cnt}{expected} )."\n" );
        dprint(SUPER, "computed content: ".( $computed_content      )."\n" );
    }

}

#-------------------------------------------------------------------------
#  Setup tests to exercise the append array subroutine
#-------------------------------------------------------------------------
sub setup_tests__unique_scalars(){
      my $subname = 'unique_scalars';
      my $cnt = 1;

      #-------------------------------------------------------------------------
      #  Test 'unique_scalars'
      #-------------------------------------------------------------------------
      my %tests = (
         '1' => {
             'test'     => [ ],
             'expected' => [ ],
         },
         '2' => {
             'test'     => [ qw( elem3 elem2 elem3 elem1 ) ],
             'expected' => [ qw( elem3 elem2 elem1 ) ],
         },
         '3' => {
             'test'     => [ qw( elem2 elem1 elem2 elem1 elem2 elem1 ) ],
             'expected' => [ qw( elem2 elem1 ) ],
         },
         '4' => {
             'test'     => [ qw( elem1 elem2 elem2 elem3 ) ],
             'expected' => [ qw( elem1 elem2 elem3 ) ],
         },
         '5' => {
             'test'     => [ qw( elem1 elem2 elem3 elem4 elem1 elem2 elem3 elem4 ) ],
             'expected' => [ qw( elem1 elem2 elem3 elem4 ) ],
         },
         '6' => {
             'test'     => [ qw( elem4 elem4 elem3 elem3 elem2 elem2 elem1 elem1 ) ],
             'expected' => [ qw( elem4 elem3 elem2 elem1 ) ],
         },
         '7' => {
             'test'     => 'string',
             'expected' => [ ],
         },
         '8' => {
             'test'     => { key => 'value' },
             'expected' => [ ],
         },
      );
      foreach my $cnt ( sort {$a<=>$b} keys %tests ){
         my (@computed_list) = unique_scalars( $tests{$cnt}{test} );
         is_deeply( \@computed_list , $tests{$cnt}{expected}, "$subname : test$cnt" );
         dprint(SUPER, "test content : ".pretty_print_aref( $tests{$cnt}{test}     )."\n" );
         dprint(SUPER, "expected list: ".pretty_print_aref( $tests{$cnt}{expected} )."\n" );
         dprint(SUPER, "computed list: ".pretty_print_aref( \@computed_list        )."\n" );
      }
         my @silly_array = qw( bhuvan patrick );
         my (@computed_list) = unique_scalars( @silly_array );
         is_deeply( \@computed_list , [], "$subname : test9" );
      #-------------------------------------------------------------------------
      #  This next test will throw a compile error when the subroutine
      #      'unique_scalars' has prototyping for a scalar (which is
      #      the desired value since an AREF is the expected argument).
      #-------------------------------------------------------------------------
      #     (@computed_list) = unique_scalars( 'bhuvan', 'patrick' );
      #  is_deeply( \@computed_list , [], "$subname : test10" );
      #-------------------------------------------------------------------------

}

#-------------------------------------------------------------------------
#  Setup tests to exercise the append array subroutine
#-------------------------------------------------------------------------
sub setup_tests__append_arrays(){
      my ($aref_set1, $aref_set2, $aref_expect, $aref_computed);
      my $cnt=1;

      #-------------------------------------------------------------------------
      #  Test 'append_arrays'
      #-------------------------------------------------------------------------
      $aref_set1   = [ qw( ele1 ele2 ) ];
      $aref_set2   = [ qw( ele3 ele4 ) ];
      $aref_expect = [ qw( ele1 ele2 ele3 ele4 ) ];
      do {
        local *STDOUT;
        local *STDERR;
        my $temp_stdout = "/tmp/unit_tests_legacy_util_tests_${cnt}_stdout}_$$";
        my $temp_stderr = "/tmp/unit_tests_legacy_util_tests_${cnt}_stderr}_$$";
        open(STDOUT, '>', $temp_stdout) || return 0;
        open(STDERR, '>', $temp_stderr) || return 0;

        $aref_computed = append_arrays( $aref_set1, $aref_set2 );
      };
      
      is_deeply( $aref_computed, $aref_expect ,  "append_arrays : test$cnt"    );
      dprint(SUPER, "set1, set2 : " . pretty_print_aref( $aref_set1  ) ." , " . pretty_print_aref( $aref_set2   ) . "\n" );
      dprint(SUPER, "computed: " . pretty_print_aref( $aref_computed ) . "\n" );
      dprint(SUPER, "expected: " . pretty_print_aref( $aref_expect ) . "\n"   );
      $cnt++;
      #-------------------------------------------------------------------------
      $aref_set1   = [ qw( com1 com2 ) ];
      $aref_set2   = [ qw( ) ];
      $aref_expect = [ qw( com1 com2 ) ];
      $aref_computed = append_arrays( $aref_set1, $aref_set2 );
      is_deeply( $aref_computed, $aref_expect ,  "append_arrays : test$cnt"    );
      dprint(SUPER, "set1, set2 : " . pretty_print_aref( $aref_set1  ) ." , " . pretty_print_aref( $aref_set2   ) . "\n" );
      dprint(SUPER, "computed: " . pretty_print_aref( $aref_computed ) . "\n" );
      dprint(SUPER, "expected: " . pretty_print_aref( $aref_expect ) . "\n"   );
      #-------------------------------------------------------------------------
      $cnt++;
      $aref_set1   = [ qw( ) ];
      $aref_set2   = [ qw( com3 com4 ) ];
      $aref_expect = [ qw( com3 com4 ) ];
      $aref_computed = append_arrays( $aref_set1, $aref_set2 );
      is_deeply( $aref_computed, $aref_expect ,  "append_arrays : test$cnt"    );
      dprint(SUPER, "set1, set2 : " . pretty_print_aref( $aref_set1  ) ." , " . pretty_print_aref( $aref_set2   ) . "\n" );
      dprint(SUPER, "computed: " . pretty_print_aref( $aref_computed ) . "\n" );
      #-------------------------------------------------------------------------
      $cnt++;
      $aref_set1   = [ qw( com1 com2) ];
      my (@array )    = ( qw( com3 com4 ) );
      my $string      = 'string';
      $aref_expect = [ qw( com1 com2 com3 com4 string ) ];
      $aref_computed = append_arrays( $aref_set1, @array , $string );
      is_deeply( $aref_computed, $aref_expect ,  "append_arrays : test$cnt"    );
      dprint(SUPER, "set1, set2 : " . pretty_print_aref( $aref_set1  ) ." , " . pretty_print_aref( $aref_set2   ) . "\n" );
      dprint(SUPER, "computed: " . pretty_print_aref( $aref_computed ) . "\n" );
      dprint(SUPER, "expected: " . pretty_print_aref( $aref_expect ) . "\n"   );
      #-------------------------------------------------------------------------
      $cnt++;
      $aref_set1   = [ qw( com1 com2) ];
      my %hash        = ( 'key' => 'value' );
      $string      = 'string';
      $aref_expect = [ qw( com1 com2 string ) ];
      do {
          local *STDOUT;
          local *STDERR;
          my $temp_stdout = "/tmp/unit_tests_legacy_util_tests_${cnt}_stdout_$$";
          my $temp_stderr = "/tmp/unit_tests_legacy_util_tests_${cnt}_stderr_$$";
          open(STDOUT, '>', $temp_stdout) || return 0;
          open(STDERR, '>', $temp_stderr) || return 0;

          $aref_computed = append_arrays( $aref_set1, \%hash , $string );
      };
      is_deeply( $aref_computed, $aref_expect ,  "append_arrays : test$cnt"    );
      dprint(SUPER, "set1, set2 : " . pretty_print_aref( $aref_set1  ) ." , " . pretty_print_aref( $aref_set2   ) . "\n" );
      dprint(SUPER, "computed: " . pretty_print_aref( $aref_computed ) . "\n" );
      dprint(SUPER, "expected: " . pretty_print_aref( $aref_expect ) . "\n"   );
      #-------------------------------------------------------------------------
      $cnt++;
      $aref_set1   = [ qw( com1 com2) ];
      %hash        = ( 'key' => 'value' );
      $string      = 'string';
      $aref_expect = [ qw( com1 com2 key value string ) ];
      $aref_computed = append_arrays( $aref_set1, %hash , $string );
      is_deeply( $aref_computed, $aref_expect ,  "append_arrays : test$cnt"    );
      dprint(SUPER, "set1, set2 : " . pretty_print_aref( $aref_set1  ) ." , " . pretty_print_aref( $aref_set2   ) . "\n" );
      dprint(SUPER, "computed: " . pretty_print_aref( $aref_computed ) . "\n" );
      dprint(SUPER, "expected: " . pretty_print_aref( $aref_expect ) . "\n"   );
      #-------------------------------------------------------------------------
}

1;

