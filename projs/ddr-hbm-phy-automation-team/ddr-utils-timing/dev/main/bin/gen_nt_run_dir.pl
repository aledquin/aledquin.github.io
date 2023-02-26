#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Cwd;
use File::Basename;
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
our $PROGRAM_NAME = $RealScript;
our $PREFIX       = "ddr-utils-timing";
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log("$LOGFILENAME");
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}

sub Main {
    my $beol;
    my $C;
    my $CELL = "";
    my @corner;
    my $corner;
    my $curr_corner;
    my $dbcorner;
    my $dir;
    my $end;
    my @fields;
    my $help = "";
    my $idx;
    my $is_bbox = "";
    my $is_etm = "";
    my $is_post = "";
    my $is_pre = "";
    my $metal_stack;
    my $mode;
    my $num;
    my $post;
    my $R;
    my $result;
    my $RootDir;
    my $temp;
    my $tim_corner;
    my $v;
    my $vdd;
    my $vstep;
    my $vtemp;
    my $vu;
    my $RUNFILE;
    my @orig_argv = @ARGV;
    my $opt_nousage;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($CELL, $is_etm, $is_bbox, $is_pre, $is_post, $opt_nousage) = process_cmd_line_args();
    unless( $opt_nousage or $main::DEBUG ) {
        utils__script_usage_statistics( "$PROGRAM_NAME", $main::VERSION, \@orig_argv );
    }

    ######### put the project root directory here ###########
    $RootDir="/slowfs/us01dwt2p278/alpha/y006-alpha-sddrphy-ss14lpp-18/rel1.00/design/timing/nt";
    #########################################################
    $metal_stack='11M_3Mx_4Cx_2Kx_2Gx_LB';
    $idx=0;
    $post = 0;
    $is_etm = 0;
    $is_bbox =0;
    $is_pre = 0;
    $is_post = 0;
    $beol = 0;
    my @corner_read = read_file("corner_list.txt");
        foreach my $FILE (@corner_read) {
            chomp $FILE;
            if ($FILE !~ /^\*/) {
                $corner[$idx] = $FILE;
                $idx++;
            }
        }
    $num = $idx;
    $end = 0;
    $idx = 0;
    my $writefile = "";
    my @RUNFILE = ();
    if ($is_etm eq "etm") {
        $writefile = "run_etm.csh";
        $mode = "";
    } elsif ($is_etm eq "rpt"){
        $writefile = "run.csh";
        $mode = ""; 
    } elsif ($is_etm eq "0"){
        $writefile = "run.csh";
        $mode = ""; 
    } else {
        $writefile = "run${is_etm}_etm.csh";
        $mode = "_${is_etm}";
        run_system_cmd("chmod +x run${is_etm}.csh", "$VERBOSITY");
    }
    
    ## check simulation using pre or post netlist
    if ($is_pre==1 and $is_post==0){
        $beol = "pre";
        iprint "\$beol = $beol";
    } elsif ($is_pre==0 and $is_post==1){
        $beol = "post";
        iprint "\$beol = $beol";        
    } else {
        die "\$beol is not defined correctly. \n";
    }
    
    ## extract 
    while ($end == 0) {    
        $curr_corner = $corner[$idx];    
        @fields = split /_/, $curr_corner;
        $corner = $fields[0];
        $R = $fields[1];
        $C = $fields[2];
        $vdd = $fields[3];
        $temp = $fields[4];    
        if ($is_etm eq "etm") {
            $dir = "Run_${corner}_${R}_${C}_${vdd}_${beol}_${temp}_etm";
        } else {
            $dir = "Run_${corner}_${R}_${C}_${vdd}_${beol}_${temp}${mode}";
        }
    
        run_system_cmd("grep xVDD ../model_inc/supply_$vdd.inc > test", "$VERBOSITY"); 
        my @read_test = read_file("test");
        foreach my $TSTFILE (@read_test) {
            chomp $TSTFILE;
            @fields = split /=/, $TSTFILE;
            $v=$fields[1];
        }    
        #$v = 0.8;
        $vstep = $v*0.01;
        $vu = $v*1.1;
        iprint "$dir\n";
        run_system_cmd("mkdir $dir", "$VERBOSITY");    
    # copy over the NT tech file into the run are
        run_system_cmd("cp ../model_inc/nt_tech_${corner}.sp temp", "$VERBOSITY");
        run_system_cmd("sed -e 's/xVDD\"/$v\"/' temp > temp2", "$VERBOSITY");
        run_system_cmd("sed -e 's/xVDDstep/$vstep/' temp2 > temp3", "$VERBOSITY");
        run_system_cmd("sed -e 's/xVDDu/$vu/' temp3 > temp4", "$VERBOSITY");    
        run_system_cmd("sed -e '/xRtype/r ../model_inc/lib_${R}.inc' temp4 > temp5", "$VERBOSITY");
        run_system_cmd("sed -e '/xRtype/d' temp5 > temp6", "$VERBOSITY");
        run_system_cmd("sed -e '/xCtype/r ../model_inc/lib_${C}.inc' temp6 > temp7", "$VERBOSITY");
        run_system_cmd("sed -e '/xCtype/d' temp7 > temp8", "$VERBOSITY");
        run_system_cmd("sed -e '/xTEMP/r ../model_inc/temp_${temp}.inc' temp8 > temp9", "$VERBOSITY");
        run_system_cmd("sed -e '/xTEMP/d' temp9 > temp10", "$VERBOSITY");
        run_system_cmd("cp temp10 $dir/nt_tech.sp", "$VERBOSITY");
        run_system_cmd("rm temp*", "$VERBOSITY");
        run_system_cmd("rm test", "$VERBOSITY");
    
        if ($is_bbox) {
            run_system_cmd("cd $dir; ln -s ${RootDir}/${CELL}/netlist/netlist_${beol}.spf netlist.sp", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ${RootDir}/${CELL}/netlist/netlist_sub.spf netlist_sub.sp", "$VERBOSITY");
        } else {
            run_system_cmd("cd $dir; ln -s ${RootDir}/${CELL}/netlist/netlist_${beol}.spf netlist.sp", "$VERBOSITY");
        }
        #run_system_cmd("cd $dir; ln -s ${RootDir}/${CELL}/run_sim_nt.csh run_sim.csh", "$VERBOSITY");
        $vtemp = $v;
        $vtemp =~ s/\./p/;
        $tim_corner = "${corner}${vtemp}v${temp}c";
        
        if ($is_etm eq "etm") {
            run_system_cmd("sed -e 's/<CORNER>/${tim_corner}/g' ${RootDir}/nt_files/run_etm.nt > temp1", "$VERBOSITY");
        } else {
            run_system_cmd("sed -e 's/<CORNER>/${tim_corner}/g' ${RootDir}/nt_files/run.nt > temp1", "$VERBOSITY");
        }
        my @read_db = read_file("db_mapping.txt");
        $dbcorner = "";
        foreach my $dbfile (@read_db) {
            chomp $dbfile;
            @fields = split / /, $dbfile;
            if (($corner eq $fields[0]) && ($v == $fields[1]) && ($temp == $fields[2])) {
                $dbcorner = $fields[3];
            }
        }
        run_system_cmd("sed -e 's/<DBCORNER>/${dbcorner}.db/g' temp1 > temp2", "$VERBOSITY");
        run_system_cmd("sed -e 's/<VDD>/${v}/g' temp2 > temp3", "$VERBOSITY");
        run_system_cmd("sed -e 's/<CELL>/$CELL/g' temp3 > temp4", "$VERBOSITY");
        run_system_cmd("sed -e 's/<BBOX>/$is_bbox/g' temp4 > temp5", "$VERBOSITY");
        run_system_cmd("sed -e 's|<ROOT>|${RootDir}|g' temp5 > temp6", "$VERBOSITY");
        run_system_cmd("sed -e 's/<CURRCORNER>/${curr_corner}/g' temp6 > temp7", "$VERBOSITY");
        run_system_cmd("sed -e 's/<METALSTACK>/${metal_stack}/g' temp7 > temp8", "$VERBOSITY");
        run_system_cmd("cp temp8 $dir/run.nt", "$VERBOSITY");
        run_system_cmd("rm temp*", "$VERBOSITY");
        if ($is_etm eq "etm") {
            run_system_cmd("sed -e 's/<CORNER>/${tim_corner}/g' ${RootDir}/nt_files/run_sim_etm_nt.csh > temp1", "$VERBOSITY");
            run_system_cmd("sed -e 's/<CELL>/${CELL}/g' temp1 > temp2", "$VERBOSITY");
            run_system_cmd("sed -e 's/<DIR>/${dir}/g' temp2 > temp3", "$VERBOSITY");
            run_system_cmd("sed -e 's/<METALSTACK>/${metal_stack}/g' temp3 > temp4", "$VERBOSITY");
            run_system_cmd("cp temp4 $dir/run_sim.csh", "$VERBOSITY");
            run_system_cmd("chmod +x $dir/run_sim.csh", "$VERBOSITY");
            run_system_cmd("rm temp*", "$VERBOSITY");
        }
        else {
            run_system_cmd("sed -e 's/CORNER>/${tim_corner}/g' ${RootDir}/nt_files/run_sim_nt.csh >temp1", "$VERBOSITY");
            run_system_cmd("cp temp1 $dir/run_sim.csh", "$VERBOSITY");
            run_system_cmd("chmod +x $dir/run_sim.csh", "$VERBOSITY");
            run_system_cmd("rm temp*", "$VERBOSITY");
        }
        push @RUNFILE, "#!/bin/csh\n\n";
        push @RUNFILE, "cd ${dir}\n";
        push @RUNFILE, "source run_sim.csh\n";
        push @RUNFILE, "cd ..\n";           
        if ($idx >= ($num-1)) {
            $end = 1;
        }    
        $idx++;
    }
    my $writefile_out = Util::Misc::write_file(\@RUNFILE, "$writefile");
    run_system_cmd("chmod +x $writefile", "$VERBOSITY");
}

sub print_usage {
    my $exit_status = shift;
    my $ScriptPath = shift;
    my $message_text = ("This is script is designed to create a series of NanoTime run scripts with different corner settings base on file 
                            \"corner_list.txt\". -pre or -post option set the simulation using schematic metlist or extracted netlist. [-mode] 
                            To create internal timing report, ignore this option. Put \"etm\" if need to create etm model, or put any mode name 
                            to create different Run* folders [-[no]bbox] Required if use any subckt lib.\n");
    pod2usage({
        -message => $message_text ,
        -exitval => $exit_status,
        -verbose => 0,
        }
    );
}

sub process_cmd_line_args(){
    my ( $opt_cell, $opt_is_etm, $opt_nousage, $opt_is_bbox, $opt_is_pre, $opt_is_post,
        $opt_help, $opt_dryrun, 
         $opt_debug,  $opt_verbosity );

    my $success = GetOptions(
        "cell=s" => \$opt_cell,
        "mode=s" => \$opt_is_etm,
        "bbox!"  => \$opt_is_bbox,
        "pre"    => \$opt_is_pre,
        "post"   => \$opt_is_post,
        "help"   => \$opt_help, 
        "nousage"     => \$opt_nousage,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "dryrun!"     => \$opt_dryrun,# Prints help
     );

    
    if((defined $opt_dryrun) && ($opt_dryrun == 1)){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &print_usage(0, "$RealBin/$PROGRAM_NAME") if $opt_help;
    &print_usage(1, "$RealBin/$PROGRAM_NAME") unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return( $opt_cell, $opt_is_etm, $opt_is_bbox, $opt_is_pre, $opt_is_post, $opt_help, $opt_nousage);
};

     

