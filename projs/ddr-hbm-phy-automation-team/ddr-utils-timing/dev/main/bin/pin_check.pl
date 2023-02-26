#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Cwd;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
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
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#


use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


utils__script_usage_statistics( $PROGRAM_NAME, $VERSION);



##########################################################################
# Author : Nandagopan G                                                  #   
# Function : Used to grep out pins from setup,libs and subckt and check  #
#            if they matches                                             # 
##########################################################################
BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log( $LOGFILENAME );
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}

sub Main {

my ($FR, $FR1, $FR2, $FR3, $lib, $line, $pin, $pin_lsb, $pin_num, $pre_post, $pwd, $sch_netlist, $sch_netlist_path, $used_netlist, $used_netlist_nt);

$pwd = getcwd();
chomp($pwd);

if ($ARGV[0] eq "" || $ARGV[1] eq "" || $ARGV[2] eq "")
{
  Util::Messaging::iprint ("Usage : pin_check.pl <nt/sis> <macro_name> <subckt/lib/setup>\n");
  exit;
}
chomp $ARGV[0];
chomp $ARGV[1];
chomp $ARGV[2];


if (lc($ARGV[0]) eq "help")
{
  Util::Messaging::iprint ("Usage : pin_check.pl <nt/sis> <macro_name> <subckt/lib/setup>\n");
  exit;
}

if (-d "$pwd/port_check")
{

}
else
{
  my ($stdout, $stderr) =  run_system_cmd  ("mkdir port_check", "$VERBOSITY");
}

if (lc ($ARGV[0]) eq "nt")
{
  if (lc($ARGV[2]) eq "subckt")
  {
    my ($stdout0, $stderr0) =  run_system_cmd  ("rm -rf port_check/subckt_pins port_check/bbox.txt port_check/netlist_used.txt", "$VERBOSITY");
    
    my ($stdout1, $stderr1) =  run_system_cmd  ("touch port_check/netlist_used.txt", "$VERBOSITY");
    my ($stdout2, $stderr2) =  run_system_cmd  ("cat alphaNT.config | grep -i 'set extractNetlistDir' | awk '{print \$NF}' > port_check/netlist.txt", "$VERBOSITY");
    #open ($FR,"<port_check/netlist.txt") or die "netlist not found" ;
    my @file_array = read_file("port_check/netlist.txt");
    foreach my $line (@file_array) 
    {
      chomp $line;
      #print "$line\n";
      my ($err1,$err2) = "";
      ($pre_post,$err1) =  run_system_cmd("cat alphaNT.config | grep -i 'set phase' | awk '{print \$NF}'","$VERBOSITY");
      chomp($pre_post);
      if ($pre_post =~ /post/)
      {
        ($used_netlist_nt,$err2) =  run_system_cmd("grep 'Instance Section' $line\/$ARGV[1]_rcc*.spf",$VERBOSITY);
        chomp($used_netlist_nt);
        if ($used_netlist_nt =~ /Instance Section/)
        {
         my ($stdout3, $stderr3) =  run_system_cmd  ("touch port_check/bbox.txt", "$VERBOSITY"); 
         my ($stdout4, $stderr4) =  run_system_cmd  ("grep -i 'subckt $ARGV[1]' $line\/$ARGV[1]_rcc*.spf  | grep -v '*' > port_check/subckt_pins", "$VERBOSITY");
         my ($stdout5, $stderr5) =  run_system_cmd  ("vi port_check/subckt_pins -c':1,\$s\/ \/\\r/g' -c ':g/.SUBCKT/d' -c ':g/$ARGV[1]/d' -c ':wq!'", "$VERBOSITY");
#        my ($stdout, $stderr) = capture { run_system_cmd  ("cat port_check/subckt_pins | sort -u > port_check/1");
#        my ($stdout, $stderr) = capture { run_system_cmd  ("\\mv port_check/1 port_check/subckt_pins");
         my ($stdout6, $stderr6) =  run_system_cmd  ("vi port_check/subckt_pins -c ':1,\$s/</[/g' -c ':1,\$s/>/]/g' -c ':wq!'", "$VERBOSITY");
         my ($stdout7, $stderr7) =  run_system_cmd  ("cat port_check/subckt_pins | sort -u > port_check/1", "$VERBOSITY");
         my ($stdout8, $stderr8) =  run_system_cmd  ("\\mv port_check/1 port_check/subckt_pins", "$VERBOSITY");
         my ($stdout9, $stderr9) =  run_system_cmd  ("cat $line\/$ARGV[1]_rcc*.spf | awk '{print \$NF}' | grep -v angle | sed -n '/Section/,/ENDS/p' | egrep -v 'Section|ENDS|\\*' | sort -u >> port_check/bbox.txt", "$VERBOSITY");
         my ($stdout10, $stderr10) =  run_system_cmd  ("vi port_check/bbox.txt -c':g/\^\$/d' -c ':1,\$s\/\\n\/ \/g' -c ':wq!'", "$VERBOSITY");
         my ($stdout11, $stderr11) =  run_system_cmd  ("echo 'Netlist Used is LAYOUT Netlist' > port_check/netlist_used.txt", "$VERBOSITY");
         Util::Messaging::iprint("Netlist Used is LAYOUT Netlist\n");
        }
        else {
         my ($stdout12, $stderr12) =  run_system_cmd  ("echo 'Netlist Used is NOT LAYOUT Netlist since \"Instance Section\" is missing from .spf file even though \"set phase\"is POST'> port_check/netlist_used.txt", "$VERBOSITY");
         my ($stdout13, $stderr13) =  run_system_cmd  ("echo 'If this is SCHEMATIC NETLIST please use \"set phase\" as PRE and re-run'>> port_check/netlist_used.txt", "$VERBOSITY");
         Util::Messaging::wprint ("Netlist Used is NOT LAYOUT Netlist since \"Instance Section\" is missing from .spf file even though \"set phase\" is POST\n");
         Util::Messaging::iprint ("If this is SCHEMATIC NETLIST please use \"set phase\" as PRE and re-run\n");
         #my ($stdout, $stderr) = capture { run_system_cmd  (q(perl -0777 -pe 's/\n\+ ?/ /g' < $line\/$ARGV[1]*.sp > merged_sch_netlist_in_one_line));
        }
      }

      elsif ($pre_post =~ /pre/) 
      {

        my ($stdout14, $stderr14) =  run_system_cmd  ("echo 'Netlist Used can be SCHEMATIC NETLIST since \"set phase\" is PRE' > port_check/netlist_used.txt", "$VERBOSITY");
        Util::Messaging::iprint ("Netlist Used can be SCHEMATIC NETLIST since \"set phase\" is PRE\n");
        Util::Messaging::iprint ("Is the netlist used SCHEMATIC NETLIST [y/n]:\n");
        $sch_netlist = <STDIN>;
        chomp($sch_netlist);

        if (lc($sch_netlist) eq "y")
        {
           my ($stdout15, $stderr15) =  run_system_cmd  ("echo 'Is the netlist used SCHEMATIC NETLIST [y/n]: $sch_netlist' >> port_check/netlist_used.txt", "$VERBOSITY");
           my ($stdout16, $stderr16) =  run_system_cmd  ("echo 'Netlist Used is SCHEMATIC Netlist' >> port_check/netlist_used.txt", "$VERBOSITY");
           Util::Messaging::iprint("Netlist Used is SCHEMATIC Netlist\n");
           my $err5 = "";
           ($sch_netlist_path,$err5) = run_system_cmd("cat alphaNT.config | grep -i 'set spiceNetlist' | awk '{print \$NF}' | rev | cut -d '/' -f2- | rev ",$VERBOSITY);
           chomp($sch_netlist_path);
           if ($sch_netlist_path eq "\$\{extractNetlistDir\}")
           {
             my $err3 = "";
             ($sch_netlist_path,$err3) =  run_system_cmd("grep -i 'set extractNetlistDir' alphaNT.config  | awk '{print \$NF}'",$VERBOSITY);
             chomp($sch_netlist_path); 
           }

           my ($stdout17, $stderr17) =  run_system_cmd  ("cat  $sch_netlist_path\/$ARGV[1]*.sp > port_check/sch_netlist_temp.txt", "$VERBOSITY");
		   run_system_cmd("sed -i -n -e '/subckt $ARGV[1]/,/^\.ends/{/^\+/p}' -e '/subckt $ARGV[1]/{p}' port_check/sch_netlist_temp.txt", $VERBOSITY);
           my ($stdout18, $stderr18) =  run_system_cmd  ("perl -0777 -pe 's/\n\+ ?/ /g' < port_check/sch_netlist_temp.txt > port_check/sch_netlist_temp_in_one_line.txt", "$VERBOSITY");
           my ($stdout19, $stderr19) =  run_system_cmd  ("rm -rf port_check/sch_netlist_temp.txt", "$VERBOSITY");
           my ($stdout21, $stderr21) =  run_system_cmd  ("vi port_check/sch_netlist_temp_in_one_line.txt -c':1,\$s\/ \/\\r/g' -c ':g/.SUBCKT/d' -c ':g/.subckt/d' -c ':g/$ARGV[1]/d' -c ':wq!'", "$VERBOSITY");
           my ($stdout22, $stderr22) =  run_system_cmd  ("vi port_check/sch_netlist_temp_in_one_line.txt -c ':1,\$s/</[/g' -c ':1,\$s/>/]/g' -c ':wq!'", "$VERBOSITY");
           my ($stdout23, $stderr23) =  run_system_cmd  ("cat port_check/sch_netlist_temp_in_one_line.txt | sort -u > port_check/1", "$VERBOSITY");	   
		   
		   run_system_cmd  ("sed -e   '/^\$/d' -e   '/^.\$/d'  port_check/1 > port_check/subckt_pins", $VERBOSITY);
           #my ($stdout24, $stderr24) =  run_system_cmd  ("\\mv port_check/1 port_check/subckt_pins", "$VERBOSITY");
           my ($stdout25, $stderr25) =  run_system_cmd  ("rm -rf port_check/sch_netlist_temp_in_one_line.txt", "$VERBOSITY");
  
        }
        else 
        {
          my ($stdout26, $stderr26) =  run_system_cmd  ("echo 'Is the netlist used SCHEMATIC NETLIST [y/n]: $sch_netlist' >> port_check/netlist_used.txt", "$VERBOSITY");
          Util::Messaging::wprint("Please use correct netlist and re-run\n");
          my ($stdout27, $stderr27) =  run_system_cmd  ("echo 'Please use correct netlist and re-run' >> port_check/netlist_used.txt", "$VERBOSITY");
        }
     }

     else
     {
       my ($stdout28, $stderr28) =  run_system_cmd  ("echo '\"set phase\" is neither POST or PRE' > port_check/netlist_used.txt", "$VERBOSITY");
       Util::Messaging::iprint("\"set phase\" is neither POST or PRE\n"); 

     }
    }
    my ($stdout29, $stderr29) =  run_system_cmd  ("rm -rf port_check/netlist.txt", "$VERBOSITY");
  }

  if (lc($ARGV[2]) eq "setup")
  {
    my ($stdout30, $stderr30) =  run_system_cmd  ("rm -rf port_check/pinInfo_pin", "$VERBOSITY");
    my ($stdout31, $stderr31) =  run_system_cmd  ("cat sourcefiles/$ARGV[1].pininfoNT | grep -v '#'|grep -v '<'| cut -d '|' -f2 | cut -d ',' -f1 | awk '{print \$1}'> port_check/2", "$VERBOSITY");
    my ($stdout32, $stderr32) =  run_system_cmd  ("vi port_check/2 -c ':g/cell_x_dim_um/d' -c ':g/$ARGV[1]/d' -c ':g/-/d' -c ':g/name/d' -c ':wq!'", "$VERBOSITY");
    
    my ($stdout33, $stderr33) =  run_system_cmd  ("touch port_check/pinInfo_pin", "$VERBOSITY");
    my ($stdoutt1,$stderrr1) =  run_system_cmd ("cat port_check/2",$VERBOSITY);
    #open ($FR,"<port_check/2");
    my @file_array2 = read_file("port_check/2");
    foreach my $line (@file_array2)
    {
      chomp $line;
      if ($line =~ /\[/)
      {
       my ($stdout34, $stderr34) =  run_system_cmd  ("echo '$line' > port_check/array", "$VERBOSITY");
       my ($stdout35, $stderr35) =  run_system_cmd  ("cat port_check/array | cut -d '[' -f1 > port_check/pin", "$VERBOSITY");
       my ($stdout36, $stderr36) =  run_system_cmd  ("cat port_check/array | cut -d '[' -f2 | cut -d ':' -f1 > port_check/pin_num", "$VERBOSITY");
       my ($stdout37, $stderr37) =  run_system_cmd  ("cat port_check/array | cut -d '[' -f2 | cut -d ':' -f2 > port_check/pin_num1", "$VERBOSITY");
       #open ($FR1,"<port_check/pin");
       my @file_array3 = read_file("port_check/pin");
       foreach my $pin (@file_array3)
       {
        chomp $pin;
        #open ($FR2,"<port_check/pin_num");
        #open ($FR3,"<port_check/pin_num1");
        my @file_array4 = read_file("port_check/pin_num");
        my @file_array5 = read_file("port_check/pin_num1");
        $pin_lsb = $file_array5[0];
        chomp $pin_lsb;
		$pin_lsb =~ s/[|]//g;

        foreach my $pin_num (@file_array4)
        {
          chomp $pin_num;
         ## $pin_num = $pin_num + 1 is done so that if the bit is 0, it will be while (1) so it enters loop and then it becomes 0 due to $a value
         $pin_num = $pin_num + 1;
          while ($pin_num)
          {
            $a = $pin_num - 1;
            my ($stdout38, $stderr38) =  run_system_cmd  ("echo '$pin\[$a\]' >> port_check/pinInfo_pin", "$VERBOSITY");
            if ($a eq $pin_lsb)
            {
              $pin_num = 1;
            }
            $pin_num = $pin_num - 1;
          }
        }
#        close $FR2;
#        close $FR3;
       }
#       close $FR1;
       my ($stdout39, $stderr39) =  run_system_cmd  ("rm -rf port_check/2 port_check/pin port_check/pin_num port_check/pin_num1 port_check/array", "$VERBOSITY");
      } else 
        {
          my ($stdout40, $stderr40) =  run_system_cmd  ("echo '$line' >> port_check/pinInfo_pin", "$VERBOSITY");
        }
    
    }
    my ($stdout41, $stderr41) =  run_system_cmd  ("cat port_check/pinInfo_pin | sort -u > port_check/2", "$VERBOSITY");
    my ($stdout42, $stderr42) =  run_system_cmd  ("\\mv port_check/2 port_check/pinInfo_pin", "$VERBOSITY");
#    close $FR;
  }
  elsif (lc($ARGV[2]) eq "lib")
  {
    my ($stdout43, $stderr43) =  run_system_cmd  ("rm -rf port_check/lib_pg_pin port_check/lib_pg_wc", "$VERBOSITY");
    my ($stdout44, $stderr44) =  run_system_cmd  ("ls $pwd/lib_pg/$ARGV[1]*.lib  | head -1 > port_check/libs", "$VERBOSITY"); 
    my ($stdout45, $stderr45) =  run_system_cmd  ("grep -i -c 'pin (\"' $pwd/lib_pg/*.lib > port_check/lib_pg_wc", "$VERBOSITY");
    my ($stdout46, $stderr46) =  run_system_cmd  ("grep -i -c 'pin (\"' $pwd/lib/*.lib > port_check/lib_wc", "$VERBOSITY");
    #open ($FR,"<port_check/libs");
    my @file_array6 = read_file("port_check/libs");
    foreach my $lib (@file_array6)
    {
      chomp $lib;
      my ($stdout47, $stderr47) =  run_system_cmd  ("grep -i 'pin (\"' $lib | awk '{print \$2}' | cut -d '\"' -f2 | sort -u > port_check/lib_pg_pin", "$VERBOSITY");
    }
    my ($stdout48, $stderr48) =  run_system_cmd  ("rm -rf port_check/libs", "$VERBOSITY");
  }
  exit(0);
}
elsif (lc($ARGV[0]) eq "sis")
{
  my ($netlist_type,$nerr1) = run_system_cmd("grep  set_netlist_file $ARGV[1].inst", $VERBOSITY);
  chomp($netlist_type);
  my $netlist_avail = glob("./$ARGV[1]*.sp*");
  $netlist_avail =~ m/.+\.(.+)$/m;
  my $prefix = $1;
  if ($netlist_type !~ m/.+\.${prefix}/mg) {
      eprint("Wrong netlist mentioned in inst file. Please re-run the script after edits\n");
	  run_system_cmd  ("echo 'Please use correct netlist and re-run' >> port_check/netlist_used.txt", "$VERBOSITY");	  
	  exit(1);
    }
  if (lc($ARGV[2]) eq "subckt")
  {
    my $err4 = "";
    ($used_netlist,$err4) = run_system_cmd("grep 'Instance Section' $ARGV[1].spf",$ VERBOSITY);
    chomp($used_netlist);
    if ($used_netlist =~ /Instance Section/)
    {
     #my ($stdout, $stderr) = capture { run_system_cmd  ("rm -rf port_check/subckt_pins");
     my ($stdout49, $stderr49) =  run_system_cmd  ("rm -rf port_check/subckt_pins port_check/netlist_used.txt port_check/inst_subckt_pin", "$VERBOSITY");
     my ($stdout50, $stderr50) =  run_system_cmd  ("grep -i 'subckt $ARGV[1]' $ARGV[1].spf  | grep -v '*' > port_check/subckt_pins", "$VERBOSITY");
     my ($stdout51, $stderr51) =  run_system_cmd  ("vi port_check/subckt_pins -c':1,\$s\/ \/\\r/g' -c ':g/.SUBCKT/d' -c ':g/$ARGV[1]/d' -c ':wq!'", "$VERBOSITY");
#      my ($stdout, $stderr) = capture { run_system_cmd  ("cat port_check/subckt_pins | sort -u > port_check/1");
#      my ($stdout, $stderr) = capture { run_system_cmd  ("\\mv port_check/1 port_check/subckt_pins");
     my ($stdout52, $stderr52) =  run_system_cmd  ("vi port_check/subckt_pins -c ':1,\$s/</[/g' -c ':1,\$s/>/]/g' -c ':wq!'", "$VERBOSITY");
     my ($stdout53, $stderr53) =  run_system_cmd  ("cat port_check/subckt_pins > port_check/inst_subckt_pin", "$VERBOSITY");
     my ($stdout54, $stderr54) =  run_system_cmd  ("cat port_check/subckt_pins | sort -u > port_check/1", "$VERBOSITY");
     my ($stdout55, $stderr55) =  run_system_cmd  ("mv port_check/1 port_check/subckt_pins", "$VERBOSITY");
     my ($stdout56, $stderr56) =  run_system_cmd  ("echo 'Netlist Used is LAYOUT Netlist' > port_check/netlist_used.txt", "$VERBOSITY");
     iprint("Netlist Used is LAYOUT Netlist\n");
   }
   elsif ($netlist_type =~ /\.sp$/m)
   {
      #my ($stdout, $stderr) = capture { run_system_cmd  ("rm -rf port_check/subckt_pins");
      my ($stdout57, $stderr57) =  run_system_cmd  ("rm -rf port_check/subckt_pins port_check/netlist_used.txt", "$VERBOSITY");
      my ($stdout58, $stderr58) =  run_system_cmd  ("echo 'Netlist Used is NOT LAYOUT Netlist since \"Instance Section\" is missing from .spf'> port_check/netlist_used.txt", "$VERBOSITY");
      Util::Messaging::wprint("Netlist Used is NOT LAYOUT Netlist since \"Instance Section\" is missing from .spf\n");
      Util::Messaging::iprint("Is the netlist used SCHEMATIC NETLIST [y/n]:\n");
      $sch_netlist = <STDIN>;
      chomp($sch_netlist);
      if (lc($sch_netlist) eq "y")
      {   
          my ($stdout, $stderr) =  run_system_cmd  ("echo 'Is the netlist used SCHEMATIC NETLIST [y/n]: $sch_netlist' >> port_check/netlist_used.txt", "$VERBOSITY");
          Util::Messaging::iprint("Netlist Used is SCHEMATIC Netlist\n");
		  Util::Messaging::wprint("Please re-run with correct netlist instance\n");
		  run_system_cmd("echo 'Please re-run the script after fixing' >> port_check/netlist_used.txt", "$VERBOSITY");
          my ($stdout59, $stderr59) =  run_system_cmd  ("echo 'netlist Used is SCHEMATIC Netlist' >> port_check/netlist_used.txt", "$VERBOSITY");
          my ($stdout60, $stderr60) =  run_system_cmd  ("cat  $ARGV[1]*.sp > port_check/sch_netlist_temp.txt", "$VERBOSITY");
          my ($stdout61, $stderr61) =  run_system_cmd  (q(perl -0777 -pe 's/\n\+ ?/ /g' < port_check/sch_netlist_temp.txt > port_check/sch_netlist_temp_in_one_line.txt), "$VERBOSITY");
          my ($stdout62, $stderr62) =  run_system_cmd  ("rm -rf port_check/sch_netlist_temp.txt", "$VERBOSITY");
          my ($stdout63, $stderr63) =  run_system_cmd  ("grep -i 'subckt $ARGV[1] ' port_check/sch_netlist_temp_in_one_line.txt | grep -v '*' > port_check/subckt_pins", "$VERBOSITY");
          my ($stdout64, $stderr64) =  run_system_cmd  ("vi port_check/subckt_pins -c':1,\$s\/ \/\\r/g' -c ':g/.SUBCKT/d' -c ':g/.subckt/d' -c ':g/$ARGV[1]/d' -c ':wq!'", "$VERBOSITY");
          my ($stdout65, $stderr65) =  run_system_cmd  ("vi port_check/subckt_pins -c ':1,\$s/</[/g' -c ':1,\$s/>/]/g' -c ':wq!'", "$VERBOSITY");
          my ($stdout66, $stderr66) =  run_system_cmd  ("cat port_check/subckt_pins | sort -u > port_check/1", "$VERBOSITY");
          my ($stdout67, $stderr67) =  run_system_cmd  ("cat port_check/subckt_pins > port_check/inst_subckt_pin", "$VERBOSITY");
          my ($stdout68, $stderr68) =  run_system_cmd  ("\\mv port_check/1 port_check/subckt_pins", "$VERBOSITY");
          my ($stdout69, $stderr69) =  run_system_cmd  ("rm -rf port_check/sch_netlist_temp_in_one_line.txt", "$VERBOSITY");
          
      }
      else 
      {
          my ($stdout70, $stderr70) =  run_system_cmd  ("echo 'Is the netlist used SCHEMATIC NETLIST [y/n]: $sch_netlist' >> port_check/netlist_used.txt", "$VERBOSITY");
          Util::Messaging::eprint("Please use correct netlist and re-run\n");
          my ($stdout71, $stderr72) =  run_system_cmd  ("echo 'Please use correct netlist and re-run' >> port_check/netlist_used.txt", "$VERBOSITY");
      }
   }
    
  } 
  elsif (lc($ARGV[2]) eq "setup")
  {
    my ($stdout72, $stderr72) =  run_system_cmd  ("rm -rf port_check/inst_pin", "$VERBOSITY");
    #my ($stdout, $stderr) = capture { run_system_cmd  ("grep -i subckt $ARGV[1].spf | grep -v '*' > port_check/inst_subckt_pin");
    #my ($stdout, $stderr) = capture { run_system_cmd  ("vi port_check/inst_subckt_pin -c':1,\$s\/ \/\\r/g' -c ':g/.SUBCKT/d' -c ':g/$ARGV[1]/d' -c ':wq!'");
    my ($stdout73, $stderr73) =  run_system_cmd  ("grep -i 'set_subckt_ports' $ARGV[1].inst | grep -v '#' | cut -d '{' -f2 | cut -d '}' -f1 > port_check/inst_pin", "$VERBOSITY");
#    my ($stdout74, $stderr74) =  run_system_cmd  ("vi port_check/inst_pin -c ':1,\$s/ /\\r/g' -c ':g/set_subckt_ports/d' -c ':g/{/d' -c ':g/}/d' -c ':wq!'", "$VERBOSITY");
#    `vi port_check/inst_pin -c ':1,\$s/ /\\r/g' -c ':g/set_subckt_ports/d' -c ':g/{/d' -c ':g/}/d' -c ':wq!'`;
  }
  elsif (lc($ARGV[2]) eq "lib")
  {
    my ($stdout75, $stderr75) =  run_system_cmd  ("rm -rf port_check/lib_pg_pin port_check/lib_pg_wc", "$VERBOSITY");
    my ($stdout76, $stderr76) =  run_system_cmd  ("ls $pwd/lib_pg/$ARGV[1]*.lib  | head -1 > port_check/libs", "$VERBOSITY");
    my ($stdout77, $stderr77) =  run_system_cmd  ("grep -i -c 'pin(' $pwd/lib_pg/*.lib > port_check/lib_pg_wc", "$VERBOSITY");
    my ($stdout78, $stderr78) =  run_system_cmd  ("grep -i -c 'pin(' $pwd/lib/*.lib > port_check/lib_wc", "$VERBOSITY");
    my @file_array7 = read_file("port_check/libs");
    foreach my $lib (@file_array7)
    {
      chomp $lib;
      my ($stdout79, $stderr79) =  run_system_cmd  ("grep -i 'pin(' $lib | cut -d '(' -f2 | cut -d ')' -f1 |  sort -u > port_check/lib_pg_pin", "$VERBOSITY");
    }
    my ($stdout80, $stderr80) =  run_system_cmd  ("rm -rf port_check/libs", "$VERBOSITY");

  }
  
}
    run_system_cmd  ("sed -i '/^\$/d'   port_check/*", $VERBOSITY);
}
