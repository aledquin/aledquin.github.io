#!/usr/bin/perl
#
# ScriptName : symlink.pl
# Author     : Alvaro QC
# Created    : June 07 2022
#
#--

use strict;
use warnings FATAL => 'all';

my $dir = shift or die "Usage: $0 DIR\n";

opendir my $dh, $dir or die;

for my $thing (readdir $dh) {
    next if $thing eq '.' or $thing eq '..';
    print $thing;
    my $target = readlink "$dir/$thing";
    if (defined $target) {
        print " -> $target";
    }
    print "\n";
}