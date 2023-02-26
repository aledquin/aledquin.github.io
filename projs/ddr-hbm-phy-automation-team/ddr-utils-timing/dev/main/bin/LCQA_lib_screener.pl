#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Pod::Usage;
use Cwd     qw( abs_path );
use Cwd;
#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $TESTMODE     = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $PREFIX       = "ddr-utils-timing";
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.10';
#--------------------------------------------------------------------#
utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);



BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log( $LOGFILENAME );
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}

#------------------------------------------------------------------------------
#  script usage message
#------------------------------------------------------------------------------

sub usage($) {
    my $exit_status = shift;

    iprint << "EOP" ;
Description

USAGE : $PROGRAM_NAME [options] -bbsim <arguement>

------------------------------------
Required Args:
------------------------------------
-lib            <arg>  
-constraint     <arg>

------------------------------------
Optional Args:
------------------------------------
-arc       <arg>
-config    <arg>
-syn_ver   <arg>
-lc_ver    <arg>
-help             iprint this screen
-verbosity  <#>    iprint additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    iprint additional diagnostic messagess to debug script
                   Must provide integer argument -> higher values increases messages.

EOP

    exit $exit_status ;
} # usage()





sub Main {
    unlink "compile.*";
    my ($Me,$std_err0) = run_system_cmd("basename $0",$VERBOSITY );
    chop($Me);
    use List::MoreUtils qw(:all);
    use List::MoreUtils qw{ uniq };
    use Sort::Fields;
    use File::Copy qw{ move };
    use Getopt::Long;
    my $lc          = "lc";
    my $def_module  = "syn";
    my $lc_module;
    my $module;
    my $help;
    my $combine;
    if ((@ARGV == 0)) {
        Usage( $RealBin, 0 );
    }
    my $found = 0;
    my $config;
    my $arc;
    my $logdirname = "csvfiles";
    my $ext = "csv";
    my $arcbasedcsv = 0;
    my $combinebasedcsv = 0;
    my @pin_arc = ();
    my %hash_constriant = ();
    my @value_lines = ();
    my $pin;
    my $opt_help;
    my $opt_debug;
    my $opt_verbosity;
    my ($syn_ver,$lc_ver,$dir) = "";
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    ($dir, $arc, $combine, $syn_ver, $lc_ver, $config, $opt_help) = process_cmd_line_args();


    unless (defined $lc_module) {
        $lc_module = $lc;
    }

    unless (defined $module) {
        $module = $def_module;
    }
    
    my @report = glob("*.report");
    foreach my $report (@report) {
        chomp $report;
        my @split_report = split /\./, $report;
        chomp @split_report;
        my ($stdout2, $stderr2) = capture { run_system_cmd( "rm -rf $split_report[0]_value_range.csv*",$VERBOSITY); };
    }
    sleep(2);
    
    opendir(DIR, $dir) || die "Cannot open directory $dir\n";
    my @libs = grep { /\.lib$/ } readdir( DIR );
    closedir(DIR);
    
    
    my @SCR = ();
    push @SCR, "#!/bin/csh\n";
    push @SCR, "\n";
    push @SCR, "module purge\n";
    push @SCR, "module load $module\n";
    push @SCR, "module unload lc\n";
    push @SCR, "module load $lc_module\n";
    push @SCR, "lc_shell -f compile.tcl\n";
    push @SCR, "exit\n";
    
    write_file(\@SCR, "compile.csh");
    my @TCL = ();
    push @TCL, "set lc_check_lib_keep_line_number true\n";
    
    if((defined $config) && (-e $config)) {
    chomp(@value_lines = read_file("$config"));
}
    my @arc_lines = ();
    if((defined $arc) && (-e $arc)) {
        chomp(@arc_lines = read_file($arc));
        iprint "Arc list has been mentioned, taking arcs from file: $arc\n";
        $arcbasedcsv = 1;
    }
    my @combine_lines = ();
    if((defined $combine) && (-e $combine)) {
        chomp(@combine_lines = read_file($combine));
       
        foreach my $combine_line (@combine_lines) {            
            if ($combine_line =~ /^pin/) {
                my @split_combine_line = split /:/, $combine_line;
                my $pin = trim $split_combine_line[0];
                $hash_constriant{$pin} = trim $split_combine_line[1];
#                print "$pin $hash_constriant{$pin} \n";
                push @pin_arc, $pin;                
            }
        }
        iprint "Combined file has been mentioned, taking arcs from file: $combine\n";
        $combinebasedcsv = 1;
    }
    if((defined $arc && defined $combine) || (defined $config && defined $combine)) {
        eprint "Weird options mentioned. Please mention either arc and config list or complete constraint list in options.\n";
        exit;
    }

    foreach my $lib (@libs) {
        my @split_lib = split /\./, $lib;
        chomp @split_lib;
        my $db = $lib;
        $db =~ s/\.lib$/.db/;
        if(!-l $db) { ## ignore symbolic links
            my $libName = libraryName($lib,$dir);
            if (defined $libName) {
                unlink $db;  
                unlink "$libName.report"; 
                unlink "${libName}_lvf.csv"; 
                unlink "${libName}_summary.csv"; 
                push @TCL, "puts \"Compiling $lib\"\n";
                push @TCL, "read_lib $dir/$lib\n";
                if($arcbasedcsv == 1) {
    #               print TCL "set_check_library_options  -analyze {value_range} -group_attribute {\"IOPAD/TxBypassOEExt\"}  -criteria {@value_lines} -report_format {csv html}\n";        ## format for pin with all related pin 
    #               print TCL "set_check_library_options  -analyze {value_range} -group_attribute {pin(related_pin=TxBypassOEExt)}  -criteria {@value_lines} -report_format {csv html}\n"; ## format for single arc
                    push @TCL, "set_check_library_options  -analyze {value_range} -group_attribute {@arc_lines}  -criteria {@value_lines} -report_format {csv html}\n";
                } elsif($combinebasedcsv == 1) {
                    foreach my $arcs (@pin_arc) {
                        push @TCL, "set_check_library_options  -analyze {value_range} -group_attribute {$arcs} -criteria {$hash_constriant{$arcs}} -report_format {csv html}\n";
                    }
                } else {
                    push @TCL, "set_check_library_options  -analyze {value_range} -criteria {@value_lines} -report_format {csv html}\n";
                }
                push @TCL, "report_check_library_options > $libName.report\n";
                push @TCL, "write_lib $libName -output $db\n";
            } else {
                eprint "Failed to get library name from $dir/$lib\n";
            }
        }
    }
    push @TCL, "check_library\n";
    push @TCL, "quit\n";
    write_file(\@TCL, "compile.tcl");
    my (@output,$std_err1) = run_system_cmd("chmod +x compile.csh; ./compile.csh",$VERBOSITY);
    unlink "command.log";
    write_file(\@output, "compile.log");
    
    foreach my $lib (@libs) {
        my $db = $lib;
        $db =~ s/\.lib$/.db/;
        if (!(-e "$db")) { eprint "$lib compile failed\n"}
    }
    
    iprint "Compile complete.  See compile.log for lc related details\n";
    
    
    if (-d $logdirname) { 
       my ($stdout,$stderr) = capture { run_system_cmd("rm -f $logdirname/*",$VERBOSITY);};
    } else  { 
       mkdir "$logdirname";
    }
    
    my @csvs = glob("*_value_range.csv");
    if(@csvs == 0) {
        eprint "lc did not run properly. Please check setup and run again.\n";
        exit;
    }
    ### trying to add pass or fail status for each csv file



    foreach my $csv (@csvs) {        
        my @rpt = split /_value_range\.csv/, $csv;
        my @ip = ();
        my @split_csv = split /\./, $csv;
        chomp @split_csv;
        my ($start_all,$std_err2) =  run_system_cmd("cut -d ',' -f1-5 $csv",$VERBOSITY);
        my @start = split /\n/, $start_all;
        chomp @start;
        logger "\n$csv:\n";
        foreach my $pin_name (@pin_arc) {
            logger "$pin_name:\t";
            if ($pin_name =~ /pin=(.*)\(related_pin=(.*)\)/) {
                my $test_arc = "$1/$2";
                if (grep {/$test_arc/} $start_all) {
                    logger "FAIL\n";
                } else { logger "PASS\n"; }
        }
        }
        my ($array_all,$std_err3) =  run_system_cmd("cut -d ',' -f6- $csv",$VERBOSITY);
        my @array = split /\n/, $array_all;
        chomp @array;
        my @lengthofvalue = "";
        my @line_num = "";
        my @sorted = "";
        my @maxvalue = "";
        my @value = "";
        
        foreach my $line (@array) {
            chomp $line;
            if ($line =~ /Table|line_num/) { next; }
            my @element = split /,/, $line;
            my @linenum = pop @element;
            my $length = @element;
            push @lengthofvalue,$length;
            push @line_num,$linenum[0];
            @sorted = sort { $a <=> $b } @element;
              @maxvalue = pop @sorted;
            push @value,$maxvalue[0];
        }
        @array = ();
        splice(@line_num,1,0,'line_num');
        splice(@value,1,0,'value');
        splice(@lengthofvalue,1,0,'count');
        my $append = each_array(@start,@value,@line_num,@lengthofvalue);
        while ( my ($p, $r, $s, $t) = $append->() ) {
            if(!defined $r) {$r = "-";}
            if(!defined $s) {$s = "-";}
            if(!defined $t) {$t = "-";}
            push @ip, "$p,$r,$s,$t,\n";
        }
        push @ip, "\n\n\n\nDetails from $rpt[0].report:\n\n\n";
    
        my @ip_report = read_file("$rpt[0].report");
        foreach my $line (@ip_report) {
            chomp $line;
            $line =~ s/^\s+|\s+$//g;
            $line =~ s/\(|\)//g;
            if($line =~ /Relative/i) {
                $found = 1;
            }
            if ($found == 1) {
                $line =~ s/:/,/g;
                push @ip, "$line\n";
            }
        }
        write_file(\@ip, "$logdirname/final_${csv}");
        my @linenum = ();
        @value = ();
        @lengthofvalue = ();
        @line_num = ();
        my @element = ();
        @maxvalue = ();
        @sorted = ();
    
    }
    my ($stdout1, $stderr1) = capture { run_system_cmd("mv *_value_range.${ext} $logdirname/",$VERBOSITY); };
    #   print "Error : LC not run properly. Please check setup and run again.\n";
}

sub libraryName($$) {
    my $lib = shift;
    my $dir = shift;
    my $libname = undef;
    my @lib_lines = read_file("$dir/$lib");
    foreach my $line (@lib_lines) {
        if ($line =~ m/^\s*library\s*\(\"*(\w+)\"*\)/) {
            $libname =  $1;
        }
    }
    return $libname;
}

sub ShowUsage($$) {
    my $script_path = shift;
    my $status      = shift;

    iprint "Current script path: '$script_path'\n";
    pod2usage({
            -pathlist => "$RealBin",
            -exitval => $status,
            -verbose => 1 });
}


sub process_cmd_line_args(){
    my ( $opt_dir, $opt_arc, $opt_combine, $opt_config, $opt_syn_ver, $opt_lc_ver,  $opt_help, $opt_dryrun, 
         $opt_debug,  $opt_verbosity );

    my $success = GetOptions(
        "config=s" => \$opt_config,
        "arc=s" => \$opt_arc,
        "syn_ver=s" => \$opt_syn_ver,
        "lc_ver=s" => \$opt_lc_ver,
        "h" => \$opt_help,
        "lib=s" => \$opt_dir,
        "constraint=s" => \$opt_combine,
        "help"        => \$opt_help,           # Prints help
     );

    if( defined $opt_dryrun ){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return($opt_dir, $opt_arc, $opt_combine, $opt_syn_ver, $opt_lc_ver, $opt_config,  $opt_help );
};


















__END__
=head1 SYNOPSIS

    ScriptPath/LCQA_lib_screener.pl \
    [-config <config file> \]
    [-arc <arc> \]
    [-syn_ver \]
    [-lc_ver \]
    [-help \]
    [-lib \]


<Script> -lib <directory with lib-files>  -config <optional file> -module <optional by default taken as syn/2013.12> 

