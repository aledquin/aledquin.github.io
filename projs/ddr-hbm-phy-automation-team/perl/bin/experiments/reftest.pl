#!/depot/perl-5.14.2/bin/perl
#!/depot/perl-5.20.2/bin/perl

#use strict;
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use Data::Dumper;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );

use lib dirname(abs_path $0) . '/../../lib/';
use Util::Misc;
use Util::CommonHeader;
use Util::Messaging;

our $DIRNAME = dirname(abs_path $0);
our $PROGRAM_NAME = $0; 
our $AUTHOR_NAME  = 'Patrick Juliano'; 
#----------------------------------#
our $DEBUG = SUPER;
#----------------------------------#


BEGIN { header(); } 
   Main();
END { footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {

 
   test_ref_behavior();

   exit(0);
}
############    END Main    ####################


sub test_ref_behavior ($) {
   print_function_header();

   my $string='string test';
   my $sref  =\$string;
   my $aref  = [];
   my @array = qw( h e l l o );
   my @emptyarray = ();
   my $href  = {};
   my %hash  => { 'wave' => 'hi' };
   
   my $msg_ref = ref $sref;
   iprint("SREF msg_ref='$msg_ref'!\n");
   if( isa_scalar( $sref ) ){
      hprint( "'\$sref' is a SCALAR.\n" );
   }
   my $msg_ref = ref $string;
   iprint("STRING msg_ref='$msg_ref'!\n");

   if( isa_scalar( $string ) ){
      hprint( "'\$string' is a SCALAR.\n" );
   }
   my $msg_ref = ref \$aref;
   iprint("Ref to an AREF msg_ref='$msg_ref'!\n");
   my $msg_ref = ref $aref;
   iprint("AREF msg_ref='$msg_ref'!\n");
   my $msg_ref = ref \@emptyarray;
   iprint("Empty ARRAY msg_ref='$msg_ref'!\n");
   my $msg_ref = ref @array;
   iprint("ARRAY msg_ref='$msg_ref'!\n");

   my $msg_ref = ref \$href;
   iprint("Ref to an HREF msg_ref='$msg_ref'!\n");
   my $msg_ref = ref $href;
   iprint("HREF msg_ref='$msg_ref'!\n");
   my $msg_ref = ref %hash;
   iprint("HASH msg_ref='$msg_ref'!\n");


   print "\n\n\n\n";
   print "-I- String tests : (1) declared (2) content added \n";
   my $string;
   print "my \$string='$string';\n";
   if( defined $string ){ print "string defined='$string'\n"; }else{ print "\$string undefined\n";}
   my $string='';
   print "my \$string='';\n";
   if( defined $string ){ print "string defined='$string'\n"; }else{ print "\$string undefined\n";}

   #print "my ". $$string. "='';\n";
    $string='clever pj';
   my $test = 'string';
   print "my clever test='". ${$test}. "';\n";
   
   if( defined $hash{'invalid key'} ){
      print "hash using invalid key is defined.\n";
   }else{
      print "hash using invalid key is not defined.\n";
   }
   print_function_footer();
}
