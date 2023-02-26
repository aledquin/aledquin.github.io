#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;

use Cwd;
use Carp;
use Pod::Usage;
use File::Spec::Functions qw/catfile/;
use Devel::StackTrace;
use File::Basename;
use Getopt::Std;
use Cwd;
use Term::ANSIColor;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use Data::Dumper; 
use Excel::Writer::XLSX;
use List::Util qw(min max);
use List::Util qw(first);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11'; 
#--------------------------------------------------------------------#


BEGIN {
    our $AUTHOR='bhuvanc, juliano, ljames';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
   Main();
END { 
    local $?;   # to prevent the exit() status from getting modified
    footer();
    write_stdout_log( $LOGFILENAME );
}

######################################### Main function ############################################
##no critic qw(ControlStructures::ProhibitMutatingListFunctions)
sub Main {

    my %options   = ();
    my %defaults  = ();
    my @required  = qw/REQUIRED_ARGUMENTS/;
    my @orig_argv = @ARGV; # keep this here cause GetOpts modifies ARGV
    
    my $error = process_cmd_line_args( \%options, \%defaults, \@required ); 

    unless( $DEBUG || $options{'nousage'}) {
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_argv);
    }
    viprint(LOW, "\@orig_argv is '@orig_argv'\n");
    viprint(LOW, "\@ARGV is '@ARGV'\n");
    my @crrs     = @ARGV;
    my $crrCount = @crrs;
    # CRR check and split based on product lines
    my %top;
    foreach my $crr (@crrs){
        chomp($crr);
        viprint(LOW, "\$crr is $crr\n");
        #$crr =~ s/\#.*//g;
        my ($product) = ($crr =~ m|/depot/products/([0-9a-z_\-\/]+)/project/.*_crr.txt|i);
        if (!defined($product) || $product eq ""){
            eprint( "Product name is empty. Invalid CRR!: \n\t'$crr'!\n" ); 
            next; 
        }
        if ($product =~ /\// ){
            $product = (split(/\//,$product))[1]; 
        }
        unless( "$crr" ~~ @{$top{$product}} ){
            push(@{$top{$product}},$crr); 
        }
    }
    foreach my $prod (keys(%top)) {
        my (@versions, @allMacros, @allViews, @allIDs); 
        my (%dateUser, %view_hash, %crr_hash, %updated_hash, %theVersions, %theMacros, %theCRR);
        #my @pruneMacs = ("clamp","decap","diode");
        my @pruneMacs;
        foreach my $crr (@{$top{$prod}}) {
            #$crr =~ s/\#.*//g;
            my $file; 
            my $uniqID;
            my @filelog;
            if ( $main::TESTMODE ){
                iprint("TESTMODE: p4 filelog $crr\n");
            }else{
                my ($stdout_err, $p4_status) = run_system_cmd("p4 filelog $crr");
                @filelog = split(/\n/, $stdout_err);

            }
            map{chomp $_}@filelog;
            if($crr !~ /\#([0-9]+)/ ){
                ($file,@filelog) = @filelog; 
            }else{ 
                ($file, @filelog) = @filelog[0,1]; 
            }
            my ($product, $project, $vcrel, $type, $release) = ($file =~ m|/depot/products/([0-9a-z_\-\/]+)/project/([0-9a-z_\-\.]+)/ckt/vcrel/([0-9a-z\.\-_]+)/(.*)_release_([a-z0-9_\-\.]+)_crr.txt|i);
            if(!$product || !$project || !$vcrel || !$release || !$type) { eprint( "Not a valid crr file: \t'$crr'\n" ); next; }
            
            if($crr !~ /\#([0-9]+)/ ){ 
                $uniqID = "${project}_BC_${vcrel}_BC_${release}_BC_0_BC_${type}"; 
            }else{ 
                $uniqID = "${project}_BC_${vcrel}_BC_${release}_BC_1_BC_${type}"; 
            }
            $theCRR{$uniqID} = $crr;
            foreach my $log (@filelog) {
                my %views;
                my ($version,$date,$user) = ($log =~ /\.\.\.\s\#([0-9]+)\s.*\son\s([0-9\/]+)\sby\s([a-z]+)\@.*/i);
                next if($version !~ /\d+/ );
                $dateUser{$uniqID}{$version}{date} = "$date";
                $dateUser{$uniqID}{$version}{user} = "$user";
                my @contents; 
                if ( $main::TESTMODE) {
                    iprint("TESTMODE: p4 print ${file}#${version} | grep -v \"^#\" | grep -v $crr \n");
                }else{
                    @contents = `p4 print ${file}#${version} | grep -v "^#" | grep -v $crr`;
                }

                @contents = grep {$_ =~ /\/macro\//} @contents;
                my $prevVersion = $version-1;
                if($version != 1 && $crr !~ /\#([0-9]+)/) { 
                    my ($changed, $added, $removed) = p4diff("$file#${version}","$file#${prevVersion}",\@pruneMacs); ## Make the p4 diff testable
                    $updated_hash{$uniqID}{$version} = getModified($uniqID,$version,$changed,$added,$removed);
                }
                unless("$version" ~~ @versions ){ 
                    push(@versions,$version); 
                }
                unless("$version" ~~ @{$theVersions{$uniqID}} ){ 
                    push (@{$theVersions{$uniqID}},$version); 
                }
                foreach my $eachLine (@contents) {
                    viprint(CRAZY, "\$eachLine of \@contents = '$eachLine'\n");
                    chomp($eachLine);
                    my $line = $eachLine; my(@viewChanged, @viewAdded, @viewRemoved); 
                    next if($line eq "" || $line !~ /\/macro\//);
                    $line =~ s/p4 sync \-f\s//g;
                    my ($mac,$view) = ($line =~ m/\/\/depot.*\/rel\/([a-z0-9\-_\.]+)\/.*\/macro\/([a-z0-9\-_\.]+)/i);
                    next if ($mac eq "" || $view =~ /\.log/ || isPruneMac($mac,\@pruneMacs));
                    unless("$mac" ~~ @allMacros) { push(@allMacros,$mac); }
                    unless("$mac" ~~ @{$theMacros{$uniqID}} ) { push(@{$theMacros{$uniqID}},$mac); }
                    if($view =~ /pincheck/i) { $view = "pincheck"; }
                    if($view =~ /lefdiff/i) { $view = "lefdiff"; }
                    if($view =~ /ctl/i) { $view = "atpg"; }
                    if($view =~ /.docx|\.pdf/i) { $view = "doc"; }
                    unless ("$view" ~~ @{$crr_hash{$uniqID}{$version}{$mac}{arr}}) { push(@{$crr_hash{$uniqID}{$version}{$mac}{arr}},$view); }
                    my @macCount = grep{/$mac/} @contents ;
                    if(!$crr_hash{$uniqID}{$version}{$mac}{count}) {  $crr_hash{$uniqID}{$version}{$mac}{count} = (@macCount) };
                    unless ("$view" ~~ @allViews) { push(@allViews,$view); }
                    $view_hash{$uniqID}{$version}{$mac}{$view} = grep{/$view/i} @macCount;     
                }
            }
            if(!$crr_hash{$uniqID} || !@allMacros) { 
                eprint( "Data could not be harvested for CRR: \n\t'$crr'\n" .
                        "Invalid data or incorrect locations for views in CRR\n" );
                next;
            }
            push(@allIDs,$uniqID);
        }
        my $reportName;
        if($crrCount != 1){ 
            $reportName = "${prod}_crr_analysis.xlsx"; 
        }else{
            my($projNum, $type, $rel) = ($top{$prod}[0] =~ m|/depot/products/[0-9a-z_\-\/]+/project/([0-9a-z]{4})\-.*/(.*)_release_([a-z0-9_\-\.]+)_crr.txt|i);
            $reportName = "CRR_XRay-${type}-${projNum}-${rel}.xlsx"; 
        }
        my $theReport  = Excel::Writer::XLSX->new("$reportName");
        my $summSheet  = $theReport->add_worksheet("${prod}_Summary");
        $summSheet->freeze_panes(3,0);
        my $vSheet     = $theReport->add_worksheet("${prod}_detail_data");
        $vSheet->freeze_panes(3,0);
        my $boldFormat = $theReport->add_format(
            align  => 'center',
            valign => 'center',
        );
        my $centerFormat = $theReport->add_format(
            align  => 'center',
            valign => 'center',
        );
        my $align90 = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            rotation => 90,
        );
        
        my $diffFormat = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            bg_color  => '#FFC9FF',
        );
        my $fileCountColor = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            bg_color  => '#FFCC99',
            size => '14',
        );
        my $changedColor = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            bg_color  => '#8DB4E2',
            size => '14',
        );
        my $addedColor = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            bg_color  => '#CAD999',
            size => '14',
        );
        my $removedColor = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            bg_color  => '#E6B8B7',
            size => '14',
        );
        my $countColor = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            bg_color  => '#D9D9D9',
        );
        my $summHeaderColor = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            bg_color  => '#C6EFCE',
            size => '14',
        );
        my $relGradeColor = $theReport->add_format(
            align  => 'center',
            valign => 'center',
            bg_color  => '#FFCC99',
        );


        my $alignLeft = $theReport->add_format();

        $boldFormat->set_border();
        $centerFormat->set_border();
        $align90->set_border();
        $alignLeft->set_border();
        $fileCountColor->set_border();
        $changedColor->set_border();
        $addedColor->set_border();
        $removedColor->set_border();
        $diffFormat->set_border();
        $summHeaderColor->set_border();
        $relGradeColor->set_border();

        $boldFormat->set_bold();
        $align90->set_bold();
        $changedColor->set_bold();
        $addedColor->set_bold();
        $removedColor->set_bold();
        $summHeaderColor->set_bold();
        $relGradeColor->set_bold();



        my $max = @versions;
        my $totMacs = @allMacros;
        my $rowCount =0; my $colCount = 0;
        #print "tot $totMacs\n";exit;

        $summSheet->autofilter(2,0,2,$max+4);
        $vSheet->autofilter(2,0,2,4*$totMacs+12);
        $vSheet->merge_range($rowCount,$colCount+0,$rowCount+1,$colCount+0,"Product",$boldFormat);
        $vSheet->merge_range($rowCount,$colCount+1,$rowCount+1,$colCount+1,"Project",$boldFormat);
        $vSheet->merge_range($rowCount,$colCount+2,$rowCount+1,$colCount+2,"VC Rel",$boldFormat);
        $vSheet->merge_range($rowCount,$colCount+3,$rowCount+1,$colCount+3,"Release",$boldFormat);        
        $vSheet->merge_range($rowCount,$colCount+4,$rowCount+1,$colCount+4,"CRR Version",$boldFormat);
        $vSheet->merge_range($rowCount,$colCount+5,$rowCount+1,$colCount+5,"Date",$boldFormat);
        $vSheet->merge_range($rowCount,$colCount+6,$rowCount+1,$colCount+6,"Views",$boldFormat);
        if($totMacs!=1) {
            $vSheet->merge_range($rowCount,$colCount+7,  $rowCount,1*$totMacs+6,"File Count",$fileCountColor);
            $vSheet->merge_range($rowCount,1*$totMacs+8, $rowCount,2*$totMacs+7,"Changed",$changedColor);
            $vSheet->merge_range($rowCount,2*$totMacs+9, $rowCount,3*$totMacs+8,"Added",$addedColor);
            $vSheet->merge_range($rowCount,3*$totMacs+10,$rowCount,4*$totMacs+9,"Removed",$removedColor);

            $vSheet->set_column($colCount+7  ,1*$totMacs+6,undef,undef,1,1);
            $vSheet->set_column(1*$totMacs+8 ,2*$totMacs+7,undef,undef,1,1);
            $vSheet->set_column(2*$totMacs+9 ,3*$totMacs+8,undef,undef,1,1);
            $vSheet->set_column(3*$totMacs+10,4*$totMacs+9,undef,undef,1,1);
        } else {
            $vSheet->write($rowCount,1*$totMacs+6, "File Count",$fileCountColor);
            $vSheet->write($rowCount,1*$totMacs+8, "Changed",$changedColor);
            $vSheet->write($rowCount,2*$totMacs+9, "Added",$addedColor);
            $vSheet->write($rowCount,3*$totMacs+10,"Removed",$removedColor);
        }
        $vSheet->merge_range($rowCount,1*$totMacs+7,$rowCount+1,1*$totMacs+7,"File Count",$align90);        
        $vSheet->merge_range($rowCount,2*$totMacs+8,$rowCount+1,2*$totMacs+8,"Changed",$align90);
        $vSheet->merge_range($rowCount,3*$totMacs+9,$rowCount+1,3*$totMacs+9,"Added",$align90);
        $vSheet->merge_range($rowCount,4*$totMacs+10,$rowCount+1,4*$totMacs+10,"Removed",$align90);
        
        $vSheet->merge_range($rowCount,4*$totMacs+11,$rowCount+1,4*$totMacs+11,"Rel Grade",$boldFormat);
        $vSheet->merge_range($rowCount,4*$totMacs+12,$rowCount+1,4*$totMacs+12,"CRR",$boldFormat);

        $vSheet->set_column($rowCount, 1*$totMacs+7,5);
        $vSheet->set_column($rowCount, 2*$totMacs+8,5);
        $vSheet->set_column($rowCount, 3*$totMacs+9,5);
        $vSheet->set_column($rowCount, 4*$totMacs+10,5);

        $rowCount++;

        $summSheet->write($rowCount,$colCount , "Product",$summHeaderColor);
        $summSheet->write($rowCount,$colCount+1,"Project",$summHeaderColor);
        $summSheet->write($rowCount,$colCount+2,"VC Rel",$summHeaderColor);
        $summSheet->write($rowCount,$colCount+3,"Release",$summHeaderColor);
        $summSheet->write($rowCount,$colCount+4,"Macros",$summHeaderColor);
        if($max!=1) { $summSheet->merge_range($rowCount-1,$colCount+5,$rowCount-1,$colCount+$max+4,"CRR Version",$summHeaderColor); }
        else { $summSheet->write($rowCount-1,$colCount+5,"CRR Version",$summHeaderColor); }

        my $i = 5; foreach my $ver (sort {$a <=> $b} @versions) { $summSheet->write($rowCount, $colCount+$i, "$ver", $summHeaderColor); $i++; }

        my $tempCount = 7;
        foreach my $macro (@allMacros) {
            viprint(CRAZY, "\$macro of \@allMacros = '$macro'\n");
            my ($tempMac) = ($macro =~ /dwc_ddrphy(\w+)/i);
            $tempMac =~ s/^_//ig;
            if($tempMac ne '') { 
                $vSheet->write($rowCount,$colCount+$tempCount,"$tempMac", $align90); #fileCount
                $vSheet->write($rowCount,$colCount+1*$totMacs+$tempCount+1,"$tempMac", $align90); #changed
                $vSheet->write($rowCount,$colCount+2*$totMacs+$tempCount+2,"$tempMac", $align90); #added 
                $vSheet->write($rowCount,$colCount+3*$totMacs+$tempCount+3,"$tempMac", $align90); #removed

                $vSheet->write($rowCount, 1*$totMacs+7, '',$countColor);
                $vSheet->write($rowCount, 2*$totMacs+8, '',$countColor);
                $vSheet->write($rowCount, 3*$totMacs+9, '',$countColor);
                $vSheet->write($rowCount, 4*$totMacs+10,'',$countColor);
                
            }
            else { 
                $vSheet->write($rowCount,$colCount+$tempCount,"$macro", $align90); 
                $vSheet->write($rowCount,$colCount+1*$totMacs+$tempCount+1,"$macro", $align90);
                $vSheet->write($rowCount,$colCount+2*$totMacs+$tempCount+2,"$macro", $align90);
                $vSheet->write($rowCount,$colCount+3*$totMacs+$tempCount+3,"$macro", $align90);

                $vSheet->write($rowCount, 1*$totMacs+7, '',$countColor);
                $vSheet->write($rowCount, 2*$totMacs+8, '',$countColor);
                $vSheet->write($rowCount, 3*$totMacs+9, '',$countColor);
                $vSheet->write($rowCount, 4*$totMacs+10,'',$countColor);
            }
            $tempCount++;
        }
        $rowCount = $rowCount+2;
        my $version_row = 3;  my $idc = 1;
        foreach my $id (@allIDs) {
            my($product,$project,$vcrel,$release,$isVer) = ($prod,split("_BC_",$id)); my %verTotal;
            foreach my $macro (@{$theMacros{$id}}) {
                my $verPos = 1;
                foreach my $version (sort {$a <=> $b} @versions) {
                    $summSheet->write($version_row,$colCount , "$product",$centerFormat);
                    $summSheet->write($version_row,$colCount+1,"$project",$centerFormat);
                    $summSheet->write($version_row,$colCount+2,"$vcrel",$centerFormat);
                    $summSheet->write($version_row,$colCount+3,"$release",$centerFormat);
                    $summSheet->write($version_row,$colCount+4,"$macro",$alignLeft);
                    if(exists ($crr_hash{$id}{$version}{$macro}{count})) { 
                        $summSheet->write($version_row,$colCount+$verPos+4,"$crr_hash{$id}{$version}{$macro}{count}",$centerFormat); 
                    }
                    else { 
                        $summSheet->write($version_row,$colCount+$verPos+4,"-",$centerFormat); 
                    }
                    $verTotal{$id}{$version} = $verTotal{$id}{$version} + $crr_hash{$id}{$version}{$macro}{count};
                    $verPos++;
                }
                $version_row++;
            }
            my $verPos = 1;
            foreach my $verTot (sort {$a <=> $b} keys($verTotal{$id})) {
                $summSheet->write($version_row,$colCount , "$product",$countColor);
                $summSheet->write($version_row,$colCount+1,"$project",$countColor);
                $summSheet->write($version_row,$colCount+2,"$vcrel",$countColor);
                $summSheet->write($version_row,$colCount+3,"$release",$countColor);    
                $summSheet->write($version_row,$colCount+4,"Total",$countColor); 
                $summSheet->write($version_row,$colCount+$verPos+4,$verTotal{$id}{$verTot},$countColor);
                $verPos++;
            }
            $version_row++;
                
        }

        foreach my $id (@allIDs) {
            my($product,$project,$vcrel,$release,$isVer) = ($prod,split("_BC_",$id));
            my $colC = 1; 
            foreach my $version (sort {$b <=> $a} @{$theVersions{$id}}) {
                my $relGrade = 0;my $versionNext = $version - 1; my $totalVerCount = 0;
                foreach my $view (@allViews) {
                    my $tempCount = 5;
                    $vSheet->write($rowCount,$colCount+0,"$product",$centerFormat);#product
                    $vSheet->write($rowCount,$colCount+1,"$project",$centerFormat);#project
                    $vSheet->write($rowCount,$colCount+2,"$vcrel",$centerFormat);#vcrelease
                    $vSheet->write($rowCount,$colCount+3,"$release",$centerFormat);#release
                    $vSheet->write($rowCount,$colCount+4,"$version",$centerFormat); #CRR version 
                    $vSheet->write($rowCount,$colCount+5,"$dateUser{$id}{$version}{date}",$centerFormat); #Date
                    $vSheet->write($rowCount,$colCount+$tempCount+1,"$view",$centerFormat);#View   
                    $vSheet->write($rowCount,$colCount+4*$totMacs+12,"$theCRR{$id}#$version");       
  
                    $vSheet->write($rowCount, 1*$totMacs+7, '',$countColor);
                    $vSheet->write($rowCount, 2*$totMacs+8, '',$countColor);
                    $vSheet->write($rowCount, 3*$totMacs+9, '',$countColor);
                    $vSheet->write($rowCount, 4*$totMacs+10,'',$countColor);
                

                    if($version != 1  && $isVer != 1) { 
                        $vSheet->write($rowCount+$#allViews+1,$colCount+0,"$product",$relGradeColor);#product
                        $vSheet->write($rowCount+$#allViews+1,$colCount+1,"$project",$relGradeColor);#project
                        $vSheet->write($rowCount+$#allViews+1,$colCount+2,"$vcrel",$relGradeColor);#vcrelease
                        $vSheet->write($rowCount+$#allViews+1,$colCount+3,"$release",$relGradeColor);#release
                        $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+1,"Rel Grade",$relGradeColor); 
                        # Rel Grade empty fills                       
                        $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+0*$totMacs+2,"-",$relGradeColor);
                        $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+1*$totMacs+3,"-",$relGradeColor);
                        $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+2*$totMacs+4,"-",$relGradeColor); 
                        $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+3*$totMacs+5,"-",$relGradeColor);

                        $vSheet->write($rowCount+$#allViews+1, 1*$totMacs+7, '',$countColor);
                        $vSheet->write($rowCount+$#allViews+1, 2*$totMacs+8, '',$countColor);
                        $vSheet->write($rowCount+$#allViews+1, 3*$totMacs+9, '',$countColor);
                        $vSheet->write($rowCount+$#allViews+1, 4*$totMacs+10,'',$countColor);
                        #
                    }
                    foreach my $macro (@allMacros) {  #Writing file count, changed, added and removed              
                        if (defined($view_hash{$id}{$version}{$macro}{$view})) { $vSheet->write($rowCount,$colCount+$tempCount+2,"$view_hash{$id}{$version}{$macro}{$view}",$centerFormat); }
                        else { $vSheet->write($rowCount,$colCount+$tempCount+2,"-",$centerFormat); }
                        if (defined($updated_hash{$id}{$version}{$macro}{$view}{changed})) { $vSheet->write($rowCount,$colCount+$tempCount+1*$totMacs+3,"$updated_hash{$id}{$version}{$macro}{$view}{changed}",$diffFormat); }
                        else { $vSheet->write($rowCount,$colCount+$tempCount+1*$totMacs+3,"-",$centerFormat); }
                        if (defined($updated_hash{$id}{$version}{$macro}{$view}{added}))   { $vSheet->write($rowCount,$colCount+$tempCount+2*$totMacs+4,"$updated_hash{$id}{$version}{$macro}{$view}{added}",$diffFormat); }
                        else { $vSheet->write($rowCount,$colCount+$tempCount+2*$totMacs+4,"-",$centerFormat); }
                        if (defined($updated_hash{$id}{$version}{$macro}{$view}{removed})) { $vSheet->write($rowCount,$colCount+$tempCount+3*$totMacs+5,"$updated_hash{$id}{$version}{$macro}{$view}{removed}",$diffFormat); }
                        else { $vSheet->write($rowCount,$colCount+$tempCount+3*$totMacs+5,"-",$centerFormat); }
                        $totalVerCount+=$view_hash{$id}{$version}{$macro}{$view};
                        $relGrade = $relGrade + $updated_hash{$id}{$version}{$macro}{$view}{changed};
                        $relGrade = $relGrade + $updated_hash{$id}{$version}{$macro}{$view}{added};
                        $relGrade = $relGrade + $updated_hash{$id}{$version}{$macro}{$view}{removed};
                        if( $version != 1 && $isVer != 1 ) {
                            # Rel Grade empty fills                       
                            $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+0*$totMacs+2,"-",$relGradeColor);
                            $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+1*$totMacs+3,"-",$relGradeColor);
                            $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+2*$totMacs+4,"-",$relGradeColor); 
                            $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+3*$totMacs+5,"-",$relGradeColor);
                        }
                        $vSheet->write($rowCount, 1*$totMacs+7, '',$countColor);
                        $vSheet->write($rowCount, 2*$totMacs+8, '',$countColor);
                        $vSheet->write($rowCount, 3*$totMacs+9, '',$countColor);
                        $vSheet->write($rowCount, 4*$totMacs+10,'',$countColor);
                        $tempCount++;
                    }
                    $rowCount++;
                }
                if($version != 1 && $isVer != 1 ) {
                    my $percentChange = sprintf('%.1f',($relGrade/$totalVerCount)*100);     
                    $vSheet->write($rowCount,$colCount+4,"$version Vs $versionNext",$relGradeColor);
                    $vSheet->write($rowCount,$colCount+5,"$dateUser{$id}{$version}{date}",$relGradeColor);
                    $vSheet->write($rowCount,$colCount+4*$totMacs+11,"$relGrade \($percentChange\%\)",$relGradeColor); 
                    $vSheet->write($rowCount,$colCount+4*$totMacs+12,"p4 diff2 $theCRR{$id}#${version} $theCRR{$id}#${versionNext}",$relGradeColor);                     
                    $vSheet->write($rowCount, 1*$totMacs+7, '',$countColor);
                    $vSheet->write($rowCount, 2*$totMacs+8, '',$countColor);
                    $vSheet->write($rowCount, 3*$totMacs+9, '',$countColor);
                    $vSheet->write($rowCount, 4*$totMacs+10,'',$countColor);
                } #Rel Grade        
                $rowCount++;
            }
            $rowCount--;
            $idc++;
        }

        $theReport->close;
    }
    exit(0);
} # end Main
##use critic

######################################### Common functions #########################################

#-----------------------------------------------------------------
#  P4 diff two versions
#-----------------------------------------------------------------
##no critic qw(ControlStructures::ProhibitMutatingListFunctions)
#----------------------------------------------------------------
sub p4diff ($$$) {
    my $first = shift;
    my $second = shift;
    my $pruneCells = shift;

    my @diff = `p4 diff2 $first $second | grep -E "\>|\<" | grep -Ev "^\<\ \#|^\>\ \#"`;
    map{chomp $_} @diff;
    @diff = grep {$_ =~ /\/\/depot.*\/rel\/([a-z0-9\-_\.]+)\/.*\/macro\/([a-z0-9\-_\.]+)\//i} @diff;
    foreach my $pcell (@{$pruneCells}) { @diff = grep{$_ !~ /$pcell/} @diff; }
    my @theFirst  = grep{/^\</} @diff;
    my @theSecond = grep{/^\>/} @diff;
    foreach (@theFirst) { 
        s/^\<\s+p4\s+sync\s+\-f\s+//g;
        s/\#.*//g;
    }

    foreach (@theSecond) { 
        s/^\>\s+p4\s+sync\s+\-f\s+//g;
        s/\#.*//g;
    }

    my ($common, $onlyFirst, $onlySecond, $bool_equi) = compare_lists(\@theFirst,\@theSecond);
    return ($common, $onlyFirst, $onlySecond);
}
##use critic

#----------------------------------------------------------------
sub getModified ($$$$$) {
    my $uniqID = shift;
    my $ver = shift;
    my $changed = shift;
    my $added = shift;
    my $removed = shift;
    my %updatedHash;
    
    foreach my $change (@{$changed}) {
        my ($mac, $view) = ($change =~ m/\/\/depot.*\/rel\/([a-z0-9\-_\.]+)\/.*\/macro\/([a-z0-9\-_\.]+)/i);
        $updatedHash{$uniqID}{$ver}{$mac}{$view}{changed}++;
    }

    foreach my $add (@{$added}) {
        my ($mac, $view) = ($add =~ m/\/\/depot.*\/rel\/([a-z0-9\-_\.]+)\/.*\/macro\/([a-z0-9\-_\.]+)/i);
        $updatedHash{$uniqID}{$ver}{$mac}{$view}{added}++;
    }

    foreach my $remove (@{$removed}) {
        my ($mac, $view) = ($remove =~ m/\/\/depot.*\/rel\/([a-z0-9\-_\.]+)\/.*\/macro\/([a-z0-9\-_\.]+)/i);
        $updatedHash{$uniqID}{$ver}{$mac}{$view}{removed}++;
    }
    return $updatedHash{$uniqID}{$ver};
}

#----------------------------------------------------------------
sub isPruneMac ($$) {
    my $mac = shift;
    my $pruneMacs = shift;
    foreach my $pm (@{$pruneMacs}) { 
        if($mac =~ /$pm/i) { 
            return 1; 
        } 
    }
    return 0;
}

#----------------------------------------------------------------
sub process_cmd_line_args($$$){
    my $href_opts     = shift;
    my $href_defaults = shift;
    my $aref_required = shift;

    my $success = GetOptions($href_opts 
        , 'nousage'
        , 'debug=i' 
        , 'testmode' 
        , 'verbosity=i' 
        , 'help'
    );
    if( ! $success || $href_opts->{'help'} ){
        pod2usage(0);
    }

    #------------------------------------------------------------
    # Make sure there are no missing REQUIRED arguments
    my $have_required = 1;
    foreach my $argname ( @{$aref_required} ){
        next if $argname eq "REQUIRED_ARGUMENTS";
        unless( defined $href_opts->{"$argname"} &&
                 exists $href_opts->{"$argname"}  ){
            $have_required = 0;
            eprint( "Missing Required Argument -$argname\n" );
        }
    }
    if ( ! $have_required ){
        dprint(LOW, "do not have required!");
        pod2usage(0);
        return(0);
    }

    #------------------------------------------------------------
    # Set defaults
    foreach my $argname ( keys( %{$href_defaults} ) ){
        $href_opts->{"$argname"} = $href_defaults->{"$argname"}
            unless( defined $href_opts->{"$argname"} &&
                    exists $href_opts->{"$argname"}  );
    }

   $main::DEBUG     = $href_opts->{'debug'}     if( defined $href_opts->{'debug'} );
   $main::VERBOSITY = $href_opts->{'verbosity'} if( defined $href_opts->{'verbosity'} );
   $main::TESTMODE  = $href_opts->{'testmode'}  if( defined $href_opts->{'testmode'} );

   return(0); ## success
}


__END__

=pod

=head1 SYNOPSIS

    ScriptPath/crr_X-ray.pl <> \
    [-debug <number>\]
    [-nousage \]
    [-testmode \]
    [-verbosity <number> \]
    [-h,-help]

This script is designed...

=head1 NAME

crr_X-ray.pl

=head1 VERSION

2022ww19

=head1 OPTIONS

'Detailed description of each of the command-line options taken by the program'

=head2 ARGS

=over 8

=item B<-testmode> Enable test mode

=item B<-debug> Set debug level

=item B<-v> Verbosity level

=item B<-h> Print this help message

=back

=cut


