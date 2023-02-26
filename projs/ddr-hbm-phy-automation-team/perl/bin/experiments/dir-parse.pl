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
use Util::Misc;

our $PROGRAM_NAME = $0; 
#----------------------------------#
use constant TRUE  => 1;
use constant FALSE => 0;
#----------------------------------#
use constant NONE      => 0;
use constant LOW       => 1;
use constant MEDIUM    => 2;
use constant FUNCTIONS => 3;
use constant HIGH      => 4;
use constant SUPER     => 5;
#----------------------------------#
our $DEBUG = SUPER;
#----------------------------------#


BEGIN { header(); } 
   Main();
END { footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {

   my $path = "synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/";
   stream_dir_tree( $path );
   exit(0);
}
############    END Main    ####################
#
#
#
#
###############################################################################
sub stream_dir_tree ($) {
   print_function_header();
   my $base_path = shift;

   my $aref_bom_files;
   my $str= '[^/]+';
   my $regex= '[^/]+';

   #print "\$regex = $regex\n";
   while( $base_path =~ m|^($regex/)| ){
       push( @$aref_bom_files, $1);
       $regex .= "/$str";
       #print "\$regex = $regex\n";
   }
   print Dumper $aref_bom_files;
   return( @$aref_bom_files );
   print_function_footer();
}

sub my($){
   my $base_path = shift;

   my $aref_bom_files;
   my $dir= qr|[^/]+|;
   if( $base_path =~ m|^($dir/)| ){
       push( @$aref_bom_files, $1);
   }
   if( $base_path =~ m|^($dir/$dir/)| ){
       push( @$aref_bom_files, $1);
   }
   if( $base_path =~ m|^($dir/$dir/$dir/)| ){
       push( @$aref_bom_files, $1);
   }

}
