#!/depot/perl-5.14.2/bin/perl

use strict;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use Test2::Bundle::More;
use FindBin qw($RealBin $RealScript);

use lib dirname(abs_path $0) . '/../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Set::Scalar;

our $PROGRAM_NAME = $RealScript;
our $VERSION = '1.0';
#----------------------------------#
our $DEBUG     = SUPER;
our $VERBOSITY = NONE;
our $STDOUT_LOG  = undef;       # Log msg to var => OFF
#our $STDOUT_LOG   = EMPTY_STR; # Log msg to var => ON

#----------------------------------#


BEGIN { header(); } 
   Main();
END { write_stdout_log("${PROGRAM_NAME}.log");  footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
   plan(2);
   process_cmd_line_args();

   utils__script_usage_statistics( abs_path($PROGRAM_NAME), $VERSION )
        unless( $DEBUG ); 


   #-------------------------------------------------------------------------
   #  Gather test content
   #-------------------------------------------------------------------------
   my (%tests) = setup_tests(); 

   my $set1         = Set::Scalar->new;
   my $set2         = Set::Scalar->new;
   my $union        = Set::Scalar->new;
   my $intersection = Set::Scalar->new;
   my $difference = Set::Scalar->new;
   $set1->insert(  qw( A B C D E F G   ) );
   $set2->insert(  qw( A B C     F G H ) );
   $union->insert( qw( A B C D E F G H ) );
   $intersection->insert( qw( A B C F G ) );
   $difference->insert( qw( D E ) );
   my $computed_intersection = $set1 * $set2; 
   my $computed_union        = $set1 + $set2; 
   print "set1 | set2:\t $set1 | $set2 \n";
   print "expected intersection:\t $intersection \n";
   print "computed intersection:\t $computed_intersection \n";
   print "expected union:\t\t  $union \n";
   print "computed union:\t\t $computed_union \n";
   my $computed_difference   = $set1 - $set2; 
   print "expected diff set1/set2\t\t  $difference \n";
   print "computed diff set1/set2\t\t  $computed_difference \n";
      $computed_difference   = $set2 - $set1; 
   print "expected diff set2/set1\t\t  $difference \n";
   print "computed diff set2/set1\t\t  $computed_difference \n";
   is_deeply( $computed_union->elements        , $union->elements, "Test Union\n" );
   is_deeply( \($computed_intersection->elements) , \($intersection->elements), "Test Intersection\n" );
   #is_deeply( $computed_difference->elements   , $difference->elements, "Test Difference\n" );
   my @t=$computed_difference->elements; my @tt=$difference->elements;
   my @test1= ( qw(a b c D E) );
   my @test2= ( qw(        E) );
   #is_deeply( \@test1, \@test2, "test1, test2\n" );
   #is_deeply( (qw(a b c D E)) , (qw( H)), "Test Difference\n" );
   #is_deeply( @t, @tt, "Test Difference\n" );
   done_testing();
exit(0);
   #-------------------------------------------------------------------------
   #  Run Tests
   #-------------------------------------------------------------------------
   foreach my $num ( sort keys %tests ){
      #-------------------------------------------------------------------------
      #  Test 'filter_optional_fileSPECS'
      #-------------------------------------------------------------------------
      # $aref_common_new = intersection of (REF, REL)
      # $aref_REF_ONLY   = set difference of (REF, REL)
      my ($aref_common_new, $aref_REF_ONLY) = filter_optional_fileSPECs( $tests{$num}->{REF}, $tests{$num}->{REL} );

      # Test the contents of the 2 sets to verify they were exactly as expected.
      is_deeply( $aref_REF_ONLY, $tests{$num}->{REF_ONLY},  "Test \#$num : check REF ONLY files ..." ); 
      is_deeply( $aref_common_new, $tests{$num}->{COMMON},  "Test \#$num : check COMMON files ..." ); 
      dprint(HIGH, "EXPECTED : common elements : " . pretty_print_aref( $tests{$num}->{COMMON}   ) . "\n" );
      dprint(HIGH, "COMPUTED : common elements : " . pretty_print_aref( $aref_common_new   ) . "\n" );
      #-------------------------------------------------------------------------
   }



   exit(0);
}
############    END Main    ####################
 

#-------------------------------------------------------------------------
#  Setup tests to exercise useful possible state space
#-------------------------------------------------------------------------
sub setup_tests(){

   my( @REF, @REL);
   my %tests;

   (@REF) = (qw( op1 op2 op3 op4 op5 ));
   (@REL) = (qw( op1 op2 op3 op4 op5 ));
   $tests{1} = { 'REF' => [@REF], 'REL' => [@REL], 'REF_ONLY' => [ qw(                     )] , 'COMMON' => [ qw( op1 op2 op3 op4 op5 )] };

   @REF = qw( op1 op2 op3 op4 op5 );
   @REL = qw( op1 op2 op3 op4     );
   $tests{2} = { 'REF' => [@REF], 'REL' => [@REL], 'REF_ONLY' => [ qw(                 op5 )] , 'COMMON' => [ qw( op1 op2 op3 op4     )] };

   @REF = qw( op1 op2 op3 op4     );
   @REL = qw( op1 op2 op3 op4 op5 );
   $tests{3} = { 'REF' => [@REF], 'REL' => [@REL], 'REF_ONLY' => [ qw(                     )] , 'COMMON' => [ qw( op1 op2 op3 op4     )] };

   @REF = qw( op1                 );
   @REL = qw( op1                 );
   $tests{4} = { 'REF' => [@REF], 'REL' => [@REL], 'REF_ONLY' => [ qw(                     )] , 'COMMON' => [ qw( op1                 )] };

   @REF = qw( op1                 );
   @REL = qw(                     );
   $tests{5} = { 'REF' => [@REF], 'REL' => [@REL], 'REF_ONLY' => [ qw( op1                 )] , 'COMMON' => [ qw(                     )] };

   @REF = qw(                     );
   @REL = qw( op1                 );
   $tests{6} = { 'REF' => [@REF], 'REL' => [@REL], 'REF_ONLY' => [ qw(                     )] , 'COMMON' => [ qw(                     )] };

   return( %tests );
} 
 
#-------------------------------------------------------------------------
#  Load filenames from a file and return the AREF of lines. Useful
#  for gathering test content from files.
#-------------------------------------------------------------------------
sub get_fnames_from_file ($) {
   print_function_header();
   my $fname = shift;

   my @lines =  ( split(/\n/, `cat $fname`) );
   foreach my $line ( @lines ){
      dprint(CRAZY, "Fname '$fname' : line : '$line'\n");
   }
   print_function_footer();
   return( \@lines );
}

#-------------------------------------------------------------------------
#  filter_optional_fileSPECs : goal here is to compute 2 "sets":
#  (1) intersection of set 'REF' and set 'REL', which is those elements
#  in both sets, and I name this 'common' (meaning there was a match for
#  each elemeent in the 'common' list)
#  (2) the 2nd 'set' computed is the 'set difference', and is the set
#  of all elements in 'REF' that are not in the 'REL'.  This 2nd
#  will be used to identify all those fileSPECs that were optional and
#  aren't found in the 'REL' so we can write waivers later.
#-------------------------------------------------------------------------
sub filter_optional_fileSPECs($$) {
   print_function_header();
   my $aref_REFfiles = shift;
   my $aref_RELfiles = shift;


   my( $common_aref, $REFOnly_aref, $RELOnly_aref, $list_equiv )= compare_lists( $aref_REFfiles , $aref_RELfiles );

   return( $common_aref, $REFOnly_aref );
   print_function_footer();
}


###############################################################################
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
