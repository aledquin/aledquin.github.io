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
use Util::Excel;
use Util::Messaging;
use Util::Misc;

our $PROGRAM_NAME = $0; 
#----------------------------------#
our $DEBUG = SUPER;
#----------------------------------#


BEGIN { header(); } 
   Main();
END { footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {

   my $hex = purple_shades( 0, 4 );
      $hex = purple_shades( 1, 4 );
      $hex = purple_shades( 2, 4 );
      $hex = purple_shades( 3, 4 );
      $hex = purple_shades( 4, 4 );
      $hex = purple_shades( 5, 4 );
      $hex = blue_shades( 0, 6 );
      $hex = blue_shades( 1, 6 );
      $hex = blue_shades( 2, 6 );
      $hex = blue_shades( 3, 6 );
      $hex = blue_shades( 4, 6 );
      $hex = blue_shades( 5, 6 );
      $hex = blue_shades( 6, 6 );
   exit(0);
}
############    END Main    ####################
#
#
sub purple_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo = 141; my $r_hi = 223;
   my $g_lo =  77; my $g_hi = 222;
   my $b_lo = 179; my $b_hi = 241;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}

sub blue_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo =  87; my $r_hi = 236;
   my $g_lo = 122; my $g_hi = 240;
   my $b_lo = 193; my $b_hi = 248;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}


sub get_hex_for_color_triplet($$$$$$$$){
   my $r_lo = shift; my $r_hi = shift; 
   my $g_lo = shift; my $g_hi = shift; 
   my $b_lo = shift; my $b_hi = shift; 
   my $shade= shift; my $range= shift;

   return( "000000" ) unless( isa_int( $shade) && isa_int( $range ) && int($shade) >= 1 && int($range) >= 1  && $shade <= $range );
   my $r = $r_lo+ int( ($shade-1) * my_interpolate( $r_lo, $r_hi, $range-1) );
   my $g = $g_lo+ int( ($shade-1) * my_interpolate( $g_lo, $g_hi, $range-1) );
   my $b = $b_lo+ int( ($shade-1) * my_interpolate( $b_lo, $b_hi, $range-1) );

   if( $r >255 ){ $r=255; }
   if( $g >255 ){ $g=255; }
   if( $b >255 ){ $b=255; }
   my $dec = sprintf("(r,g,b)=(%3d,%3d,%3d)", $r, $g, $b);
   my $hex = sprintf("%2X%2X%2X", $r, $g, $b);
   dprint(SUPER, "$dec\t hex=($hex)\n" );
   return( $hex );
}

sub my_interpolate($$$){
   my $min = shift;
   my $max = shift;
   my $stp = shift;

   #unless( $min 
   my $val = ($max-$min)/$stp;

   dprint(CRAZY, "[step size => min,max,#parts]=[$val => $min,$max,$stp]\n");

   return( $val );
}
