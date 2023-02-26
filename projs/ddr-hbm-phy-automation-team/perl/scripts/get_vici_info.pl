#!/depot/perl-5.14.2/bin/perl

use strict;
use Cwd;
use Carp;
use File::Spec::Functions qw/catfile/;
use Devel::StackTrace;
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
use Term::ANSIColor;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use JSON qw( decode_json );
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib/";
use Util::Misc;
use Util::Messaging;

BEGIN { }

	Main();

END { }


######################################### Main function ############################################
sub Main {
    my $vici_url = $ARGV[0];
    if (! defined($vici_url)) {
        eprint("Required argument was not provided.!\n");
        exit(0);
    }

    my ($vici_id) = ($vici_url =~ /\/id\/(\d+)\/page_id/i);
    if ( ! defined($vici_id) ) {
        eprint("Invalid URL: '$vici_url'. Expecting '/id/##/page_id' \n");
        exit(0);
    }

    my $vici_api = "curl http://vici/api/getReleaseData -F \"id=$vici_id\"";
    my @vici_info; 
    my ($stdout, $stderr) = capture{ @vici_info = `$vici_api`;};

    my $decoded = decode_json( @vici_info );

   # print Dumper($decoded);
    #print "\n"; exit;
    $decoded = format_href($decoded);
    
    print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
    foreach my $comp (keys($decoded->{"component"})) {
        my $tcomp = lc($comp);
        my $torient = $decoded->{'component'}{$comp}{'orientation'};
        if($torient ne "") { $torient = "_".lc($torient); }
        print "$tcomp : $torient : $decoded->{'component'}{$comp}{'version'}\n";
    }
    print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
    if(exists $decoded->{"PVT combos"}) {
        foreach my $cornerType (keys($decoded->{"PVT combos"})) {
            print "$cornerType : PVT options : ".join" ",@{$decoded->{"PVT combos"}{$cornerType}},"\n";
        }
    }
    print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n";
    print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
    print "Foundry Metal Option: ", join" ",@{$decoded->{"foundry_stacks"}},"\n";
    print "PHY Metal Option: ", join" ",@{$decoded->{"phy_stacks"}},"\n";
    print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
}


sub format_href ($) {
    my $decoded_json = shift;
    my %formatted;
    
    ## Technology process - phyv, foundry metal and technology process technology_process' => 'foundry_metal_options_used' 'foundry_phy_metal_options'
    $formatted{"foundry_stacks"} = $decoded_json->{"technology_process"}{"foundry_metal_options_used"};
    
    foreach my $hashes (@{$decoded_json->{"technology_process"}{"foundry_phy_metal_options"}}) {
        push(@{$formatted{"phy_stacks"}},$hashes->{"phy_metal_option"});
    }

    #@{$formatted{"phyv_stacks"}} = getPhyvStacks($decoded_json->{'$technology_process'}{'phy_metal_option'});
    $formatted{"technology"} = $decoded_json->{"technology_process"}{"technology"};
    #$formatted{"
    
    ## sub_projects_components - component name { release_version, version_note(orientation) }
    foreach my $href_component (@{$decoded_json->{"sub_projects_components"}}) {
        my $comp = $href_component->{'component'};
        chomp($comp);
        $formatted{"component"}{"$comp"}{"version"} = $href_component->{'release_version'};
        $formatted{"component"}{"$comp"}{"orientation"} = $href_component->{"version_note"};
        chomp($formatted{"component"}{"$comp"}{"version"});
        chomp($formatted{"component"}{"$comp"}{"orientation"});
    }
    
    ## PVT corners - {core_voltage, case, corner_type, temperature, extraction_corner}
    
    foreach my $href_pvt (@{$decoded_json->{"pvt_corners"}}) {
        my $corner_type = $href_pvt->{"corner_type"};
        chomp($corner_type);
        my @pvts = formPvts($href_pvt);
        push(@{$formatted{"PVT combos"}{$corner_type}},@pvts);
    }
    return \%formatted;
}

sub formPvts ($) {
    my $href_pvt = shift;
    chomp(my $voltage = $href_pvt->{"core_voltage"});
    chomp(my $case = $href_pvt->{"case"});
    chomp(my $temp = $href_pvt->{"temperature"});
    chomp(my $corner = $href_pvt->{"extraction_corner"});
    $voltage =~ s/(\.\d+)0+$/$1/;
    $voltage =~ s/\./p/;
    $case = lc($case);
   
    my @pvts;
    my @corners = split(/\,\s+/,$corner);
    my @temps;
    if($temp =~ /\//) { @temps = split(/\s+\/\s+/,$temp); }
    elsif($temp =~ /\,/) { @temps = split(/\,\s+/,$temp); }
    else { push(@temps, $temp); }

    foreach my $cor (@corners) {
        foreach my $temp (@temps) {
            $temp =~ s/\-/n/;
            $temp =~ s/\.0+$//;
            $temp =~ s/(\.\d+)0+$/$1/;
            $temp =~ s/\./p/;
            push(@pvts,"${case}${voltage}v${temp}c_${cor}");
        }
    }
    return @pvts;
    
}

######################################### Common functions #########################################



