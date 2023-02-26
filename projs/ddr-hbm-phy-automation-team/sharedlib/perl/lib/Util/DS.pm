############################################################
#  DS (Data Structure) Utilities.
#  Author : Harsimrat Wadhawan
#  Contains set operations and multimap functions
############################################################
package Util::DS;

use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec::Functions qw( catfile );
use Devel::StackTrace;
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
use Capture::Tiny qw/capture/;
use MIME::Lite;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;

$Data::Dumper::Sortkeys = sub { [ sort keys %{ $_[0] } ] };


use Exporter;

our @ISA = qw(Exporter);

# Symbols (subs or vars) to export by default
our @EXPORT = qw(
  insert_at_key union intersection simple_difference symmetric_difference
);

# Symbols to export by request
our @EXPORT_OK = qw();

#-----------------------------------------------------------------
#  sub 'insert_at_key'
#  Create a multimap by addding multiple elements for a single key in a hash;
#-----------------------------------------------------------------
sub insert_at_key($$$) {

    my $hash  = shift;
    my $key   = shift;
    my $value = shift;

    if ( exists $hash->{$key} ) {
        push @{ $hash->{$key} }, $value;
    }
    else {
        $hash->{$key} = [$value];
    }

}

#-----------------------------------------------------------------
#  sub 'intersection'
#-----------------------------------------------------------------
sub intersection($$) {

   my $one_ref = shift;
   my $two_ref = shift;
   my @a       = @{$one_ref};    # dereferencing and copying each array
   my @b       = @{$two_ref};

   my ( @union, @isect, @diff, %union, %count, %isect );

   @union = @isect = @diff = ();
   %union = %isect = ();
   %count = ();

   foreach my $e ( @a, @b ) { $count{$e}++ }

   foreach my $e ( keys %count ) {
      push( @union, $e );
      if ( $count{$e} == 2 ) {
         push @isect, $e;
      }
      else {
         push @diff, $e;
      }
   }

   return \@isect;

}

#-----------------------------------------------------------------
#  sub 'union'
#-----------------------------------------------------------------
sub union($$) {

   my $one_ref = shift;
   my $two_ref = shift;
   my @a       = @{$one_ref};    # dereferencing and copying each array
   my @b       = @{$two_ref};

   my ( @union, @isect, @diff, %union, %count, %isect );

   @union = @isect = @diff = ();
   %union = %isect = ();
   %count = ();

   foreach my $e ( @a, @b ) { $count{$e}++ }

   foreach my $e ( keys %count ) {
      push( @union, $e );
      if ( $count{$e} == 2 ) {
         push @isect, $e;
      }
      else {
         push @diff, $e;
      }
   }

   return \@union;

}

#-----------------------------------------------------------------
#  sub 'simple_difference'
#-----------------------------------------------------------------
sub simple_difference($$) {

   my $one_ref = shift;
   my $two_ref = shift;
   my @empty_array = ();

   if ( ! Util::Misc::isa_aref($one_ref)) {
       Util::Messaging::eprint("simple_difference: first arg is not an array reference!");
       return \@empty_array;
   }
   if ( ! Util::Misc::isa_aref($two_ref)){
       Util::Messaging::eprint("simple_difference: second arg is not an array reference!");
       return \@empty_array;
   }


   my @a       = @{$one_ref};    # dereferencing and copying each array
   my @b       = @{$two_ref};

   my %seen;               # lookup table
   my @aonly;              # answer

   # build lookup table
   @seen{@a} = ();

   foreach my $item (@b) {
      push( @aonly, $item ) unless exists $seen{$item};
   }

   return \@aonly;

}

#-----------------------------------------------------------------
#  sub 'symmetric_difference'
#-----------------------------------------------------------------
sub symmetric_difference($$) {

   my $one_ref = shift;
   my $two_ref = shift;
   my @a       = @{$one_ref};    # dereferencing and copying each array
   my @b       = @{$two_ref};
   my ( @union, @isect, @diff, %union, %count, %isect );

   @union = @isect = @diff = ();
   %union = %isect = ();
   %count = ();

   foreach my $e ( @a, @b ) { $count{$e}++ }

   foreach my $e ( keys %count ) {
      push( @union, $e );
      if ( $count{$e} == 2 ) {
         push @isect, $e;
      }
      else {
         push @diff, $e;
      }
   }

   return \@diff;

}

################################
# A package must return "TRUE" #
################################

1;
