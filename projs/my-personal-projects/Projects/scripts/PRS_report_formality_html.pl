#!/usr/local/bin/perl5 

# Author: Sruti Banerjee
#----------------------------------------------
# Produces report on formality run
#----------------------------------------------

use warnings;
use strict;
use Getopt::Long;
use Fcntl;

$script_dir = `dirname $0`;
chomp $script_dir;

GetOptions('help' => \$arg_help,
           'log=s' => \$arg_log,
           'results=s' => \$arg_result,
           'image=s' => \$arg_image,
           'output=s' => \$arg_output,
	   'markcolor=s' => \$arg_markcolor,
           'flows=s' => \$arg_flow);

if(defined($arg_help)){
    &print_usage;
    exit(1);
}

#LOG
#---
if(!defined($arg_log)){
    $arg_log = `pwd`;
    chomp($arg_log);
}

#OUTPUT
#------
if(!defined($arg_output)){
    $arg_output = "$arg_log/report_formality";
    chomp($arg_output);
}
open(OUT, "> $arg_output");

#FLOW
#----
if(!defined($arg_flow)){
    print "\nPlease define the flows \n";
    print_usage();
    exit; 
}

@flow = split(/::/,$arg_flow);
@tmp_flow = split(/:/,$arg_flow);
$base_flow = $tmp_flow[0];
foreach $k (@flow){
    @k_flow = split(/:/,$k);
    #push(@all_flow, @k_flow);
    foreach $j (@k_flow){
        $flow_list{$j} = 1;
    }
}

if(!defined($arg_base)){
    $arg_base = $base_flow;
}

#START PROCESSING
#----------------
$date = `date +%Y%m%d`;
chop($date);
$jobname = "$arg_log:$arg_suite:$arg_comp_strat:$date";

$cur_user = `/usr/bin/whoami`;
chomp $cur_user;
$cur_host = `hostname`;
chomp $cur_host;
$cur_dir = `pwd`;
chomp $cur_dir;
$temp_file = "$arg_log/temp";

open(IN, "> $temp_file");
system ("chmod 777 $temp_file");
close IN;

collect_data();
print_report();
system ("rm -rf $temp_file");
#generate_history();

exit 0;

#----------------------------------------------
# print_usage
#----------------------------------------------
sub print_usage {
    print "\nFormality comparison report for PRS run\n";
    print "\nUsage:\n";
    print "\nPRS_prepare";
    print "\n  -help ";
    print "\n  -log <directory where flows are created> ";
    print "\n  -flow ':' separated list of flows to report on";
    print "\n        Use a '::' to start flow reporting on a new line";
    print "\n  -markcolor <cmp|fail>";
    print "\n        cmp:  mark red color if it succeeds at the baseline but fails";
    print "\n              at the current flow";
    print "\n        fail: mark red color for all failed designs";
    print "\n ";
    print "\nEg:\n ";
    print "PRS_report_formality_html -flow DecFm:DecFmXG::UltraFm:UltraFmXG\n ";
    print "\n ";
}


#----------------------------------------------
# collect_data
# Updated: 2010 Jul 08 : Now report 'Not Found'
#          for designs that are not in base flow
#          but present in compare flow
#----------------------------------------------
sub collect_data{

  foreach $f (sort keys %flow_list){
    $base_dir = $arg_log ."/". $f;
    opendir(DIR, "$base_dir");
    local(@directories) = readdir(DIR);
    closedir(DIR);

    foreach $dir (@directories) {
      next if $dir eq '.';
      next if $dir eq '..';
      next if($dir =~ /propts/) ;

      $design{$dir} = 1;
    }
  }


    foreach $d (sort keys %design) {
        foreach $f (sort keys %flow_list) {
          if (-r "$arg_log/$f/$d") {
            $d_owner = $cur_user;
            `$script_dir/extract_data.pl -dir $arg_log -des $d -flow $f -file $temp_file`;
          } else {
            #detect user/real flow dir
            if (-l "$arg_log/$f") {
              $d_link = `\\ls -la $arg_log/$f`;
              chomp $d_link;
              $d_link =~ /.* -> (.*)/;
              $real_f = $1;
            } else { 
              $real_f = "$arg_log/$f";
            }

            if (-l "$real_f/$d") { 
              chdir $real_f;
              while (-l "$real_f/$d") { 
                $d_link = `\\ls -la $real_f/$d`;
                chomp $d_link;
                $d_link =~ /.* -> (.*)/;
                $real_f = `/usr/bin/dirname $1`;
                chomp $real_f;
                if (-r $real_f) {
                   chdir $real_f;
                   $real_f = `pwd`; 
                   chomp $real_f;
                } else {
                   $real_f = `pwd`; 
                   chomp $real_f;
                   last;
                }  
              }
              $d_owner = `stat -c %U "$real_f/$d"`;
              chomp $d_owner;
            } elsif (-d "$real_f/$d") {   
              $d_owner = `stat -c %U "$real_f/$d"`;
              chomp $d_owner;
            }
            `rsh $cur_host -l $d_owner "cd $cur_dir;$script_dir/extract_data.pl -dir $arg_log -des $d -flow $f -file $temp_file"`; 
        }
      }
    }
}

#----------------------------------------------
# print_report
#----------------------------------------------
sub print_report{

    $date = `date`;
    $head = sprintf("%-25s||%-15s||%-30s","Design",$arg_base,$fm_heading);

    print OUT ".title Formality Report\n\n";
    print OUT "Log Directory: $arg_log\n.br\n";
    print OUT "Date: $date \n.br \n";

    print OUT "The following error codes are reported in this report:\n";
    print OUT "- CMD-081 - Script stopped due to error\n";
    print OUT "- FM-547 - load_upf must be error free before match or verify is allowed\n";
    print OUT "- FM-348 - Could not verify SVF constant 0 register\n";
    print OUT "- FM-340 - Could not process object(s) referenced in SVF\n";
    print OUT "- FM-339 - Invalid SVF file\n";
    print OUT "- FM-045 - Reference design not set\n";
    print OUT "- FM-046 - Implementation design not set\n";
    print OUT "- FM-016 - Can't open file\n";
    print OUT "- SIGSEGV - FM core dump\n";
    print OUT "- SIGABRT - FM aborted\n";
    print OUT "- SIGXCPU - FM run out of CPU limit\n";
    print OUT "- Not Found - FM run hasn't started\n";
    print OUT "- Not Run - FM run finished immediately after starting\n";
    print OUT "- Exit - FM has exit\n";
    print OUT "- Running - FM run hasn't finished\n.br\n";


    open(FILE, "$temp_file");
    while ($line = <FILE>) {
        chomp $line;
        @list = split(/\|/,$line);
        ($d, $f) =  split(/:/,$list[0]);
        $fm_flows{"$d:$f"} = $list[1];
    }
    close FILE;
    
    # Data abstraction for the new FM report enhancements
    # 1.Design Count Status
    # 2.Result Status
    # 3.First level failure analysis
    # 4.Status of the run 

    foreach $k (@flow){
      @k_flow = split(/:/,$k);
      @t_flow =@k_flow;
      shift(@t_flow);
      for ($c=0;$c<=$#t_flow;$c++){

        # Counts the number of designs expected from the propts.cfg file 
        $propts_file = "$arg_log/propts.cfg";
        $grep_string = "^flow.$t_flow[$c]::designs:";
        $design_list = `grep $grep_string $propts_file`;
        ($junk,$t_designs) = split("::",$design_list);
        ($junk,$design_list) = split(":",$t_designs);
        (@propts_designs) = split(" ",$design_list);
        
        @total_expected_designs=@propts_designs;

        foreach $d (sort keys %design){
          $base_missing=0;
          # Design count status
          # Counts the number of designs expected from current flow and base flow
          if((-e "$arg_log/$t_flow[$c]/$d") || (-l "$arg_log/$t_flow[$c]/$d") || (-e "$arg_log/$k_flow[0]/$d") || (-e "$arg_log/$k_flow[0]/$d/$d")){
            unless(grep /^$d$/,@propts_designs){
              push(@total_expected_designs,$d);
            }
          }
          if(!((-e "$arg_log/$k_flow[0]/$d/$d.fmchk.csh") || (-e "$arg_log/$k_flow[0]/$d/$d.fmchk.out") || (-e "$arg_log/$k_flow[0]/$d/$d.fmchk.done") || (-e "$arg_log/$k_flow[0]/$d/$d.fmchk.out.gz") || ($fm_flows{"$d:$k_flow[0]"} !~ /Not Found/))){
            $base_missing=1;
          }
          if((-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.done") || (-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.out.gz") || ($fm_flows{"$d:$t_flow[$c]"} =~ /SUCCEEDED|FAILED|INCONCLUSIVE|FATAL|^Initializing\s*/)){
            push (@complete_designs,$d);
            # Result status
            # Counts the designs SUCCEEDED in the current run
            if ($fm_flows{"$d:$t_flow[$c]"} =~ /SUCCEEDED/) {
              push (@current_pass,$d);
            # Counts the failure designs (Fatal/Inconclusive/Failed) in the current run
            } elsif ($fm_flows{"$d:$t_flow[$c]"} =~ /INCONCLUSIVE|^Initializing\s*|FAILED\s*|^\s*FATAL\s*/) {
                push (@current_fail_inconclusive_fatal,$d);
                # First level failure analysis
                # Counts the designs with FM result SUCCEEDED/FAILED/INCONCLUSIVE/Missing - FATAL
                if ($fm_flows{"$d:$t_flow[$c]"} =~ /^\s*FATAL\s*/) {
                  if ($fm_flows{"$d:$k_flow[0]"} =~ /SUCCEEDED|FAILED\s*|INCONCLUSIVE/) {
                    push (@vary_fatal,$d);
                  } elsif ($base_missing ==1){
                      push (@vary_fatal,$d);
                  }
                # Counts the designs with the FM result SUCCEEDED/FATAL/INCONCLUSIVE/Missing - FAILED
                } elsif ($fm_flows{"$d:$t_flow[$c]"} =~ /FAILED\s*/) {
                    if ($fm_flows{"$d:$k_flow[0]"} =~ /SUCCEEDED|INCONCLUSIVE|^\s*FATAL\s*/) {
                      push (@vary_failed,$d);
                    } elsif ($base_missing ==1){
                        push (@vary_failed,$d);
                    }
                # Counts the designs with the FM result SUCCEEDED/FATAL/FAILED/Missing - INCONCLUSIVE
                } elsif ($fm_flows{"$d:$t_flow[$c]"} =~ /INCONCLUSIVE/) {
                    if ($fm_flows{"$d:$k_flow[0]"} =~ /SUCCEEDED|FAILED\s*|^\s*FATAL\s*/) {
                      push (@vary_inconclusive,$d);
                    } elsif($base_missing ==1){
                        push (@vary_inconclusive,$d);
                    }
                }
            }
          }
          # Status of the run
          unless ((-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.done") || (-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.out.gz") || ($fm_flows{"$d:$t_flow[$c]"} =~ /SUCCEEDEED|FATAL|INCONCLUSIVE|FAILED/)){
            if((-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.csh") || ($fm_flows{"$d:$t_flow[$c]"} =~ /Running/)){
              push(@status,1);
            } 
            if(((-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.csh") && (-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.out")) || ($fm_flows{"$d:$t_flow[$c]"} =~ /Running/)){
              push(@incomplete_designs,$d);
            } elsif((-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.csh") && !(-e "$arg_log/$t_flow[$c]/$d/$d.fmchk.out")){
                push(@notstarted_designs,$d);
            }
          }
        }
      # Calculating the expected design count
      @expected_count = @total_expected_designs;
      $present_designs = scalar(@complete_designs)+scalar(@incomplete_designs)+scalar(@notstarted_designs);
      $missing_designs = scalar(@expected_count)-$present_designs;

      push(@total_expected_count,scalar(@expected_count));
      push(@total_complete_designs,scalar(@complete_designs));
      push(@total_current_pass,scalar(@current_pass));
      push(@total_current_failure,scalar(@current_fail_inconclusive_fatal));
      push(@total_vary_fatal,scalar(@vary_fatal));
      push(@total_vary_failed,scalar(@vary_failed));
      push(@total_vary_inconclusive,scalar(@vary_inconclusive));
      push(@total_incomplete_designs,scalar(@incomplete_designs));
      push(@total_missing_designs,$missing_designs);
      push(@total_notstarted_designs,scalar(@notstarted_designs));
     
      @total_expected_designs=();
      @complete_designs=();
      @current_pass=();
      @current_fail_inconclusive_fatal=();
      @vary_fatal= ();
      @vary_failed = ();
      @vary_inconclusive = ();
      @incomplete_designs = ();
      @notstarted_designs = ();
      }
    }
    # Printing the new FM results
    print OUT "\n<b>\n = Design Count Status</b>";
    for ($c=0;$c<=$#t_flow;$c++){
      print OUT "\n   = Number of designs expected for $t_flow[$c] flow : $total_expected_count[$c]";
      print OUT "\n   = Number of designs missing in $t_flow[$c] flow : $total_missing_designs[$c]";
      print OUT "\n   = Number of designs not started formality in $t_flow[$c] flow : $total_notstarted_designs[$c]";
      print OUT "\n   = Number of designs incomplete in $t_flow[$c] flow : $total_incomplete_designs[$c]";
      print OUT "\n   = Number of designs complete in $t_flow[$c] flow : $total_complete_designs[$c]";
    }
    print OUT "<b>\n =  Result Status </b>";
    for ($c=0;$c<=$#t_flow;$c++){
      print OUT "\n   = Number of designs passed in $t_flow[$c] flow : $total_current_pass[$c]";
      print OUT "\n   = Number of designs failed in $t_flow[$c] flow : $total_current_failure[$c]";
    }
    print OUT "<b>\n = First level Failure Analysis </b>";
    for ($c=0;$c<=$#t_flow;$c++){
      print OUT "\n   = New fatals in $t_flow[$c] flow (Succeeded/Failed/Inconclusive/Missing - Fatal)  : @total_vary_fatal[$c]";
      print OUT "\n   = New failed in $t_flow[$c] flow (Succeeded/Fatal/Inconclusive/Missing - Failed) : @total_vary_failed[$c]";
      print OUT "\n   = New inconclusive in $t_flow[$c] flow (Succeeded/Fatal/Failed/Missing - Inconclusive) : @total_vary_inconclusive[$c]";
    }
    if(@status){
      print OUT "<b>\n = Status of the run : In Progress </b>";
    } else {
        print OUT "<b>\n = Status of the run : Complete </b>";
    }
    for($c=0;$c<=$#t_flow;$c++){
      foreach $d (@expected_count){
        if(!((-d "$arg_log/$t_flow[$c]/$d") || ($fm_flows{"$d:$t_flow[$c]"} =~ /SUCCEEDED|FATAL|INCONCLUSIVE|FAILED|Running/))){
            push(@current_missing,$d);
        }
      }
      if(scalar(@current_missing) >0){
        print OUT "\n   = List of designs missing in $t_flow[$c] flow : <b>@current_missing</b>";
      }
      @current_missing=();
    }
    $num_flows = @k_flow + 3;
    
    print OUT "\n\n.table cols=$num_flows border=1\n";

    # Added Index to the table 
    print OUT ".cell\n<b>Sl.no</b>\n";
    $cell = ".cell";
    $i = 0;

    $index_cell = ".cell";
    print OUT ".cell\n<b>Design Name</b>\n";
    $cell = ".cell";
    $i = 0;
    foreach $k (@flow){
        $cell = ".rowcell\n  \n.cell" if($i > 0);
        $i++;
        @k_flow = split(/:/,$k);
        foreach $j (@k_flow){
            print OUT "$cell\n<b>$j</b> \n";
            $cell = ".cell";
        }
    }

    $index_cell = ".cell";
    print OUT ".rowcell\n<b>--</b>\n";
    $cell = ".cell";
    $i = 0;

    $index_cell = ".cell";
    print OUT ".cell\n<b>Flow Title</b>\n";
    $cell = ".cell";
    $i = 0;
    foreach $k (@flow){
        $cell = ".rowcell\n  \n.cell" if($i > 0);
        $i++;
        @k_flow = split(/:/,$k);
        foreach $j (@k_flow){
            $propts_file = "$arg_log/propts.cfg";
            $grep_string = "^flow.$j.title:";
            $temp = `grep $grep_string $propts_file`;
            print $temp;
            ($junk, $flow_title) = split("title:", $temp);
            #($junk, $flow_title) = split("nbsp;", $temp1);
            $flow_title =~ s/&nbsp;//; 
            chomp $flow_title;
            print OUT "$cell\n<b>$flow_title</b> \n";            
        }
    }

    $design_cell = ".rowcell";
    $slno=1;
    foreach $d (sort keys %design){
        print OUT "$design_cell\n$slno\n";
        print OUT "$index_cell\n$d\n";

        $cell = ".cell";
        $i = 0;
        $slno++;
        foreach $k (@flow){
            $cell = ".rowcell\n  \n.cell" if($i > 0);
            $i++;
            @k_flow = split(/:/,$k);
            foreach $j (@k_flow){
              print OUT "$cell";
	      if ($arg_markcolor eq "cmp") {
                  #Added background highlighting for designs showing variation in formality result 
                  #Missing - FAILED/INCONCLUSIVE/FATAL 
                  if (!((-e "$arg_log/$k_flow[0]/$d/$d.fmchk.out") || (-e "$arg_log/$k_flow[0]/$d/$d.fmchk.csh") || (-e "$arg_log/$k_flow[0]/$d/$d.fmchk.out.gz"))){
                    if ($fm_flows{"$d:$j"} =~ /^\s*FATAL SIGSEGV\s*|^\s*FATAL Out-of-Memory\s*|^\s*FATAL FM-045\s*|^\s*FATAL SIGABRT\s*|^\s*FATAL SIGXCPU\s*/) {
                      print OUT "bgcolor=yellow";
                    } elsif ($fm_flows{"$d:$j"} =~ /^\s*FM-\d+|^\s*FATAL FM-046\s*/) {
                        print OUT " bgcolor=skyblue";
                    } elsif ($fm_flows{"$d:$j"} =~ /INCONCLUSIVE/) {
                        print OUT "bgcolor=orange";
                    } elsif ($fm_flows{"$d:$j"} =~ /FAILED/) {
                        print OUT "bgcolor=red";
                    }
                  }
                  # FATAL / FAILED / SUCCEEDED - INCONCLUSIVE
                  if ($fm_flows{"$d:$k_flow[0]"} =~ /SUCCEEDED|FAILED|^\s*FATAL\s*/) {
                    if ($fm_flows{"$d:$j"} =~ /INCONCLUSIVE/) {
                      print OUT "bgcolor=orange";
                    }
                  }
                  #FATAL / INCONCLUSIVE / SUCCEEDED - FAILED
                  if ($fm_flows{"$d:$k_flow[0]"} =~ /SUCCEEDED|INCONCLUSIVE|^\s*FATAL\s*/) {
                    if ($fm_flows{"$d:$j"} =~ /FAILED/) {
                      print OUT "bgcolor=red";
                    }
                  }
                  # FAILED /INCONCLUSIVE /SUCCEEDED - FATAL
                  if ($fm_flows{"$d:$k_flow[0]"} =~ /SUCCEEDED|INCONCLUSIVE|FAILED/) {
                    if ($fm_flows{"$d:$j"} =~ /^\s*FATAL SIGSEGV\s*|^\s*FATAL Out-of-Memory\s*|^\s*FATAL FM-045\s*|^\s*FATAL SIGABRT\s*|^\s*FATAL SIGXCPU\s*/) {
                      print OUT "bgcolor=yellow";
                    } elsif ($fm_flows{"$d:$j"} =~ /^\s*FM-\d+|^\s*FATAL FM-046\s*/) {
                        print OUT " bgcolor=skyblue";
                    }
                  }
	       } elsif ($arg_markcolor eq "fail") {
		 if ($fm_flows{"$d:$j"} =~ /FAILED/) {
		   print OUT " bgcolor=red";
                 } elsif ($fm_flows{"$d:$j"} =~ /INCONCLUSIVE/) {
		     print OUT " bgcolor=orange";
                 } elsif ($fm_flows{"$d:$j"} =~ /^\s*FATAL SIGSEGV\s*|^\s*FATAL Out-of-Memory\s*|^\s*FATAL FM-045\s*|^\s*FATAL SIGABRT\s*|^\s*FATAL SIGXCPU\s*/) {
		     print OUT " bgcolor=yellow";
                 } elsif ($fm_flows{"$d:$j"} =~ /^\s*FM-\d+|^\s*FATAL FM-046\s*/) {
		     print OUT " bgcolor=skyblue";
		 }
    	      }
	      print OUT "\n";
              if(-e "$arg_result/formality/$arg_image/$j/$d.fmchk.out.gz"){
                print OUT ".link http://clearcase.synopsys.com/$arg_result/formality/$arg_image/$j/$d.fmchk.out.gz $fm_flows{\"$d:$j\"} \n";
              } else {
                  print OUT " $fm_flows{\"$d:$j\"} \n";
              }
                $cell = ".cell";
          }
            #$cell = ".rowcell\n  \n.cell";
        }
    }
    print OUT ".end\n";
    print OUT "\n Data Interpretation";
    print OUT "\n -Expected designs -  Designs expected to run in this flow. This is a superset of ";
    print OUT "\n  -Designs as defined in the propts.cfg for this flow";
    print OUT "\n  -Design directories actually created in the current flow ";
    print OUT "\n  -Design directories actually created in the base flow";
    print OUT "\n -Missing designs - Number design for which the design directory was not created in the flow directory ";
    print OUT "\n -Not started designs - Number of designs which did not start the formality run yet ";
    print OUT "\n -Incomplete designs - Number of designs for which the formality run is going on ";
    print OUT "\n -Completed designs - Number of designs which completed FM run ";
}
