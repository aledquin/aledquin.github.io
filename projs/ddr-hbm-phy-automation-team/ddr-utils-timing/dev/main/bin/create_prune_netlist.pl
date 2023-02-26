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
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log($LOGFILENAME);
   footer(); 
}


#
##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;



#####################################################################################################################################################################

my ($debug,$opt_help,$bbox_list_file,$in_file,$tree_file,$lvl);

sub Main {
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);

   ($debug,$bbox_list_file,$in_file,$tree_file,$lvl,$opt_help)
            = process_cmd_line_args();

    ## set file names
    my ($in_file);
    my $bbox_list_file;
    my $tree_file;
    my $CELL;
    my $lvl=0;
    my $help = 0;

    my $sub_file = './netlist_sub.spf';
    my $pre_file = './netlist_pre.spf';
    my $tmp_netlist_file = './temp1';
    my $equiv_file = './equiv.txt';
    my $config_file = './config.txt';
    my $model_port_file = '../timing/src/model_port.tcl';
    my $tmp_tree_file = './temp2';
   
    
    ## check input
    if ((not defined $in_file) or (not defined $bbox_list_file)) {
        warn "Wrong args: try $0 -netlist <schematic netlist> -bbox_list <bbox cell list>\n";
        exit 1;
    }
    
    ## welcome
    iprint ("Using $bbox_list_file and $in_file to create netlist_pre.spf, netlist_sub.spf\n 
    equiv.txt, config.txt and ../timing/src/model_port.tcl ...\n");
    
    ## local variables
    
    ## open files
    run_system_cmd ("sed -e '/^\*/d' -e '/^\#/d' $in_file > temp1", "$VERBOSITY");
    
    ##open(my $IFH,"<", "$tmp_netlist_file") || die ("Can't find or open netlist_org file: $tmp_netlist_file\n");
    my @IFH = read_file("$tmp_netlist_file");
    #open(my $PFH,">", "$pre_file") || die ("Can't open netlist_pre file: $pre_file\n");
    #open(my $SFH,">", "$sub_file") || die ("Can't open netlist_sub file: $sub_file\n");
    ##open(my $BBH,"<", "$bbox_list_file") || die ("Can't find or open bbox list file: $bbox_list_file\n");
    my @BBH = read_file("$bbox_list_file");
    #open(my $EQH,">", "$equiv_file") || die ("Can't open blackbox extract config file: $equiv_file\n");
    #open(my $CNH,">", "$config_file") || die ("Can't open blackbox extract config file: $config_file\n");
    #open(my $MPH,">", "$model_port_file") || die ("Can't open NT hierachical config file: $model_port_file\n");
    ##open(my $TRH,"<", "$tree_file") || die ("Can't open hierachical tree list file: $tree_file\n");
    my @TRH = read_file("$tree_file");
    ## create blackbox array
    my @bbox_array = '';
    my $i=0;
    ##while (my $str=<$BBH>){
    foreach my $str (@BBH){
       if ($str=~/^\s*(\S+)\s*$/){
          $bbox_array[$i]=$1;
       }
       $i++;
    }
    
    iprint ("black box array is @bbox_array\n");
    
    ## find macro name and create cell bbox list
    my $max_broken_bar_count = 0;
    my $current_bbox_layer = 1;
    my $bboxing = 0;
    my %cell_prune_list;
   ## while (my $str=<$TRH>){
    foreach my $str (@TRH){
    #   print SFH "$str";
      ## my @list = split (/\s+/,$str);
       my @list = split (/\s+/,$str);
       my $broken_bar_count = 0;
       my $lib_name = '';
       my $cell_name = '';
       my $b_or_not = 0;
       
       ## find the hierarchy layer
       for (my $i=0; $i<=$#list; $i++){
          if ($list[$i] eq "|"){
             $broken_bar_count ++;
          }
          elsif ($list[$i-2] eq "-"){
             $lib_name = $list[$i-1];
         $cell_name = $list[$i];
          }
       }
    
       
       ## remove unwanted cell
       if (($lib_name eq "basic") || ($lib_name eq "sheets") || ($lib_name eq "devices")) {
          ;
       }
       else{
          ## check if it needs to bbox
          ## find the TOP CELL Name
          if ($broken_bar_count == 0){
         $CELL = ${cell_name};
         $cell_prune_list{$cell_name} = 1;
    #         print SFH "$cell_name =1 line=117\n"; #debug
          }
          else {
         ##check if on bbox_list
         ## $cell_prune_list{$cell_name} = 2,1,0 == bbox, keep, pruned
         for (my $i=0; $i<=$#bbox_array; $i++){
         my $tmp = $bbox_array[$i];
            if ($cell_name=~/^$tmp$/){
               $b_or_not = 1;
            }
         }
         if ($b_or_not && !$bboxing){
                $bboxing = 1;
            $current_bbox_layer = $broken_bar_count;
            $cell_prune_list{$cell_name} = 2;
    #        print SFH "$cell_name =2 line=132\n"; #debug
         }
         elsif ($b_or_not && $bboxing){
                if ($broken_bar_count <= $current_bbox_layer){
               # new bbox cell 
               $current_bbox_layer = $broken_bar_count;
               $cell_prune_list{$cell_name}=2;
    #           print SFH "$cell_name =2 line=139\n"; #debug
            }
            else {
                   if ($cell_prune_list{$cell_name}){
                  # broken_bar_count > $current_bbox_layer means this cell is a subckt of bbox cell
                  # do nothing if the cell already been kept or bboxed
    #              print SFH "??\n"; #debug
              ;
               }
               else{
              $cell_prune_list{$cell_name}=0;
    #              print SFH "$cell_name =0 line=150\n"; #debug
               }
            }
         }
         elsif (!$b_or_not && $bboxing) {
            if ($broken_bar_count <= $current_bbox_layer){
               # keep the cell if it is not 
               $bboxing = 0;
               $cell_prune_list{$cell_name} = 1;
    #           print SFH "$cell_name =1 line=159\n"; #debug
            }
            else {
               if ($cell_prune_list{$cell_name}){
                  # broken_bar_count > $current_bbox_layer means this cell is a subckt of bbox cell
                  # do nothing if the cell already been kept or bboxed
    #              print SFH "??\n"; #debug
              ;
               }
               else{
                     $cell_prune_list{$cell_name}=0;
    #              print SFH "$cell_name =0 line=170\n"; #debug
               }
            }
         }
         elsif (!$b_or_not && !$bboxing){
                $cell_prune_list{$cell_name} = 1;
    #        print SFH "$cell_name =1 line=168\n"; #debug
         }
         else {
             eprint ("ERROR check script\n");
         }
         if ($max_broken_bar_count >= $broken_bar_count){
            
         }
         elsif ($max_broken_bar_count < $broken_bar_count){
           $max_broken_bar_count = $broken_bar_count;
         }
          }
       }
       
       ## preserve levelshifter if request 
       if ($lvl){
          if (($lib_name eq "hdreglhmvcell") || ($lib_name eq "hdreghlmvcell") || ($lib_name eq "hdiolhmvcell") || ($lib_name eq "hdiohlmvcell") || ($lib_name eq "gf14nxgslogl14hdr078f")){
             $cell_prune_list{$cell_name} = 1;
          iprint ("Found LVL: $cell_name\n");
          }
       }
    }
    
    
    #print MPH "set link_prefer_model_port { ";
    my $MPH1 = write_file("set link_prefer_model_port { ","$model_port_file");

    while (my($key,$value)=each(%cell_prune_list)){
       if ($value == 2){
          #print EQH "$key ";
	  my $EQH1 = write_file("$key ","$equiv_file");
         # print CNH "\"$key\",";
	 my $CNH1 = write_file("\"$key\",","$config_file");
          #print MPH "$key ";
	 my $MPH2 = write_file("$key }","$model_port_file",">");
       }
    #   print PFH "$key => $value\n";
    }
    #print MPH "}";
    #my $MPH3 = write_file("}","$model_port_file",">");
    
    ## debug
    #while (my ($key, $value)=each %cell_prune_list){
    #print SFH "$key $value\n"
    #}
    ## debug
    
    #print PFH "\*This file is pruned schematic netlist for $CELL\n\n";
    my $PFH1 = write_file("\*This file is pruned schematic netlist for $CELL\n\n","$pre_file");
    #print SFH "\* This file is pruned subckt netlist for $CELL\n\n";
    my $SFH1 = write_file("\* This file is pruned subckt netlist for $CELL\n\n","$sub_file");
    ## create netlist_sub and netlist_pre
    my $cell_name;
    my $found_cell=0;
    my $found_inst=0;
    my $cell_not_on_list=0;
   ## while (my $str=<$IFH>){
    foreach my $str (@IFH){
       ##if ($str=~/^\s*\.subckt\s+(\S+)\s+/ && !$found_cell && !$found_inst){
       if ($str=~/^\s*\.subckt\s+(\S+)\s+/ && !$found_cell && !$found_inst){
          $cell_name = $1;
          while (my($key,$value)=each(%cell_prune_list)){
             if ($key eq $cell_name){
            if ($cell_prune_list{$cell_name} == 2){
                   #print SFH "$str";
		   my $SFH2 = write_file($str,"$sub_file",">");
               $found_cell = 1;
            }
            elsif ($cell_prune_list{$cell_name} == 1){
                   #print PFH "$str";
		   my $PFH2 = write_file($str,"$pre_file",">");
               $found_cell = 1;
            }
            elsif ($cell_prune_list{$cell_name} == 0){
               $found_cell = 1;
            }
         }
          }
          if (!$found_cell){
             $cell_not_on_list = 1;
         $found_cell = 1;
         $found_inst = 1;
         iprint ("$cell_name is not in $tree_file\n");
          }
       }
       elsif ($str=~/^\s*\.ends\s+(\S+)\s*$/ && $found_cell && $found_inst){
          my $tmp_cell = $1;
          if ($cell_name eq $tmp_cell && !$cell_not_on_list){
         if ($cell_prune_list{$cell_name} == 2){
                #print SFH "$str\n";
		my $SFH3 = write_file("$str\n","$sub_file",">");
            $found_cell = 0;
            $found_inst = 0;
         }
         elsif ($cell_prune_list{$cell_name} == 1){
                #print PFH "$str\n";
		my $PFH3 = write_file("$str\n","$pre_file",">");
            $found_cell = 0;
            $found_inst = 0;
         }
         elsif ($cell_prune_list{$cell_name} == 0){
            $found_cell = 0;
            $found_inst = 0;
         }    
          }
          elsif ($cell_name eq $tmp_cell && $cell_not_on_list){
             $cell_not_on_list = 0;
         $found_cell = 0;
         $found_inst = 0;
          }
          else {
             die ("Error found in $in_file subckt $cell_name\n");
          }
       }
       elsif ($str=~/^\s*\+\s+\S+/ && $found_cell && !$found_inst){
          if ($cell_not_on_list){
             ;
          }
          else {
         if ($cell_prune_list{$cell_name} == 2){
                #print SFH "$str";
		my $SFH4 = write_file("$str","$sub_file",">");
         }
         elsif ($cell_prune_list{$cell_name} == 1){
                #print PFH "$str";
		my $PFH4 = write_file("$str","$pre_file",">");
         }
         elsif ($cell_prune_list{$cell_name} == 0){
                ;
         }
         else {
                die ("Error found in $in_file subckt $cell_name\n");
         }
          }   
       }
       elsif ($str=~/^\s*\+\s+\S+/ && $found_cell && $found_inst){
          if ($cell_not_on_list){
             ;
          }
          else {
         if ($cell_prune_list{$cell_name} == 2){
                ;
         }
         elsif ($cell_prune_list{$cell_name} == 1){
                #print PFH "$str";
		my $PFH5 = write_file("$str","$pre_file",">");
         }
         elsif ($cell_prune_list{$cell_name} == 0){
                ;
         }
         else {
                die ("Error found in $in_file subckt $cell_name\n");
         } 
          }  
       } 
       elsif ($str=m/^\s*[XxMmRrCc,]\S+\s+/ && $found_cell){
          if ($cell_not_on_list){
             ;
          }
          else {
         if ($cell_prune_list{$cell_name} == 2){
                $found_inst = 1;
         }
         elsif ($cell_prune_list{$cell_name} == 1){
               # print PFH "$str";
		my $PFH6 = write_file("$str","$pre_file",">");
            $found_inst = 1;
         }
         elsif ($cell_prune_list{$cell_name} == 0){
                $found_inst = 1;
            ;
         }
         else {
                die ("Error found in $in_file subckt $cell_name\n");
         }
          }   
       } 
       elsif ($str=m/^\s*$/){
       
       }    
       else {
          wprint ("something wrong with @IFH\n");
       }
    }
    
    
    run_system_cmd ("rm temp*", "$VERBOSITY");
}
## all done
iprint ("All done.\n");


sub process_cmd_line_args(){
    my ($outdir,$configFile,$RefLib,$convertbrackets,$convert_Pin_name_to_lowercase,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);
    my $success = GetOptions(
                "help|h"         => \$opt_help,
                "bbox_list=s"    => \$bbox_list_file,
                "dryrun!"        => \$opt_dryrun,
                "debug=i"        => \$opt_debug,
                "verbosity=i"    => \$opt_verbosity,
                "netlist=s"      => \$in_file,
                "tree=s"         => \$tree_file,
                "lvl"            => \$lvl
	); 

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );

    return ($bbox_list_file,$in_file,$tree_file,$lvl);  
}    

sub usage($) {
    my $exit_status = shift || '0';
	pod2usage($exit_status);
   
}    


__END__

=head1 SYNOPSIS

     create_prune_netlist.pl -netlist SCHEMTATIC_NETLIST -bbox_list BBOX_LIST_FILE -tree TREE_FILE [-lvl] [-help] [-h]
     
The script create netlist_pre.spf, netlist_sub.spf, and model_port.tcl for NT bbox simulation, also create
config.txt and equiv.txt for bbox layout netlist extraction. Use [-lvl] if you need to keep hd levelshifter in netlist.
