#!/depot/perl-5.14.2/bin/perl

##  The current PERL5LIB causes issues.
use strict;
use warnings;
BEGIN {delete $ENV{PERL5LIB}}
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Cwd;
use Pod::Usage;
use Data::Dumper ;
use Liberty::Parser; 
use Parse::Liberty;
use File::Temp qw/ tempfile tempdir /;
use File::Find;
use Getopt::Long;
use Compress::Zlib;
use List::MoreUtils qw(:all);
use List::MoreUtils qw{ uniq };
use Sort::Fields;
use File::Copy qw{ move };
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = FALSE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || '2022.11';
##------------------------------------------------------------------
##  Gather run statistics for the script
##     First argument is name of the script.
##     Second argument is the script version. (ie. 2022ww10)
##     Third argument (optional) is an aref, used
##          to capture the cmd line arguments and log them.
##------------------------------------------------------------------
our $LOGFILENAME = getcwd() . "/$PROGRAM_NAME.log";
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log("${LOGFILENAME}");
   footer(); 
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);
}



 # Get options
#if (!GetOptions( "help|h"         => \$help,
#                  "config=s"       => \$config,
#                 "netlist=s"      => \$netlist,
#                 "xReduction=s"   => \$xReduction,
#                 "xTempSens=s"    => \$xTempSens,
#                 "xtGroundNode=s" => \$xtGroundNode,
#                 "xTypes=s"          => \$xTypes,
#                 "xtPowerExtract=s" => \$xtPowerExtract,
#                 "xtPowerNets=s"    => \$xtPowerNets,
#                 "stdcell=s"     => \$stdcellpath
#                     )) {
#    print STDERR &usage;
#    exit 0;
#}
my ($start2,$start3,@first_element,$common_in_all,$in_arguement_only,$in_netlist_only,$bool_lists,@common_in_all,@in_arguement_only,@in_netlist_only,$xtstarrcxt) ;
sub Main {
my $foundinstance = 0;
my @bbox_array = ();
my $config;
my $netlist; my $netlist_var;
my $help;
my $ipline;
my @check_bbox_lines;
my $foundsecondI = 0;
my $bboxlength;
my $bboxlength_netlist = 0;
my $xReduction;
my $xTempSens;
my $xtGroundNode;
my $xTypes;
my $xtPowerExtract;
my $xtPowerNets;
my $stdcellpath;
my @startsecond;
my @foundsecondI;
my $secondcount;
my $extractedcommands = 0;
my $libdef;
my @irlarray;
my $bboxfile;
my @bboxarray;
my @compare_bbox = ();
my @compare_irl = ();
my @common;
my $first;
my $second;
my $bool_lists_equiv;
my $common;
my @firstonly;
my @secondonly;
my @commonforboth;
my $stdcelllog;
my $argument_value;
my $netlist_value;
my $extractlog;
my $log;
my $ip;
my @ip;
my $debug;
my $opt_help;
my $opt_dryrun;
my $opt_debug;
my $opt_verbosity;

($debug,$config,$netlist,$xReduction,$xTempSens,$xtGroundNode,
$xTypes,$xtPowerExtract,$xtPowerNets,$xtstarrcxt,$stdcellpath,$opt_help)
            = process_cmd_line_args();

if(CheckRequiredFile($config)) {
    iprint ("Info: config file mentioned: $config\n"); 
} else {
    eprint ("Error: Not able to read $config file\n");
}

#open($log,">","bbox_qa.log") or die "Can't open bbox_netlist_qa.log file for read\n";
#open($extractlog,">","extraction_qa.log") or die "Can't open bbox_netlist_qa.log file for read\n";
unlink "extraction_qa.log";

    if(CheckRequiredFile($netlist)) {
        @startsecond = ();
        @foundsecondI = ();
#        print "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
        my $log1 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
        my $status1 = write_file($log1, "bbox_qa.log");
	    iprint ("Info: Reading $netlist\n");
        my $status2 = write_file("Info: Reading $netlist\n","bbox_qa.log",">");
        if($netlist =~ /.gz$/) {
            gunzip $netlist => \ $netlist_var  or die "blah...\n";
            @ip = split($/, $netlist_var);
#            print @ip;
#            exit;
        } else {
		    @ip = read_file($netlist);
        }
        @check_bbox_lines = read_file($config); chomp @check_bbox_lines;
        $bboxlength = @check_bbox_lines;
        foreach my $ipline (@ip) {
            chomp $ipline;
            if($ipline =~ /Instance Section/) {
                $foundinstance = 1;
            }
            if($ipline =~ /.ENDS/) {
                iprint ("Checking Extracted commands.\n");
                $extractedcommands = 1;
            }
            if($foundinstance == 1) {
                foreach my $bbox (@check_bbox_lines) {
                    $bbox =~ s/^\s+|\s+$//g;
                    if($ipline =~ /$bbox/) {
#                        print "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
                        my $log2 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
                        my $status3 = write_file($log2, "bbox_qa.log",">");

#                        print "$bbox:\n";
                        my $log3 ="$bbox:\n";
                        my $status4 = write_file($log3, "bbox_qa.log",">");

                        $bboxlength_netlist = $bboxlength_netlist + 1 ;
#                        print "Info: $ipline $bboxlength_netlist\n";
                       # print $log "Info: $ipline $bboxlength_netlist\n";
                        my $status5 = write_file("Info: $ipline $bboxlength_netlist\n", "bbox_qa.log",">");
			
                        my ($startsecond) = split /[:\s]+/, $ipline, 2;
                        my ($startsecond2) = substr($startsecond,1);
                        my ($startsecond3) = substr($startsecond2,1);
                        my ($flagvalue, $founderrors) = testsyntax($ipline,$bbox);
                        my @dereffounderrors = @$founderrors;
                        if($flagvalue == 1) {
                            my $log4 = "Error: Instance Section Netlist incorrect.$startsecond First check failed at value|s: @dereffounderrors. \n";
                            my $status6 = write_file($log4, "bbox_qa.log",">");    
				            $secondcount = 0;
                                for(my $k = 0; $k<=$#foundsecondI; $k = $k +1) {
                                    if ($foundsecondI[$k] =~ /$startsecond/ || $foundsecondI[$k] =~ /$startsecond2/ || $foundsecondI[$k] =~ /$startsecond3/) {
                                        $secondcount = $secondcount + 1 ;
                                        my $log5 = "Info: *I( lines  found at $foundsecondI[$k]\n" ;
                                        my $status7 = write_file($log5, "bbox_qa.log",">");
                                    }
#                                testI(@foundsecondI,$startsecond);
                            }
                            if($secondcount ne 0) {
                                my $status8 = write_file( "Info: Instances present.\n","bbox_qa.log",">");
                            } else {
                                my $log6 = "Error: $secondcount Instances found. Second check also failed.\n";
				                my $status9 = write_file($log6, "bbox_qa.log",">");
                            }
                        } else {
                            my $log7 = "Info: Instance Section netlist definition ok.$startsecond First check passed. \n";
                            my $status10 = write_file($log7, "bbox_qa.log",">");
			                $secondcount = 0;
                            if($foundsecondI == 1) {
#                                testI(@foundsecondI,$startsecond,$ipline);
                                for(my $k = 0; $k<=$#foundsecondI; $k = $k +1) {
                                    if($foundsecondI[$k] =~ /$startsecond/ || $foundsecondI[$k] =~ /$startsecond2/ || $foundsecondI[$k] =~ /$startsecond3/) {
                                        $secondcount = $secondcount + 1 ;
                                        my $log8 = "Info: *I( lines found at $foundsecondI[$k]\n";
				                        my $status12 = write_file($log8, "bbox_qa.log",">");
                                    }
                                }
                            }
                            if($secondcount ne 0) {
                            my $status13 = write_file( "Info: Instances present. Second check also passed.\n","bbox_qa.log",">");
                            } else {
                                eprint ("Error: $secondcount Instances found. Second Check failed.\n");
                                my $status14 = write_file( "Error: $secondcount Instances found. Second Check failed.\n","bbox_qa.log",">");
                            }
                        }                        
                    }            
                }                
            }            
            if($ipline =~ /^\*\|I \(.+:.*\)$/) {    
                push @foundsecondI, $ipline;
                $foundsecondI = 1;
                
            }
            if ($extractedcommands == 1) {
                if(defined $xReduction && $ipline =~ /^\* Reduction: /i) {
                    testnextlistI($xReduction,$ipline);
                }                
                if(defined $xtGroundNode && $ipline =~ /^\* NETLIST_GROUND_NODE_NAME: /i) {
                    testnextlistI($xtGroundNode,$ipline);
                }
                if(defined $xtPowerExtract && $ipline =~ /^\* POWER_EXTRACT: /i) {
                    testnextlistI($xtPowerExtract,$ipline);
                }
                if(defined $xTempSens && $ipline =~ /^\* TEMPERATURE_SENSITIVITY: /i) {
                    testnextlistI($xTempSens,$ipline);
                }
                if(defined $xtPowerNets && $ipline =~ /^\* POWER_NETS: /i) {
                    testnextlistIpower($xtPowerNets,$ipline);
                }
                if(defined $xtstarrcxt && $ipline =~ /Starrc Version used: /i) {
                    testnextlistIpower($xtstarrcxt,$ipline);
                }
            }
        }
#        print "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
        my $log9 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
        my $status15 = write_file($log9,"bbox_qa.log",">");
	
	    if($bboxlength > $bboxlength_netlist) {
            eprint ("Error: Mismatch found. bbox has $bboxlength devices. Netlist found $bboxlength_netlist devices in it.\n");
            my $status16 = write_file( "Error: Mismatch found. bbox has $bboxlength devices. Netlist found $bboxlength_netlist devices in it.\n","bbox_qa.log",">");
        }
    } else {
        eprint ("Error: Not able to read file.\n");    
    }
    nprint ("------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n");
    my $log10 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
    my $status17 = write_file($log10,"bbox_qa.log",">");
    $foundinstance = 0;

if(defined $stdcellpath) {    
    #open($stdcelllog,">","stdcell_compare.log") or die "Can't open bbox_netlist_qa.log file for read\n";
	my $stdcelllog1;
    my $status18 = write_file( "Info: Comparing the std cell lib names in lib.def vs the names mentioned in bboxlist.list\n","stdcell_compare.log");
    if(CheckRequiredFile("$stdcellpath/lib.defs")) {
        $libdef = "$stdcellpath/lib.defs";
        @irlarray = `grep 'IRL' $libdef`;
        my $status19 = write_file("Info: Reading file $libdef.\n","stdcell_compare.log",">");
	    my $status20 = write_file("Info: IRL found:\n","stdcell_compare.log",">");
        foreach my $value (@irlarray) {
            chomp $value;
            if($value !~ /^#DEFINE/) {
                my $middle = findsecondvalue($value);
                chomp $middle;
                my $status201 = write_file("-$middle\n","stdcell_compare.log",">");
            push @compare_irl,$middle ;
           } else {
                my $status21 = write_file("Warning: $value is commented out.\n","stdcell_compare.log",">");
           }
        }
        $stdcelllog1 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
        my $status22 = write_file($stdcelllog1,"stdcell_compare.log",">");
    } else {
        my $status202 = write_file("Error: lib.defs file not found.\n","stdcell_compare.log",">");
        exit;
    }
    if(CheckRequiredFile("$stdcellpath/bboxList.txt")) {
        $bboxfile = "$stdcellpath/bboxList.txt";
        my $status23 = write_file("Info: Reading file $bboxfile.\n","stdcell_compare.log",">");
        @bboxarray = `grep '^LIB' $bboxfile`;
        my $status24 = write_file("Info: IRL found:\n","stdcell_compare.log",">");
        foreach my $value (@bboxarray) {
            chomp $value;
            my $middle = findsecondvalue($value);
            my $status25 = write_file("-$middle\n","stdcell_compare.log",">");
            push @compare_bbox,$middle;
        }
        my $stdcelllog2 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
        my $status26 = write_file($stdcelllog2,"stdcell_compare.log",">");
    } else {
         my $status27 = write_file("Error: bboxlist.txt file not found.\n","stdcell_compare.log",">");
         exit;
    }


#compare_lists(\@compare_irl,\@compare_bbox);
iprint ("Comparing irl in lib.defs w.r.t bboxList.txt.\n");
my $status28 = write_file("Comparing irl in lib.defs w.r.t bboxList.txt:\n\n","stdcell_compare.log",">");
($common, $first, $second, $bool_lists_equiv) = compare_lists(\@compare_irl,\@compare_bbox);
@firstonly = @$first;
@secondonly = @$second;
@common = @$common;
if(scalar @firstonly == 0 && scalar @secondonly == 0) {
    my $status29 = write_file("Info: Both have same irls. PASSED\n","stdcell_compare.log",">");
    foreach my $c (@common) {
            my $status30 = write_file("Info: Common stdcells: $c.\n","stdcell_compare.log",">");
        }
#    print $stdcelllog "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
    exit;
} else {
    if(@firstonly ne "") {
        foreach my $f (@firstonly) {
             my $status31 = write_file("Error: $f missing in $bboxfile.\n","stdcell_compare.log",">");
        }
        my $stdcelllog3 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
        my $status32 = write_file($stdcelllog3,"stdcell_compare.log",">");
    }
    if(@secondonly ne "") {
        foreach my $s (@secondonly) {
             my $status33 = write_file("Error: $s missing in $libdef.\n","stdcell_compare.log",">");
        }
        my $stdcelllog4 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
        my $status34 = write_file($stdcelllog4,"stdcell_compare.log",">");
    }
}
nprint ("------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n");
my $stdcelllog5 = "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
my $status35 = write_file($stdcelllog5,"stdcell_compare.log",">");
}
}

sub CheckRequiredFile  {
    my $fileName = shift;
    if (defined $fileName) {
        if (-r $fileName) {
            return 1;
        }    
    } else {
        eprint ("Error: Required file variable is undefined\n");
        return 0;
    }
}



sub testsyntax {
    my $fileline = shift;
    my $bbox_config = shift;
    my $flag = 0;
    my @wrongvalues = ();
    my @splitfileline = Tokenify($fileline);
    pop @splitfileline;
    my ($start) = split /[:\s]+/, $fileline, 2;
    push @first_element, $start;
    $start2 = substr($start,1);
    $start3 = substr($start2,1);
    for(my $i =1 ; $i <= $#splitfileline ; $i = $i+1) {
        if($splitfileline[$i] =~ /^$start:/) {
        } elsif($splitfileline[$i] =~ /^$start2:/) {
            $flag = 0;
        } elsif($splitfileline[$i] =~ /^$start3:/) {
            $flag = 0;
        } else {
            push @wrongvalues, "$splitfileline[$i]";
            $flag = $flag + 1;
            last;
        }
    }
return ($flag, \@wrongvalues);
}

sub testnextlistI {
    my $netlistinput = shift;
    my $fileline = shift;
    my $extractlog1 = write_file("Info: File line found '$fileline'\n","extraction_qa.log",">");
    my $extractlog2 = write_file("Info: Argument passed is '$netlistinput'\n","extraction_qa.log",">");
    my ($subfileline) = $fileline =~ /:\s*(.+)$/ ;
    my $extractlog3 = write_file("Info: Value found in netlist is '$subfileline'\n","extraction_qa.log",">");
    if("$netlistinput" eq "$subfileline") {
            my $extractlog4 = write_file("Info: 'PASS' Arguement $netlistinput matches netlist file value $subfileline\n","extraction_qa.log",">");
        my $extractlog5 = write_file("------------------------------------------------------------------------\n","extraction_qa.log",">");
    } else {
         my $extractlog6 = write_file( "Error: Arguement $netlistinput does not match netlist file value $subfileline\n","extraction_qa.log",">");
         my $extractlog7 = write_file( "------------------------------------------------------------------------\n","extraction_qa.log",">");
    }
}


sub testnextlistIpower {
    my $netlistinput = shift;
    my $fileline = shift;
    my $extractlog8 = write_file("Info: File line found '$fileline'\n","extraction_qa.log",">");
    my $extractlog9 = write_file("Info: Argument passed is '$netlistinput'\n","extraction_qa.log",">");
    my ($subfileline) = $fileline =~ /:\s*(.+)$/ ;
    my $extractlog10 = write_file("Info: Value found in netlist is '$subfileline'\n","extraction_qa.log",">");
    my @split_netlistinput = Tokenify($netlistinput);
    my @split_subfileline  = Tokenify($subfileline);
    if("$netlistinput" eq "$subfileline") {
        my $extractlog11 = write_file("Info: 'PASS' Arguement $netlistinput matches netlist file value $subfileline\n","extraction_qa.log",">");
       my $extractlog12 = write_file("------------------------------------------------------------------------\n","extraction_qa.log",">");
    } else {
        ($common_in_all, $in_arguement_only, $in_netlist_only, $bool_lists) = compare_lists(\@split_netlistinput,\@split_subfileline);
        @common_in_all = @$common_in_all;
        @in_arguement_only = @$in_arguement_only;
        @in_netlist_only = @$in_netlist_only;
        chomp @in_arguement_only; chomp @in_netlist_only;
        if(scalar @in_arguement_only == 0 && scalar @in_netlist_only == 0) {
            my $extractlog13 = write_file("Info: 'PASS' Arguement $netlistinput matches netlist file value $subfileline\n","extraction_qa.log",">");
            my $extractlog14 = write_file("------------------------------------------------------------------------\n","extraction_qa.log",">");
        } else {
            if(@in_arguement_only ne "") {
                chomp @in_arguement_only;
                foreach my $argument_value (@in_arguement_only) {
                    my $extractlog15 = write_file("Error: pin '$argument_value' present in Arguement and missing in netlist.\n","extraction_qa.log",">");
                }
            } 
            if(@in_netlist_only ne "") { 
            chomp @in_netlist_only;
            foreach my $netlist_value  (@in_netlist_only) {
                my $extractlog16 = write_file("Error: pin '$netlist_value' present in netlist and missing in Arguement.\n","extraction_qa.log",">");
            }            
        }
            my $extractlog17 = write_file( "------------------------------------------------------------------------\n","extraction_qa.log",">");
        }
    }
}


sub Tokenify
{
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s*(.*)\s+$/$1/;
    return split(/\s+/, $line);
}


sub findsecondvalue {
    my $arrayline = shift;
    if($arrayline =~ /#/) {
        wprint ("Warning: $arrayline is commented out.\n");            
    } else {
        my @splitvalue = Tokenify($arrayline);
        return $splitvalue[1];
    }
}




sub process_cmd_line_args(){
my ($config,$netlist,$xReduction,$xTempSens,$xtGroundNode,
$xTypes,$xtPowerExtract,$xtPowerNets,$stdcellpath,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);

   my $success = GetOptions(
                 "help|h"         => \$opt_help,
                 "config=s"	 => \$config,
                 "dryrun!"        => \$opt_dryrun,
                 "debug=i"        => \$opt_debug,
                 "verbosity=i"    => \$opt_verbosity,
                 "netlist=s"	 => \$netlist,
                 "xReduction=s"   => \$xReduction,
                 "xTempSens=s"	 => \$xTempSens,
                 "xtGroundNode=s" => \$xtGroundNode,
                 "xTypes=s"	 => \$xTypes,
                 "xtPowerExtract=s" => \$xtPowerExtract,
                 "xtPowerNets=s"    => \$xtPowerNets,
                 "starrcxt=s"    => \$xtstarrcxt,
                 "stdcell=s"	=> \$stdcellpath
	);
	
    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    return ($opt_debug,$config,$netlist,$xReduction,$xTempSens,$xtGroundNode,
             $xTypes,$xtPowerExtract,$xtPowerNets,$xtstarrcxt,$stdcellpath,$opt_help);

}    

sub usage($) {
    my $USAGE = <<EOusage;

Usage steps are listed below:

Module load ddr-utils-timing/dev
bbox_netlist_qa.pl -config <cellname.bbox.config path found inside verification directory generated during extraction(eg: /slowfs/us01dwt2p273/ujiten/verification/lpddr5x/d930-lpddr5x-tsmc5ff12/rel1.00_cktpcs/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z/pro_lp5x_rx/dwc_lpddr5xphy_rxdq_ew/dwc_lpddr5xphy_rxdq_ew.bbox.config )> -netlist <.spf path>  -xtGroundNode <extraction command> -xTypes  <extraction command> -xtPowerExtract <extraction command> -xReduction <extraction command>  -xTempSens <extraction command> -xtPowerNets "<extraction command>" -stdcell <path till design directory>

eg:  bbox_netlist_qa.pl -config /remote/us01home57/snehar/timing/bbox_netlist/tx_fe_data_ser.bbox.config -netlist/remote/us01home57/snehar/timing/bbox_netlist/netlist_example/incorrect_tx_fe_data_ser_rcc_typical_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z.spf -xtGroundNode VSS -xTypes rcc -xtPowerExtract "DEVICE_LAYERS NON_DEVICE_LAYERS_CONLY" -xReduction YES -xTempSens NO -xtPowerNets "VDDQ VDDQ_VDD2H VDD VSS" -stdcell  /remote/cad-rep/projects/hbm3/d763-hbm3-v2-tsmc3eff-12-ew/rel1.00/design


The bbox netlist qa script was written to catch missing nets while extracting netlists for nt macros. It is supposed to primarily check for the following in netlist:

BBOX instance definition syntax in instance section
Connection of bbox pin to top level pin


Additionally, it also performs the below checks:

Check if options given in extraction commands match all options present in netlists.
Compare standard cell IRL names in pcs area.



There are 3 log files generated post running the script:

bbox_qa.log :  This takes options ‘-config’ and ‘-netlist’ ; checks syntax of nt netlists and throws error if lines containing black boxed devices are not matching the correct syntax. example log file: /remote/us01home57/snehar/timing/bbox_netlist/bbox_qa.log
extraction_qa.log : This takes all the extraction command options and the netlist option. It performs a comparison check to ensure that the extraction command is run properly. example log file: /remote/us01home57/snehar/timing/bbox_netlist/extraction_qa.log
stdcell_compare.log: This takes the last option ‘-stdcell’. It reads bboxList.txt and lib.defs files present in pcs area and compares the flavours of IRL. It will throw error for any mismatch between both the files. example log file: /remote/us01home57/snehar/timing/bbox_netlist/stdcell_compare.log

EOusage

    nprint ($USAGE);
    exit;   
}




