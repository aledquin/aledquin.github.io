#!/depot/perl-5.14.2/bin/perl
#Developed by Dikshant Rohatgi(dikshant@synopsys.com)
#The script is used to copy xml reports from one site to another
use warnings;
use strict;

 
use Getopt::Long;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use File::Basename;
use Cwd;



use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
#
##  Constants
use constant LOG_INFO => 0;
use constant LOG_WARNING => 1;
use constant LOG_ERROR => 2;
use constant LOG_FATAL => 3;
use constant LOG_RAW => 4;


#----------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG         = NONE;
our $VERBOSITY     = NONE;
our $TESTMODE      = undef;
our $PROGRAM_NAME  = $RealScript;
our $LOGFILENAME   = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION       = get_release_version();
#----------------------------------#

BEGIN {
    our $AUTHOR='dikshant';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
    local $?;   ## adding this will pass the status of failure if the script
                ## does not compile; otherwise this will always return 0
    footer();
    write_stdout_log("$LOGFILENAME");
}
utils__script_usage_statistics( $PROGRAM_NAME, $VERSION);
sub Main {
my ($src,$dst,$host,$macro,$cells_name,$help)="";
GetOptions ("src=s" => \$src,
              "dst=s"   => \$dst,
              "host=s"  => \$host,
	      "macro=s"	=> \$macro,
	      "tb=s"	=>  \$cells_name,
	      "help"	=>  \$help)
or die("Error in command line arguments\n");


my $ch;
if(defined $help) {&help;exit;}
my $copy_file="copy.cfg";
my @FID;

push @FID,  "Source:$dst\n";
push @FID,  "Destination:$dst\n";
push @FID,  "Block:$macro\n";
if(defined $cells_name) {
my @cells=split(/\s+/,$cells_name);
foreach my $cell (@cells) {
	if(!-d "$dst/xml_data/$macro/$cell") {
		print "\nInfo::$dst/xml_data/$macro/$cell is not a valid directory\nDo you want to create it?[y/n]\n";
		my $ch=<STDIN>;
		chomp $ch;
		if($ch eq "y") {
			run_system_cmd_array("mkdir -p $dst/xml_data/$macro/$cell");
			goto Cmd;
		} else {
			print "\nSkipping $cell\n";
			next;
		}
	} else {
		print "\nInfo::$macro/$cell exists in \n$dst,\nPress y to to overwrite or press n to skip the directory\n";
		my $ch=<STDIN>;
		chomp($ch);
		if($ch eq "y") {
			goto Cmd;
		} elsif($ch eq "n") {
			print "\nSkiping $macro/$cell\n";
			next;
		}
	}
my $cmd = "scp -r $host:$src/xml_data/$macro/$cell $dst/xml_data/$macro";
Cmd:	run_system_cmd($cmd, $VERBOSITY);
	print "\nInfo::Sucess:XML data copied for $cell from $src to \n$dst\n\n";
	push @FID,  "$cell\n";
}
} else {
	my $files_src;
	my @files_dst;
	my @files_array;
	my $ch;
	my $flag=0;
	if(-d "$dst/xml_data/$macro") {
		print "Info::$macro exists in $dst\nComparing Testbenches with source\n\n";
		$files_src = run_system_cmd_array("ssh $host ls $src/xml_data/$macro", $VERBOSITY);
		@files_dst=split('\n',$files_src);
		foreach my $f (sort @files_dst) {
			if(-d "$dst/xml_data/$macro/$f") {
				print "Info::$dst/xml_data/$macro/$f exists\npress y to overwrite or press n to skip $f\n";
				$ch=<STDIN>;chomp($ch);
				next if($ch eq "n");
				push(@files_array,"$src/xml_data/$macro/$f");
				push @FID,  "$f\n";
				$flag=1;
			} else {
				push(@files_array,"$src/xml_data/$macro/$f");
				push @FID,  "$f\n";
				$flag=1;
			}
		}
		run_system_cmd_array("scp -r $host:@files_array $dst/xml_data/$macro", $VERBOSITY) if($flag eq 1);
	} else {
		print "Info::$dst/xml_data/$macro Doesn't exists\nCreating it\n";
		run_system_cmd_array("mkdir -p $dst/xml_data");
		print "Copying all Testbenches\n";
		run_system_cmd_array("scp -r $host:$src/xml_data/$macro $dst/xml_data", $VERBOSITY);
		my $stdout1 = run_system_cmd_array("ls -1 $dst/xml_data/$macro");
		push @FID,  $stdout1;
		
	}
} 
write_file(\@FID, $copy_file);
print "Updating .XMLS now,might take some time\n";
#$dst=~ m/(.*\/rel\d+\.\d+.+?)\/.*/g;
#my $dir=$1;
#`mkdir -p "$1/design/sim"` if (!-d "$1/design/sim");
run_system_cmd_array("bbSim_proj_report_copy -copy_list copy.cfg");

print "\nAll Files are copied and xmls are updated, Do You want to upload it on SRV?[y/n]\n";
$ch=<STDIN>;
chomp $ch;
exit if($ch eq "n");

print "Uploading Data on SRV\n";


if(defined $cells_name) {
	my @cells=split(/\s+/,$cells_name);
	foreach (@cells) {
		run_system_cmd_array("rawXML2CDB -report_path $dst/xml_data/$macro/$_");
	}

} else { 
	my @o_files=glob("$dst/xml_data/$macro/*");
	foreach (@o_files) {
		run_system_cmd_array("rawXML2CDB -report_path $_");
	}

}
print "DONE, Please Check SRV\n";

print "Done,Exiting\n";
}

sub help {
	my $usage="Use this script to copy report file from one site to another
	Make sure you have access to both sites
	Options Used:
		-src=Path for your source report directory which has your xml_data directory
		-host=Host name from which you want to copy the data
		-tb=Name of testbenche you want to copy,Use single '' if there are multiple cells
		-macro=Name of the macro
		-dst=Path for your destination directory.This is where the .XMLS will be formed
	If there is no -cell option used with the script,it will copy whole macro directory
	The script gives you choices, so make sure to choose correctly
	After copying the xml data, it will run bbSim command to update the xmls and your data will be uploaded to SRV
	It will make a cofy.cfg file in your cwd which will be used for updating .Xmls
	It will give you a choice to cancel update of xml and promotion of data to SRV
	Example: /remote/us01home58/dikshant/bin/CopyXMLFiles.pl -host dikshant\@in01lts9 -src /slowfs/in01dwt2p056/projects/lpddr54/d859-lpddr54-tsmc7ff18/rel1.00/design/reports 
	-macro dwc_ddrphy_se_io 
	-dst /slowfs/us01dwt2p389/dikshant/lpddr54/d859-lpddr54-tsmc7ff18/rel1.00/documentation/reports/project
	For any updated or clarification, please contact Dikshant Rohatgi";
	hprint "$usage\n";	
}
