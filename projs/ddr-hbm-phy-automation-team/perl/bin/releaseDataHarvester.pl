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
use Data::Dumper; 
use Excel::Writer::XLSX;
use List::Util qw(min max);
use lib dirname(abs_path $0) . '/../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

our $PROGRAM_NAME = $0; 
#----------------------------------#
our $DEBUG     = SUPER;
our $VERBOSITY = NONE;
#----------------------------------#
our $PROGRAM_NAME = basename($0);
our $VERSION      = '1.0';

BEGIN { header(); }

Main();

END { footer(); }



######################################### Main function ############################################
sub Main { 
	  utils__script_usage_statistics( abs_path($PROGRAM_NAME), $VERSION );
    #my $crr = $ARGV[0];
    my @crrs = @ARGV;
    # CRR check and split based on product lines
    my %top;
    foreach my $crr (@crrs) {
        chomp($crr);
        $crr =~ s/#.*//g;
        my ($product) = ($crr =~ m|/depot/products/([0-9a-z]+)/project/.*_crr.txt|i);
        if ($product eq "") { eprint "Invalid CRR $crr!"; next; }
        unless("$crr" ~~ @{$top{$product}} ) { push(@{$top{$product}},$crr); }
    }
    foreach my $prod (keys(%top)) {
        my (@versions, @allMacros, @allViews, @allIDs); 
        my (%dateUser, %view_hash, %crr_hash, %updated_hash, %theVersions, %theMacros, %theCRR);
        my @pruneMacs = ("clamp","decap","utility","diode");
        foreach my $crr (@{$top{$prod}}) {
            $crr =~ s/\#.*//g;
            my @filelog = `p4 filelog $crr`; #update this to use runsystemcmd
            map{chomp $_}@filelog;
            my $file; ($file,@filelog) = @filelog;
            my ($product, $project, $vcrel, $release) = ($file =~ m|/depot/products/([0-9a-z]+)/project/([0-9a-z_\-\.]+)/ckt/vcrel/([0-9a-z\.\-_]+)/.*_release_([a-z0-9_\-\.]+)_crr.txt|i);
            if(!$product || !$project || !$vcrel || !$release) { eprint("Not a valid crr file!"); exit; }
            my $uniqID = "${project}_BC_${vcrel}_BC_${release}";
            $theCRR{$uniqID} = $crr;
            foreach my $log (@filelog) {
                my %views;
                my ($version,$date,$user) = ($log =~ /\.\.\.\s\#([0-9]+)\s.*\son\s([0-9\/]+)\sby\s([a-z]+)\@.*/i);
                next if($version !~ /\d+/ );
                $dateUser{$uniqID}{$version}{date} = "$date";
                $dateUser{$uniqID}{$version}{user} = "$user";
                my @contents = `p4 print ${file}#${version} | grep -v "^#" | grep -v $crr`;
                @contents = grep {$_ =~ /\/macro\//}@contents;
                my $prevVersion = $version-1;
                unless($version == 1) { 
                    my ($changed, $added, $removed) = p4diff("$file#${version}","$file#${prevVersion}",\@pruneMacs); ## Make the p4 diff testable
                    $updated_hash{$uniqID}{$version} = getModified($uniqID,$version,$changed,$added,$removed);
                }
                unless("$version" ~~ @versions) { push(@versions,$version); }
                unless("$version" ~~ @{$theVersions{$uniqID}}) { push (@{theVersions{$uniqID}},$version); }
                foreach my $eachLine (@contents) {
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
                    my @macCount = grep(/$mac/, @contents);
                    if(!$crr_hash{$uniqID}{$version}{$mac}{count}) {  $crr_hash{$uniqID}{$version}{$mac}{count} = (@macCount) };
                    unless ("$view" ~~ @allViews) { push(@allViews,$view); }
                    $view_hash{$uniqID}{$version}{$mac}{$view} = grep(/$view/i,@macCount);     
                }
            }
            if(!$crr_hash{$uniqID} || !@allMacros) { 
                eprint("Data could not be harvested for $crr");
                eprint("Invalid data or incorrect locations for views in CRR");
                next;
            }
            push(@allIDs,$uniqID);
        }
        my $reportName = "crr_data_$prod.xlsx";
        my $theReport  = Excel::Writer::XLSX->new("$reportName");
        my $summSheet  = $theReport->add_worksheet("${prod}_Summary");
        my $vSheet     = $theReport->add_worksheet("${prod}_detail_data");
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



        my $max = max @versions;
        my $totMacs = @allMacros;
        my $rowCount =0; my $colCount = 0;
        #print "tot $totMacs\n";exit;
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
        } else {
            $vSheet->write($rowCount,1*$totMacs+6, "File Count",$fileCountColor);
            $vSheet->write($rowCount,1*$totMacs+8, "Changed",$changedColor);
            $vSheet->write($rowCount,2*$totMacs+9, "Added",$addedColor);
            $vSheet->write($rowCount,3*$totMacs+10,"Removed",$removedColor);
        }
        $vSheet->set_column($rowCount, 1*$totMacs+7,5);
        $vSheet->set_column($rowCount, 2*$totMacs+8,5);
        $vSheet->set_column($rowCount, 3*$totMacs+9,5);

        $vSheet->write($rowCount, 1*$totMacs+7,'',$countColor);
        $vSheet->write($rowCount, 2*$totMacs+8,'',$countColor);
        $vSheet->write($rowCount, 3*$totMacs+9,'',$countColor);

        $vSheet->merge_range($rowCount,4*$totMacs+10,$rowCount+1,4*$totMacs+10,"Rel Grade",$boldFormat);
        $vSheet->merge_range($rowCount,4*$totMacs+11,$rowCount+1,4*$totMacs+11,"CRR",$boldFormat);
        
        $rowCount++;

        $summSheet->write($rowCount,$colCount , "Product",$summHeaderColor);
        $summSheet->write($rowCount,$colCount+1,"Project",$summHeaderColor);
        $summSheet->write($rowCount,$colCount+2,"VC Rel",$summHeaderColor);
        $summSheet->write($rowCount,$colCount+3,"Release",$summHeaderColor);
        $summSheet->write($rowCount,$colCount+4,"Macros",$summHeaderColor);
        if($max!=1) { $summSheet->merge_range($rowCount-1,$colCount+5,$rowCount-1,$colCount+$max+4,"Versions",$summHeaderColor); }
        else { $summSheet->write($rowCount-1,$colCount+5,"Versions",$summHeaderColor); }

        my $i = 5; foreach my $ver (sort {$a <=> $b} @versions) { $summSheet->write($rowCount, $colCount+$i, "$ver", $summHeaderColor); $i++; }


        my $tempCount = 7;
        foreach my $macro (@allMacros) {
            my ($tempMac) = ($macro =~ /dwc_ddrphy(\w+)/i);
            $tempMac =~ s/^_//ig;
            if($tempMac ne '') { 
                $vSheet->write($rowCount,$colCount+$tempCount,"$tempMac", $align90); #fileCount
                $vSheet->write($rowCount,$colCount+1*$totMacs+$tempCount+1,"$tempMac", $align90); #changed
                $vSheet->write($rowCount,$colCount+2*$totMacs+$tempCount+2,"$tempMac", $align90); #added 
                $vSheet->write($rowCount,$colCount+3*$totMacs+$tempCount+3,"$tempMac", $align90); #removed

                $vSheet->write($rowCount, 1*$totMacs+7,'',$countColor);
                $vSheet->write($rowCount, 2*$totMacs+8,'',$countColor);
                $vSheet->write($rowCount, 3*$totMacs+9,'',$countColor);
                
            }
            else { 
                $vSheet->write($rowCount,$colCount+$tempCount,"$macro", $align90); 
                $vSheet->write($rowCount,$colCount+1*$totMacs+$tempCount+1,"$macro", $align90);
                $vSheet->write($rowCount,$colCount+2*$totMacs+$tempCount+2,"$macro", $align90);
                $vSheet->write($rowCount,$colCount+3*$totMacs+$tempCount+3,"$macro", $align90);

                $vSheet->write($rowCount, 1*$totMacs+7,'',$countColor);
                $vSheet->write($rowCount, 2*$totMacs+8,'',$countColor);
                $vSheet->write($rowCount, 3*$totMacs+9,'',$countColor);
            }
            $tempCount++;
        }
        $rowCount++;
        my $version_row = 2;  my $idc = 1;
        foreach my $id (@allIDs) {
            my($product,$project,$vcrel,$release) = ($prod,split("_BC_",$id)); my %verTotal;
            foreach my $macro (@{$theMacros{$id}}) {
                foreach my $version (@versions) {                           
                    $summSheet->write($version_row,$colCount , "$product",$centerFormat);
                    $summSheet->write($version_row,$colCount+1,"$project",$centerFormat);
                    $summSheet->write($version_row,$colCount+2,"$vcrel",$centerFormat);
                    $summSheet->write($version_row,$colCount+3,"$release",$centerFormat);
                    $summSheet->write($version_row,$colCount+4,"$macro",$alignLeft);
                    if(exists ($crr_hash{$id}{$version}{$macro}{count})) { 
                        $summSheet->write($version_row,$colCount+$version+4,"$crr_hash{$id}{$version}{$macro}{count}",$centerFormat); 
                    }
                    else { 
                        $summSheet->write($version_row,$colCount+$version+4,"-",$centerFormat); 
                    }
                    $verTotal{$id}{$version} = $verTotal{$id}{$version} + $crr_hash{$id}{$version}{$macro}{count};
                }
                $version_row++;
            }
            foreach my $verTot (keys($verTotal{$id})) {
                $summSheet->write($version_row,$colCount , "$product",$countColor);
                $summSheet->write($version_row,$colCount+1,"$project",$countColor);
                $summSheet->write($version_row,$colCount+2,"$vcrel",$countColor);
                $summSheet->write($version_row,$colCount+3,"$release",$countColor);    
                $summSheet->write($version_row,$colCount+4,"Total",$countColor); 
                $summSheet->write($version_row,$colCount+$verTot+4,$verTotal{$id}{$verTot},$countColor);
            }
            $version_row++;
                
        }


        foreach my $id (@allIDs) {
            my($product,$project,$vcrel,$release) = ($prod,split("_BC_",$id));
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
                    $vSheet->write($rowCount,$colCount+4*$totMacs+11,"$theCRR{$id}#$version");       
  
                    $vSheet->write($rowCount, 1*$totMacs+7,'',$countColor);
                    $vSheet->write($rowCount, 2*$totMacs+8,'',$countColor);
                    $vSheet->write($rowCount, 3*$totMacs+9,'',$countColor);
                

                    if($version != 1) { 
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

                        $vSheet->write($rowCount+$#allViews+1, 1*$totMacs+7,'',$countColor);
                        $vSheet->write($rowCount+$#allViews+1, 2*$totMacs+8,'',$countColor);
                        $vSheet->write($rowCount+$#allViews+1, 3*$totMacs+9,'',$countColor);
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
                        if( $version != 1 ) {
                            # Rel Grade empty fills                       
                            $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+0*$totMacs+2,"-",$relGradeColor);
                            $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+1*$totMacs+3,"-",$relGradeColor);
                            $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+2*$totMacs+4,"-",$relGradeColor); 
                            $vSheet->write($rowCount+$#allViews+1,$colCount+$tempCount+3*$totMacs+5,"-",$relGradeColor);
                        }
                        $vSheet->write($rowCount, 1*$totMacs+7,'',$countColor);
                        $vSheet->write($rowCount, 2*$totMacs+8,'',$countColor);
                        $vSheet->write($rowCount, 3*$totMacs+9,'',$countColor);
                        $tempCount++;
                    }
                    $rowCount++;
                }
                if($version != 1) {
                    my $percentChange = sprintf('%.1f',($relGrade/$totalVerCount)*100);     
                    $vSheet->write($rowCount,$colCount+4,"$version Vs $versionNext",$relGradeColor);
                    $vSheet->write($rowCount,$colCount+5,"$dateUser{$id}{$version}{date}",$relGradeColor);
                    $vSheet->write($rowCount,$colCount+4*$totMacs+10,"$relGrade \($percentChange\%\)",$relGradeColor); 
                    $vSheet->write($rowCount,$colCount+4*$totMacs+11,"p4 diff2 $theCRR{$id}#${version} $theCRR{$id}#${versionNext}",$relGradeColor);                     
                    $vSheet->write($rowCount, 1*$totMacs+7,'',$countColor);
                    $vSheet->write($rowCount, 2*$totMacs+8,'',$countColor);
                    $vSheet->write($rowCount, 3*$totMacs+9,'',$countColor);
                } #Rel Grade        
                $rowCount++;
            }
            $rowCount--;
            $idc++;
        }

        $theReport->close;
    }
}

######################################### Common functions #########################################

#-----------------------------------------------------------------
#  Print Functions 
#-----------------------------------------------------------------
sub iprint ($)  { my $str = shift; print "-I- $str"; }
sub wprint ($)  { my $str = shift; print colored("-W- $str", 'yellow'),"\n"; }
sub eprint ($)  { my $str = shift; print colored("-E- $str", 'red'   ),"\n"; }

#-----------------------------------------------------------------
#  P4 diff two versions
#-----------------------------------------------------------------
sub p4diff ($$$) {
    my $first = shift;
    my $second = shift;
    my $pruneCells = shift;

    my @diff = `p4 diff2 $first $second | grep -E "\>|\<" | grep -Ev "^\<\ \#|^\>\ \#"`;
    map{chomp $_} @diff;
    @diff = grep {$_ =~ /\/\/depot.*\/rel\/([a-z0-9\-_\.]+)\/.*\/macro\/([a-z0-9\-_\.]+)\//i}@diff;
    foreach my $pcell (@{$pruneCells}) { @diff = grep{$_ !~ /$pcell/}@diff; }
    my @theFirst  = grep(/^\</,@diff);
    my @theSecond = grep(/^\>/,@diff);
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
        
    
