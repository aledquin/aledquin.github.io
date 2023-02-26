#!/depot/perl-5.14.2/bin/perl
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

use lib dirname(abs_path $0) . '/../../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Manifest;

our $PROGRAM_NAME = $0; 
#----------------------------------#
our $DEBUG = SUPER;
#----------------------------------#


BEGIN { header(); } 
   Main();
END { footer(); }

our %globals;

our %global_test_hash;
########  YOUR CODE goes in Main  ##############
sub Main {
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

   my $aref = \@ary;
   print pretty_print_aref_of_arefs( $aref ) ."\n";
   print join(",", @{$aref->[1]},@{$aref->[2]} );
   print "\n";
 
exit;
   can_I_write_the_hash( \%global_test_hash );
   print "global_test_hash -----> \n" . pretty_print_href( \%global_test_hash) ."\n";
   print pretty_print_href( \%globals );
   %globals = %{setup_default_configs()};
   print pretty_print_href( \%globals );
   do "../lp54-bom-v1.18.cfg";
   print pretty_print_href( \%globals );

   my %orig_hash = (
      'key1' => 'value1',
      'key2' => 'value2',
      'key3' => 'value3',
   );
   print Dumper \%orig_hash;
   my_random_sub( \%orig_hash );

   exit(0);
}
############    END Main    ####################
#
#
#
#
###############################################################################
sub   can_I_write_the_hash($){
   my $href_globals = shift;

   print "href_globals -----> \n" . pretty_print_href( $href_globals) ."\n";
   print "global_test_hash -----> \n" . pretty_print_href( \%global_test_hash) ."\n";
   <STDIN>;
   $href_globals->{test1} = "val1";
   print "href_globals -----> \n" . pretty_print_href( $href_globals) ."\n";
   print "global_test_hash -----> \n" . pretty_print_href( \%global_test_hash) ."\n";
}

sub my_random_sub ($) {
   print_function_header();
   my $href = shift;
   my %hash_new;
   %hash_new = %$href;

   iprint("Let's check \%hash_new...\n");
   print Dumper \%hash_new;
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
