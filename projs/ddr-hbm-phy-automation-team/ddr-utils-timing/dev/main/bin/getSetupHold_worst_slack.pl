#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );

use Cwd qw( abs_path getcwd );
use Cwd;
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

use Data::Dumper;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = FALSE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || '2022.11'; 



our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
my %constraint;
my %Block;
my %MAP;
my %path;
my ($setup_rpt,$MapFile,$cell_name,$hold_rpt,$verbose,$report_all,$report_pathid,$csv,$html,$opt_help,$debug) = "";
my @filter = "";
my $filter;

BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log($LOGFILENAME);
   footer(); 
}

sub Main() {
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);

   

    ($setup_rpt,$MapFile,$cell_name,$hold_rpt,$filter,$verbose,$report_all,$report_pathid,$csv,$html) = process_cmd_line_args();
    chomp $csv;
	@filter = @$filter;

    get_category();
    $setup_rpt= "WorstSetup";
    $hold_rpt= "WorstHold";
    my $common_rpt = "WorstSetup&Hold.rpt";
    my ($stdout1,$stderr1) = capture {run_system_cmd("rm -rf max_timing.rpt.path min_timing.rpt.path",$VERBOSITY);};
    #my ($dir_list,$stderr2) = capture {run_system_cmd("ls -d $ARGV[0]/*_internal",$VERBOSITY);};
    my @dir_list = glob("$ARGV[0]/*internal");
    my $corner = "";
    foreach my $file1 (@dir_list) {
    #chomp $file1;
        if($file1 =~ /Run_(.*)(_etm|_internal)/) {$corner = $1;}else {$corner = $file1;}
            chk_file($file1,"max_timing.rpt",$corner);
            chk_file($file1,"min_timing.rpt",$corner);
        }

        if (defined $csv) {
            csv_summary("$setup_rpt.csv","max_timing.rpt");
            csv_summary("$hold_rpt.csv","min_timing.rpt");
        }

        if(defined $html) {
            html_summary("$setup_rpt.html","max_timing.rpt");
            html_summary("$hold_rpt.html","min_timing.rpt");
        }

}


sub process_cmd_line_args(){
    my ($setup_rpt,$MapFile,$cell_name,$hold_rpt,$verbose,$report_all,$report_pathid,$csv,$html,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity) = 0;
	my @filter;

    my $success = GetOptions(
                "help|h"         => \$opt_help,
                "setup_rpt=s"    => \$setup_rpt,
                "dryrun!"        => \$opt_dryrun,
                "debug=i"        => \$opt_debug,
                "map=s"          => \$MapFile,
                "cell=s"         => \$cell_name,
                "hold_rpt=s"     => \$hold_rpt,
                "remove=s@"      => \@filter,
                "report_all"     => \$report_all,
                "report_pathid"  => \$report_pathid,
                "csv"            => \$csv,
                "html"           => \$html
	); 

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    return ($setup_rpt,$MapFile,$cell_name,$hold_rpt,\@filter,$verbose,$report_all,$report_pathid,$csv,$html);  
}    

sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

    Usage: getSetupHold_worst_slack.pl [-h|-help]

    -h or -help  this help message
    
    getSetupHold_worst_slack.pl {>>options} 

EOusage
nprint ("$USAGE");
exit;
}    


sub html_summary($$) {
my $report_name = shift;
my $report_type = shift;
my @REPORT = "";
#open(REPORT, ">$report_name") || die "cant write $report_name\n";

push @REPORT,"<!DOCTYPE html>
<html>
<head>
<meta name=\"viewport\" content=\"width=1, initial-scale=1\">
<link rel=\"stylesheet\" href=\"https://code.jquery.com/mobile/1.4.5/jquery.mobile-1.4.5.min.css\">
<script src=\"https://code.jquery.com/jquery-1.11.3.min.js\"></script>
<script src=\"https://code.jquery.com/mobile/1.4.5/jquery.mobile-1.4.5.min.js\"></script>
<style>
table {
 table-layout: fixed;
	font-family: arial, sans-serif;
	border-collapse: collapse;
	width: 100%;
}
td, th {
	border: 1px solid #dddddd;
	text-align: left;
}
table#t01 {
    width: 100%;
}
</style>
</head>
<body>
<div data-role=\"page\" id=\"pageone\">
<div data-role=\"header\">
<h1>$cell_name</h1>
</div>
\n";
my $match = 0;
foreach my $constraint (keys %{$constraint{$report_type}}) {
$match = 0;
foreach my $f (@filter) {
    if($constraint =~ /$f/) {
        $match = 1 ;
   }
}
next if($match == 1);

push @REPORT ,"<table id=\"t01\">
<tr>
<th><font size=\"5\">Endpoint:</font></th>
<th><font size=\"5\">$constraint</font></th>
</tr>
</table>
";
my $max_count = 0;
foreach my $category (sort(keys %MAP)) {
$max_count =0;
my $count = 0;
foreach my $corner (sort(keys %Block)) {
$count = keys %{$Block{$corner}{$constraint}{$category}{$report_type}};
if($count>$max_count){$max_count=$count;}
}
if($max_count>0) {

push @REPORT ,"<div data-role=\"collapsible\" style=\"font-size:100%\">
<h1>
<table>
<tr>
<td>$category</td>
<td>
<table>
";

foreach (uniq {%{$path{$constraint}{$category}{$report_type}}}){
push @REPORT,"<tr><td>$_</td></tr>\n";
}
push @REPORT, "</table>
</td>
</tr>
</table>
</h1>
<table>
<td width=\"15%\">corner Name</td>
";
for(my $i=0;$i<$max_count;$i++) {
if($report_pathid == 1) {push @REPORT,"<td width=\"",85/($max_count*4),"%\">Path Id</td>\n";}
if($i==0) {push @REPORT,"<td width=\"",(85*3)/($max_count*4),"%\">Worst Slack</td>\n";}
else {push @REPORT,"<td width=\"",(85*3)/($max_count*4),"%\">Slack</td>\n";}
}
push @REPORT,"</tr>
<tr>
";


foreach my $corner (sort(keys %Block)) {
next if($corner eq "");
push @REPORT,"<td>$corner</td>\n";
my @slacks; 
my @pathid;
my @slacks_tmp = "";
@slacks = sort  (values %{$Block{$corner}{$constraint}{$category}{$report_type}});
if($report_pathid == 1) {
@slacks_tmp=@slacks;
foreach (keys %{$Block{$corner}{$constraint}{$category}{$report_type}}) {
for(my $i = 0; $i<=$#slacks_tmp; $i++) {
if($Block{$corner}{$constraint}{$category}{$report_type}{$_} eq $slacks_tmp[$i]) {$pathid[$i]=$_;$slacks_tmp[$i]="";}
}
}
}

for(my $i = 0; $i<=$#slacks; $i++) {
if($report_pathid == 1) {push @REPORT,"<td>$pathid[0]</td>\n";}
push @REPORT,"<td>$slacks[0]</td>\n";
}
push @REPORT,"</tr>
";
}

push @REPORT,"</tr>
</table>
</div>
<br><br><br>
</body>
</html>
";


}
}
}
my $status = write_file(\@REPORT,$report_name);
}

sub csv_summary() {
my $report_name = shift;
my $report_type = shift;
my @REPORT;
my $REPORT="";
#open(REPORT, ">$report_name") || die "cant write $report_name\n";

foreach my $constraint (keys %{$constraint{$report_type}}) {
my $match = 0;
if($#filter >1) {
    foreach my $f (@filter) {$match = 1 if($constraint =~ /$f/);}
}
next if($match eq 1);
#push @REPORT,"Report for $constraint\n";
#push @REPORT,"\n---------------------------------------------------------------------------------------------------------------------------------\nCorner Name\t";
$REPORT .= "Report for $constraint\n";
$REPORT .= "\n---------------------------------------------------------------------------------------------------------------------------------\nCorner Name\t";
foreach my $category (sort(keys %MAP)) {
chomp($category);
my $max_count =1;
foreach my $corner (sort(keys %Block)) {
chomp($corner);
my $count = keys %{$Block{$corner}{$constraint}{$category}{$report_type}};
if($count>$max_count){$max_count=$count;}
}
for(my $i=0;$i<$max_count;$i++) {$REPORT.="$category\t"}
}
#push @REPORT,"\n---------------------------------------------------------------------------------------------------------------------------------\n";
$REPORT .= "\n---------------------------------------------------------------------------------------------------------------------------------\n";
foreach my $corner (sort(keys %Block)) {
next if($corner eq "");
$REPORT .= "$corner\t";
foreach my $category (sort(keys %MAP)) {
chomp($category);
#####verbose########
if(defined $verbose) {
$REPORT .= "\tBlock{$corner}{$constraint}{$category}{$report_type}";
}
######################################################
my @slacks; 
my @pathid;
my @slacks_tmp= "";
#my $len = (values %{$Block{$corner}{$constraint}{$category}{$report_type}});
#if($corner =~ /ffg0p825v0c/) { print Dumper(\%{$Block{$corner}});}
@slacks = sort special_sort  (values %{$Block{$corner}{$constraint}{$category}{$report_type}});
if((defined $report_pathid) && ($report_pathid == 1)) {
@slacks_tmp=@slacks;
foreach (keys %{$Block{$corner}{$constraint}{$category}{$report_type}}) {
for(my $i = 0; $i<=$#slacks_tmp; $i++) {
if($Block{$corner}{$constraint}{$category}{$report_type}{$_} eq $slacks_tmp[$i]) {$pathid[$i]=$_;$slacks_tmp[$i]="";}
}
}
}
for(my $i = 0; $i<=$#slacks; $i++) {
if((defined $report_pathid) && ($report_pathid == 1)) {$REPORT .= "Path ID:$pathid[$i], slack:";}
$REPORT .= "$slacks[$i]\t";
if(!(defined $report_all) || ($report_all != 1)) {last;}
}
}

$REPORT .= "\n";
}
$REPORT .= "\n\n";
}

my $status3 = write_file($REPORT,$report_name);

}

sub get_category() {
	$MAP{"deglitch block   "} = "Xsnps_ddl_lcdl_calen";
	$MAP{"calibration block"} = "Xsnps_ddl_lcdl_cal0";
	$MAP{"IOs              "} = "XXdataslice";
	return unless(defined $MapFile);
    #open(MAP_FILE,"<$MapFile") || die "cant open $MapFile\n";
    my @MAP_FILE = read_file("$MapFile");
	foreach my $line (@MAP_FILE) {
		if($line =~ /^(.*)(\s|\t)*(.*)$/) {$MAP{$1} = $3;} else { eprint ("Error: not able to configure for $line");}
		}
	}

sub chk_file($$) {
my $report_name = shift;
my $report_type = shift;
my $corner = shift;
my $constraint;
my $report = $report_type;
my $line;
my @file;
my $file_ref;
my ($startpt,$endpt, $slack,$pathid) = "";
my $flag1 = "";
my %flag;
my %slack_store;
my @raw = Util::Misc::read_file("$report_name/$report_type");
my $raw = join("\n",@raw);
my $header = qr/(\d+\.\d+\s+slack)/msx;
my @chunks = split /Item:\s+\d+/, $raw;
       for my $i (1..@chunks) {
	       chomp($chunks[$i-1]);
		   $chunks[$i-1] =~ s/^\s+//;
            $file[$i-1] =  $chunks[$i-1];
 
			
       }
	       @file = grep { $_ ne ''} @file;
	       #@file = grep { $_  /^\-\-/} @file;

	       foreach my $str (@file) {
		   ($startpt,$endpt, $constraint, $pathid,$slack) = check_path($str);
			if ($startpt eq 0) {next;}
            if (($constraint =~ /set_output_delay/) or ($constraint =~ /recovery|removal/)) {next;}

			$startpt =~ s/\s+//g;
            #$constraint =~ s/\s+//g;
			$endpt =~ s/\s+//g;
			$pathid =~ s/\s+//g;
			$constraint{$report}{$constraint} = $pathid;
			$slack_store{$corner}{$report_type}{$constraint} = $slack;
			foreach my $category (keys %MAP) {
			if($startpt =~ /$MAP{$category}/||$endpt =~ /$MAP{$category}/) {
			$flag{$startpt}{$endpt} = "$pathid";
			push(@{$path{$constraint}{$category}{$report}},"$startpt($pathid)");
			$Block{$corner}{$constraint}{$category}{$report}{$pathid} = $slack;
			#detailed_report($report, $corner, $file_ref);
			}
			}
			#if ($flag{$startpt}{$endpt} ne "$pathid" ) {$MAP{"Unknown "}= $startpt;$Block{$corner}{$constraint}{"Unknown "}{$report}{$pathid} = "$slack";detailed_report($report, $corner, $file_ref);}
			if ((not defined $flag{$startpt}{$endpt}) or ($flag{$startpt}{$endpt} ne $pathid)) {
			    $MAP{"Unknown "}= $startpt;$Block{$corner}{$constraint}{"Unknown "}{$report_type}{$pathid} = $slack;
			    #detailed_report($report_type,$corner,$file_ref);
			} 
               
#		}
#	}
#	}

}
#print Dumper(\%slack_store);
@file = grep {$_ =~ /slack/} @file;
detailed_report($report, $corner, \@file, \%slack_store);
}
sub check_path() {
my $file_ref = shift;
#my $flag = shift;
my $flag = "found";
my @file = "";
my ($startpt,$endpt, $constraint, $pathid, $slack) = 0;
my @file_array = split /\n/, $file_ref;
#print "$file_ref";
foreach  my $line (@file_array) {
    if (($line !~ /Path     Incr/) &&  ($line !~ /Item:/)) { 
        if($line =~ /Startpoint:/) { $startpt = $line;
        } elsif($line =~ /Endpoint:/) { $endpt = $line;
        } elsif($line =~ /Constraint:(.*)\(/) {$constraint= $1;
        } elsif($line =~ /Constraint:(.*)/) {$constraint= $1;
        } elsif($line =~ /^Path ID:(.*)/) {$pathid= $1;$pathid =~ s/\t| //g;
        } elsif($line =~ /external delay|pulse width/) {return(0,$endpt, $constraint, $pathid,$slack,$flag)
        } elsif($line =~ /slack\s+\(/mg) {$slack= $line;
		   $slack =~ m/(-?[0-9.]*)\s+slack.*\((.*)\)/;
             $slack = $1." $2"; 
			 }  
        #if($line =~ /Constraint:.*(recovery|removal)/) {return($startpt,$endpt, $constraint, $pathid,$slack);}

       }
	   unless((defined $constraint) && (defined $startpt) && (defined $pathid) && (defined $slack) && (defined $endpt)) {next};
	   }
   
return($startpt,$endpt, $constraint, $pathid,$slack,$flag);

}
sub detailed_report() {
my $report_type = shift;
my $corner = shift;
my $file = shift;
my $slack_store = shift;
my %hash = %$slack_store;
#open(REPORT, ">>$report_type.path") || die "cant write $report_type.path\n";
my @REPORT;
push @REPORT,"######$corner#######################\n";
foreach my $k (keys %{$hash{$corner}{$report_type}}) {
    if ($k =~ /model/) {    
	my $v = $hash{$corner}{$report_type}{$k};
	$v =~ m/(.+)\s+.+/;
	$v = $1;
	my @tmp_array = grep {$_ =~ /$v\s+slack/} @$file;
    push @REPORT,"@tmp_array\n";
	}
}
my $status2 = write_file(\@REPORT,"$report_type.path",">");

}

sub tget_call_stack(){
   my(   $package,   $filename, $line,       $subroutine, $hasargs,
   $wantarray, $evaltext, $is_require, $hints,      $bitmask
   ) = caller(0);

   my $subname;
   my @subroutines;
   for( my $i=0; (caller($i))[3]; $i++){
      $subname =  ( caller($i) ) [3];
      $subname =~ s/main:://g;
      push(@subroutines, $subname);
   }
   @subroutines = reverse @subroutines;
   pop(@subroutines);
   my $callstack = "";
   my $spacer = " -> ";
   foreach my $name ( @subroutines ){
      $callstack .= "$name" . $spacer;
   }
   $callstack =~ s/$spacer$//;
   return( $callstack );
}

sub special_sort {
    my $num1 = $a;
    my $num2 = $b;
    $num1 =~ m/(.+)\s+/;
    $num1 = $1;

    $num2 =~ m/(.+)\s+/;
    $num2 = $1;
    if($num1 < $num2) {
        return -1;
    } elsif($num1 == $num2) {
        return 0;
    } else {
        return 1;
    }
}
