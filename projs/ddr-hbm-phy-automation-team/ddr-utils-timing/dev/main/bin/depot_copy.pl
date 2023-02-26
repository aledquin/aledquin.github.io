#!/depot/perl-5.14.2/bin/perl


#################################################################
## Author        : Nandagopan G                                 #
## Functionality : LVF QA                                       # 
#################################################################



use strict;
use warnings;

use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     ;
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
#--------------------------------------------------------------------#

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log($LOGFILENAME);
   footer(); 
}


sub Main {
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);

   process_cmd_line_args();    

   
    
    my $dir = run_system_cmd("pwd", "$VERBOSITY");
    my $common;
    my @common_pvt = ();
    my $count;
    my $count1;
    my $count1_lvf;
    my $count_lvf;
    my $CPVT;
    my $db_lib_lvf_size_c;
    my $db_lib_size_c;
    my @db_lvf_size = ();
    my @db_pg_lvf_size = ();
    my @db_pg_size = ();
    my $db_pg_time;
    my @db_size = ();
    my $db_time;
    my $empty_lib_flag;
    my $empty_lib_lvf_flag;
    my $error_md;
    my $error_md_lvf;
    my $flag;
    my $flag_lvf;
    my $FR;
    my $FR_depot;
    my $FR_lvf_p4;
    my $FR_p4;
    my $grep_result_lib;
    my $grep_result_lib_lvf;
    my $grep_result_lib_pg;
    my $grep_result_lib_pg_lvf;
    my $i;
    my @lib_lvf_size = ();
    my @lib_lvf_wc = ();
    my $lib_lvf_wc_c = ();
    my $lib_name;
    my @lib_pg_lvf_size = ();
    my @lib_pg_lvf_wc = ();
    my @lib_pg_size = ();
    my $lib_pg_time;
    my @lib_pg_wc = ();
    my @lib_size = ();
    my $lib_time;
    my @lib_wc = ();
    my $lib_wc_c;
    my @lvf_file = ();
    my $lvf_file_count;
    my @lvf_file_work_area = ();
    my $lvf_file_work_area_count;
    my $match;
    my $match1;
    my $MDD;
    my $MDDEPOT;
    my $MDDEPOT_lvf;
    my $MDD_lvf;
    my $MDW;
    my $MDW_lvf;
    my $MDWORK;
    my $MDWORK_lvf;
    my $miss_compile;
    my $miss_compile_lvf;
    my $miss_depot_count;
    my $miss_dev_count;
    my @missing_depot = ();
    my $missing_depot_count;
    my @missing_dev = ();
    my $missing_dev_count;
    my $missing_files;
    my $missing_files_lvf;
    my @nldm_file = ();
    my $nldm_file_count;
    my @nldm_file_work_area = ();
    my $nldm_file_work_area_count;
    my $option;
    my $p;
    my $p4_edit_count;
    my $p4_edit_count_lvf;
    my $p4_var;
    my $p4_var_lvf;
    my $path;
    my $p_depot;
    my $p_dev;
    my $size_count_lib_db_flag;
    my $size_count_lib_db_lvf_flag;
    my $view;
    my $word_count_lib_flag;
    my $word_count_lib_lvf_flag;
    my $macro;
    chomp($dir);
    
    #$dir = $pwd;
    
   # if ($ARGV[0] eq "help")
   # {
    #  print ("Usage : depot_copy.pl <work area till macro directories are present> <macro name> <Metal Stack name/na if there is no MS> <lvf/nldm> \n");
    #  exit;
    #}
    #my $a = @ARGV;
   # if ($a != 4)
   # {
    #  print ("Please type \"depot_copy help\" for usage\n");
    #  exit;
    #}
    
    my $work_area = $ARGV[0];
    $macro = $ARGV[1];
    
    my $MS = $ARGV[2];
    chomp($MS);
    
    if (lc($MS) eq "na")
    {
      $lib_name = "${macro}";
    }
    else
    {
      $lib_name = "${macro}_${MS}";
    }
    
    $path = "$work_area/$macro";
    
    $view = $ARGV[3];
    
    chomp($view);
    
    ###########################
    #### Copying NLDM LIBS ####
    ###########################
    
    
    if (lc($view) eq "nldm")
    {
    
      run_system_cmd ("rm -rf copy_logs", "$VERBOSITY");
      
      run_system_cmd ("mkdir copy_logs", "$VERBOSITY");
      run_system_cmd ("touch copy_logs/lib_db_time_stamp", "$VERBOSITY");
      run_system_cmd ("touch copy_logs/lib_workarea_md5sum", "$VERBOSITY");
      run_system_cmd ("touch copy_logs/lib_depot_md5sum", "$VERBOSITY");
      
      @nldm_file = run_system_cmd ("ls $dir/lib_pg/${lib_name}*_pg.lib", "$VERBOSITY");
      
      $nldm_file_count = @nldm_file;
    
      if ($nldm_file_count != 0)
      {
        run_system_cmd ("ls lib_pg/${lib_name}*.lib | cut -d '.' -f1 | rev | cut -d '_' -f2 | rev | sort -u > pvt_depot", "$VERBOSITY");
      }
      else 
      {
        eprint ("Please Sync correct libs from Depot or Please check if you are in correct MACRO Folder\n");
        eprint ("EXITING....\n");
        exit;
      }
      
      @nldm_file_work_area = run_system_cmd ("ls $path/lib_pg/${lib_name}*_pg.lib", "$VERBOSITY");
      
      $nldm_file_work_area_count = @nldm_file_work_area;
      #print "$nldm_file_work_area_count\n";
      
      if ($nldm_file_work_area_count != 0)
      {
        run_system_cmd ("ls $path/lib_pg/${lib_name}*.lib | rev| cut -d '.' -f2 |  cut -d '_' -f2 | rev | sort -u > pvt_dev", "$VERBOSITY");
      }
      else 
      {
        eprint ("Please check if ${macro} has correct libs or ${macro} folder is available in the given path\n");
        eprint ("EXITING....\n");
        exit;
      }
      #
      #if (-z "$dir/pvt_depot" || -z "$dir/pvt_dev")
      #{
      #  if (-z "$dir/pvt_depot")
      #  {
      #    print ("Please Check if you are in correct depot path of $macro\n");
      #    exit;
      #  }
      #  else
      #  {
      #    print ("Please Check if your workarea has libs of $macro\n");
      #    exit;
      #  }
      #}
      
      #open ($FR_depot, "<pvt_depot");
      my @FR_depot = read_file("pvt_depot");
      $match = 0;
      $common = 0;
      $miss_dev_count = 0;
      outer_loop : 
      foreach my $p_depot (@FR_depot)
      {
        #open ($FR, "<pvt_dev");
	#while ($p_dev = <$FR>)
	my @FR = read_file("pvt_dev");
	foreach my $p_dev (@FR)
        { 
      
          chomp($p_depot);
          chomp($p_dev);
      
          if ($p_dev eq $p_depot)
          {
            $common_pvt[$common] = "$p_depot\n";
            $common = $common + 1;
            goto outer_loop;
          }
        }
        
        $match = $match + 1;
        $missing_dev[$miss_dev_count] = "$p_depot\n";
        $miss_dev_count = $miss_dev_count + 1;
      
      }
      
      
      
      #open ($FR, "<pvt_dev");
      my @FR = read_file("pvt_dev");
      $match1 = 0;
      $miss_depot_count = 0;
      outer_loop1 :
      #while ($p_dev = <$FR>)
      foreach my $p_dev (@FR)
      {
        #open ($FR_depot, "<pvt_depot");
        #while ($p_depot = <$FR_depot>)
	my @FR_depot = read_file("pvt_depot");
        foreach my $p_depot (@FR_depot)	
        {
          chomp($p_depot);
          chomp($p_dev);
          
          if ($p_dev eq $p_depot)
          {
            goto outer_loop1;
          }
        }
        
        $match1 = $match1 + 1;
        $missing_depot[$miss_depot_count] = "$p_dev\n";
        $miss_depot_count = $miss_depot_count + 1;
      }
      #$missing_depot[0] = " $missing_depot[0]";
     
      if ($match != 0 || $match1 != 0)
      {
        #print ("Mismatch in depot and development area PVT. Please check mismatch_pvt.txt for more info\n");
        
        if ($match1 != 0)
        {
          wprint ("$match1 PVT missing in depot compared to development area\n ");
          #run_system_cmd ("echo 'PVT missing in depot compared to development area'", "$VERBOSITY");
          #chomp(@missing_depot);
          wprint ("@missing_depot");
        }
      
        if ($match != 0)
        {
          wprint ("$match PVT missing in development area compared to depot area\n ");
          wprint ("@missing_dev");
        }
      
      
        iprint ("Do you wish to continue copying common PVTs [Y/N] : \n");
        $option = <STDIN>;
        chomp($option);
      
        if (lc($option) eq "y")
        {
           nprint ("COPYING COMMON PVT. Common PVT will be found in copy_logs/pvt file ....\n");
           
           $count = @common_pvt;
           
           $i = 0;
      
           run_system_cmd ("touch pvt", "$VERBOSITY");
      
          # open ($CPVT, ">>pvt");
           while ($i<$count)
           {
              #run_system_cmd ("echo '$common_pvt[$i]' >> pvt", "$VERBOSITY");
              
              #print $CPVT $common_pvt[$i];
	      my $CPVT1 = write_file("$common_pvt[$i]","pvt");
      
              $i = $i + 1;
           }
        }
        else 
        {
          run_system_cmd ("mv pvt_dev copy_logs/", "$VERBOSITY");
          run_system_cmd ("mv pvt_depot copy_logs/", "$VERBOSITY");
      
          eprint ("NOT COPYING..... EXITING....\n");
          exit;
        }
      
      }
      
      else
      {
        run_system_cmd ("cp -rf pvt_depot pvt", "$VERBOSITY");
      }
      
      
      $flag = 0;
      
      #open ($FR, "<pvt");
     # while ($p = <$FR>)
      my @FR1 = read_file("pvt");
      foreach my $p (@FR1)
      {
        chomp($p);
        
        
      
        run_system_cmd ("echo '$p' >> copy_logs/lib_db_time_stamp", "$VERBOSITY");
        #run_system_cmd ("echo '$p' >> lib_db_time_stamp", "$VERBOSITY");
      
        $lib_pg_time = run_system_cmd ("stat -c %Y $path/lib_pg/*${lib_name}_${p}*.lib", "$VERBOSITY");
        $lib_time = run_system_cmd ("stat -c %Y $path/lib/*${lib_name}_${p}*.lib", "$VERBOSITY");
        $db_pg_time = run_system_cmd ("stat -c %Y $path/lib_pg/*${lib_name}_${p}*.db", "$VERBOSITY");
        $db_time = run_system_cmd ("stat -c %Y $path/lib/*${lib_name}_${p}*.db", "$VERBOSITY");
      
        if ($lib_pg_time > $db_pg_time || $lib_time > $db_time)
        {
           run_system_cmd ("echo 'ISSUE : PLEASE COMPILE AGAIN and do complete QA at development area' >> copy_logs/lib_db_time_stamp", "$VERBOSITY"); 
           $flag = 1;
        }
      
      
      }
      
      
      if ($flag == 0)
      {
    
        #$pfour = 0;
        $missing_files = 0;  
        $p4_edit_count = 0;
        $miss_compile = 0;
    
        iprint ("ABOUT TO PERFORM P4 EDIT...\n");
    
        run_system_cmd ("touch copy_logs/p4_commands", "$VERBOSITY"); 
        #open ($FR, "<pvt");
        #while ($p = <$FR>)
        my @FR = read_file("pvt");
        foreach my $p (@FR)	
        {
          chomp($p);
      
    
         if (-e "$dir/lib_pg/${lib_name}_${p}_pg.lib" && -e "$dir/lib_pg/${lib_name}_${p}_pg.db" && -e "$dir/lib/${lib_name}_${p}.lib" && -e "$dir/lib/${lib_name}_${p}.db")  
         { 
           
           
           
           if ($p4_edit_count < 1 && -e "$dir/lib/compile.log" && -e "$dir/lib_pg/compile.log")
           {
             run_system_cmd ("p4 edit $dir/lib_pg/compile.log $dir/lib/compile.log >> copy_logs/p4_commands", "$VERBOSITY");
             $p4_edit_count = $p4_edit_count + 1;
           }
    
           if ($p4_edit_count == 0 && $miss_compile == 0)
           {
              wprint ("compile.log IS NOT SEEDED FOR LIB OR LIB_PG OR BOTH. SO IT WILL NOT BE CHECKED_IN. PLEASE INFORM MANAGER\n");
              $miss_compile = $miss_compile + 1;
           }
    
           run_system_cmd ("p4 edit $dir/lib_pg/${lib_name}_${p}_pg.lib $dir/lib_pg/${lib_name}_${p}_pg.db $dir/lib/${lib_name}_${p}.lib $dir/lib/${lib_name}_${p}.db >> copy_logs/p4_commands", "$VERBOSITY");
           run_system_cmd ("\\cp -rf $path/lib_pg/${lib_name}_${p}_pg.lib lib_pg/.", "$VERBOSITY");
           run_system_cmd ("rm -rf $dir/lib_pg/${lib_name}_${p}_pg.db", "$VERBOSITY");
           #run_system_cmd ("\\cp -rf $path/lib_pg/${lib_name}_${p}_pg.db lib_pg/.", "$VERBOSITY");
           run_system_cmd ("\\cp -rf $path/lib/${lib_name}_${p}.lib lib/.", "$VERBOSITY");
           run_system_cmd ("rm -rf $dir/lib/${lib_name}_${p}.db", "$VERBOSITY");
           #run_system_cmd ("\\cp -rf $path/lib/${lib_name}_${p}.db lib/."), "$VERBOSITY";
           
          
           ## For Testing ##
    
           #if (${p} eq "ffg0p88v0c")
           #{
           # run_system_cmd ("sed -i '1d' /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88v0c_pg.lib", "$VERBOSITY"); 
           # run_system_cmd ("sed -i '1d' /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88v0c_pg.db", "$VERBOSITY"); 
           #}
    
           ## Testing Ends ##
    
           run_system_cmd ("md5sum $path/lib_pg/${lib_name}_${p}_pg.lib >> copy_logs/lib_workarea_md5sum", "$VERBOSITY");
           #run_system_cmd ("md5sum $path/lib_pg/${lib_name}_${p}_pg.db >> copy_logs/lib_workarea_md5sum", "$VERBOSITY");
           run_system_cmd ("md5sum $path/lib/${lib_name}_${p}.lib >> copy_logs/lib_workarea_md5sum", "$VERBOSITY");
           #run_system_cmd ("md5sum $path/lib/${lib_name}_${p}.db >> copy_logs/lib_workarea_md5sum", "$VERBOSITY");
           
           run_system_cmd ("md5sum lib_pg/${lib_name}_${p}_pg.lib >> copy_logs/lib_depot_md5sum", "$VERBOSITY");
           #run_system_cmd ("md5sum lib_pg/${lib_name}_${p}_pg.db >> copy_logs/lib_depot_md5sum", "$VERBOSITY");
           run_system_cmd ("md5sum lib/${lib_name}_${p}.lib >> copy_logs/lib_depot_md5sum", "$VERBOSITY");
           #run_system_cmd ("md5sum lib/${lib_name}_${p}.db >> copy_logs/lib_depot_md5sum", "$VERBOSITY");
         } 
         else
         {   
           nprint ("$dir/lib_pg/${lib_name}_${p}_pg.lib or $dir/lib_pg/${lib_name}_${p}_pg.db or $dir/lib/${lib_name}_${p}.lib or $dir/lib/${lib_name}_${p}.db is not Present\n");
           wprint ("NOT COPYING THE ABOVE PVTS\n");
           $missing_files = 1;
         }
      
       }
       
        
         if ($missing_files == 1)
         {
            iprint ("PLEASE SYNC THE MISSING VIEWS AND RE_RUN\n");
            exit;
         }
    
         $error_md = 0;
         ## Added newly ##
         run_system_cmd ("cat copy_logs/lib_workarea_md5sum | awk '{print \$1}' > copy_logs/lib_workarea_md5sum_temp", "$VERBOSITY");
         run_system_cmd ("cat copy_logs/lib_depot_md5sum | awk '{print \$1}' > copy_logs/lib_depot_md5sum_temp", "$VERBOSITY");
         #open ($MDWORK,"<copy_logs/lib_workarea_md5sum_temp");
         my @MDWORK = read_file ("copy_logs/lib_workarea_md5sum_temp");
	 
         $count = 0;
         MD5W : 
         #while ($MDW = <$MDWORK>)
	 foreach my $MDW (@MDWORK)
         {
            #open ($MDDEPOT,"<copy_logs/lib_depot_md5sum_temp");
            my @MDDEPOT = read_file("copy_logs/lib_depot_md5sum_temp");
            $count1 = 0;
    
            #while ($MDD = <$MDDEPOT>)
	    foreach my $MDD (@MDDEPOT)
            {
              
              if ($count == $count1)
              {
                if ("$MDW" eq "$MDD")
                {
                }
                else
                {
                  $error_md = $error_md + 1;
                }
      
                $count = $count + 1;
                goto MD5W;
      
              }
              $count1 = $count1 + 1;
            }
      
         }
      
      
         run_system_cmd ("rm -rf copy_logs/lib_depot_md5sum_temp copy_logs/lib_workarea_md5sum_temp", "$VERBOSITY");
      
         if ($error_md == 0)
         {
             
            run_system_cmd ("PERFORMING COMPILATION.....\n", "$VERBOSITY");
            chdir "$dir/lib_pg";
            run_system_cmd ("perl $RealBin/alphaCompileLibs.pl", "$VERBOSITY");
            chdir "$dir/lib";
            run_system_cmd ("perl $RealBin/alphaCompileLibs.pl", "$VERBOSITY");
            chdir "$dir";
    
            ## Testing ##
            #run_system_cmd ("echo 'error' >> $dir/lib_pg/compile.log", "$VERBOSITY");
            
            $grep_result_lib = `grep -i error $dir/lib/compile.log | head -1`;  
            $grep_result_lib_pg = `grep -i error $dir/lib_pg/compile.log | head -1`;
    
            if (lc ($grep_result_lib) =~ /error/ || lc ($grep_result_lib_pg) =~ /error/)
            {
              run_system_cmd ("grep -i error $dir/lib/compile.log > copy_logs/compile_error", "$VERBOSITY");
              run_system_cmd ("grep -i error $dir/lib_pg/compile.log >> copy_logs/compile_error", "$VERBOSITY");
              eprint ("COMPILATION HAS ERRORS. P4 REVERTING... PLEASE CHECK copy_logs/compile_error FOR MORE INFO. PLEASE CORRECT AND RE_RUN\n");
              if ($p4_edit_count == 1)
              { 
                run_system_cmd ("p4 revert $dir/lib/compile.log $dir/lib_pg/compile.log >> copy_logs/p4_commands", "$VERBOSITY");
              }
              run_system_cmd ("p4 revert $dir/lib/... $dir/lib_pg/... >> copy_logs/p4_commands", "$VERBOSITY");
              exit;
            }
            
            if ($p4_edit_count == 0)
            {
               #run_system_cmd ("rm -rf $dir/lib/compile.log $dir/lib_pg/compile.log", "$VERBOSITY"); 
            }
    
            iprint ("Performing SIZE CHECK and WORD COUNT CHECK AFTER COPYING and COMPILING....\n");
            run_system_cmd ("mv pvt copy_logs/", "$VERBOSITY");
            run_system_cmd ("mv pvt_dev copy_logs/", "$VERBOSITY");
            run_system_cmd ("mv pvt_depot copy_logs/", "$VERBOSITY");
            
            run_system_cmd ("touch copy_logs/lib_wc", "$VERBOSITY");
            run_system_cmd ("touch copy_logs/lib_size", "$VERBOSITY");
            run_system_cmd ("touch copy_logs/db_size", "$VERBOSITY");
            run_system_cmd ("touch copy_logs/lib_pg_wc", "$VERBOSITY");
            run_system_cmd ("touch copy_logs/lib_pg_size", "$VERBOSITY");
            run_system_cmd ("touch copy_logs/db_pg_size", "$VERBOSITY");
            run_system_cmd ("touch copy_logs/empty_pvt", "$VERBOSITY");
       
            # Used for testing #
            #run_system_cmd ("sed -i '1d' /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88v0c_pg.lib", "$VERBOSITY");
            #run_system_cmd ("rm -rf /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88v0c_pg.lib", "$VERBOSITY");
            #run_system_cmd ("touch /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88v0c_pg.lib", "$VERBOSITY");
      
            $lib_wc_c = 0;
            $db_lib_size_c = 0;
            $empty_lib_flag = 0;
            $word_count_lib_flag = 0;
            $size_count_lib_db_flag = 0;
    
            #open ($FR_p4, "<copy_logs/pvt");
            #while ($p4_var = <$FR_p4>)
	    my @FR_p4 = read_file("copy_logs/pvt");
	    foreach my $p4_var (@FR_p4)
            {
              chomp($p4_var);
              run_system_cmd ("wc lib/${lib_name}_${p4_var}.lib >> copy_logs/lib_wc", "$VERBOSITY");
              run_system_cmd ("du -ch lib/${lib_name}_${p4_var}.lib | grep -v total >> copy_logs/lib_size", "$VERBOSITY");
              run_system_cmd ("du -ch lib/${lib_name}_${p4_var}.db | grep -v total >> copy_logs/db_size", "$VERBOSITY");
              run_system_cmd ("wc lib_pg/${lib_name}_${p4_var}_pg.lib >> copy_logs/lib_pg_wc", "$VERBOSITY");
              run_system_cmd ("du -ch lib_pg/${lib_name}_${p4_var}_pg.lib | grep -v total >> copy_logs/lib_pg_size", "$VERBOSITY");
              run_system_cmd ("du -ch lib_pg/${lib_name}_${p4_var}_pg.db | grep -v total >> copy_logs/db_pg_size", "$VERBOSITY");
              
              $lib_wc[$lib_wc_c] = `wc lib/${lib_name}_${p4_var}.lib | awk '{print \$1}'`;
              $lib_pg_wc[$lib_wc_c] = `wc lib_pg/${lib_name}_${p4_var}_pg.lib | awk '{print \$1}'`;
              
              $lib_size[$db_lib_size_c] = `du -ch lib/${lib_name}_${p4_var}.lib | grep -v total | awk '{print \$1}'`;
              $db_size[$db_lib_size_c] = `du -ch lib/${lib_name}_${p4_var}.db | grep -v total | awk '{print \$1}'`;
              $lib_pg_size[$db_lib_size_c] = `du -ch lib_pg/${lib_name}_${p4_var}_pg.lib | grep -v total | awk '{print \$1}'`;
              $db_pg_size[$db_lib_size_c] = `du -ch lib_pg/${lib_name}_${p4_var}_pg.db | grep -v total | awk '{print \$1}'`;
              
              
              if (-z "lib/${lib_name}_${p4_var}.lib" || -z "lib_pg/${lib_name}_${p4_var}_pg.lib" || -z "lib/${lib_name}_${p4_var}.db" || -z "lib_pg/${lib_name}_${p4_var}_pg.db")
              {
               $empty_lib_flag = 1;
               #run_system_cmd ("echo '${p4_var}' >>  copy_logs/empty_pvt", "$VERBOSITY");
              }
              else {
                     if ($db_lib_size_c > 0)
                     {
                      chomp($lib_size[$db_lib_size_c]);
                      chomp($lib_pg_size[$db_lib_size_c]);
                      chomp($db_size[$db_lib_size_c]);
                      chomp($db_pg_size[$db_lib_size_c]);
                      chomp($lib_size[$db_lib_size_c - 1]);
                      chomp($lib_pg_size[$db_lib_size_c - 1]);
                      chomp($db_size[$db_lib_size_c - 1]);
                      chomp($db_pg_size[$db_lib_size_c - 1]);
                
                      if (($lib_size[$db_lib_size_c] != $lib_size[$db_lib_size_c - 1]) || ($db_size[$db_lib_size_c] != $db_size[$db_lib_size_c - 1]) || ($lib_pg_size[$db_lib_size_c] != $lib_pg_size[$db_lib_size_c - 1]) || ($db_pg_size[$db_lib_size_c] != $db_pg_size[$db_lib_size_c - 1]))
                      {
                        $size_count_lib_db_flag = 1;
                      }
                    }
      
                    $db_lib_size_c = $db_lib_size_c + 1;
                  } 
                    
      
              if ($lib_wc_c > 0)
              {
                chomp($lib_wc[$lib_wc_c]);
                chomp($lib_pg_wc[$lib_wc_c]);
                chomp($lib_wc[$lib_wc_c - 1]);
                chomp($lib_pg_wc[$lib_wc_c - 1]);
                
                if (($lib_pg_wc[$lib_wc_c] != $lib_pg_wc[$lib_wc_c - 1]) || ($lib_wc[$lib_wc_c] != $lib_wc[$lib_wc_c - 1]))
                {
                  $word_count_lib_flag = 1;
                }
              }
      
              $lib_wc_c = $lib_wc_c + 1;
            }
      
            if ($empty_lib_flag == 1 || $word_count_lib_flag == 1 || $size_count_lib_db_flag == 1)
            {
              if ($empty_lib_flag == 1)
              {
                wprint ("THERE ARE ZERO SIZED LIBS. PLEASE REVIEW copy_logs/lib_size and copy_logs/lib_pg_size FOR MORE INFO\n");
                wprint ("PLEASE FIX AND RE-RUN IF ITS ISSUE AT WORKAREA or RE-RUN THE SCRIPT IF WORKAREA IS CLEAN\n");
                if ($p4_edit_count == 1)
                { 
                  run_system_cmd ("p4 revert $dir/lib/compile.log $dir/lib_pg/compile.log >> copy_logs/p4_commands", "$VERBOSITY");
                }
                run_system_cmd ("p4 revert $dir/lib/... $dir/lib_pg/... >> copy_logs/p4_commands", "$VERBOSITY");
              }
      
              if ($word_count_lib_flag == 1)
              {
                wprint ("THERE ARE WORD COUNT MISMATCHES IN THE LIBS. PLEASE REVIEW  copy_logs/lib_wc and copy_logs/lib_pg_wc FOR MORE INFO\n");
                wprint ("PLEASE FIX AND RE-RUN IF ITS ISSUE AT WORKAREA or RE-RUN THE SCRIPT IF WORKAREA IS CLEAN\n");
                if ($p4_edit_count == 1)
                { 
                  run_system_cmd ("p4 revert $dir/lib/compile.log $dir/lib_pg/compile.log >> copy_logs/p4_commands", "$VERBOSITY");
                }
                run_system_cmd ("p4 revert $dir/lib/... $dir/lib_pg/... >> copy_logs/p4_commands", "$VERBOSITY");
              }
    
              if ($size_count_lib_db_flag == 1)
              {
                wprint ("THERE ARE SIZE MISMATCHES IN THE LIBS OR DBS. PLEASE REVIEW  copy_logs/lib_size, copy_logs/db_size, copy_logs/lib_pg_size and copy_logs/db_pg_size FOR MORE INFO. Please perform p4 submit if these are fine.\n");
              }
            }
      
            else 
            {
              iprint ("PLEASE VERIFY USING \"p4 opened\" and submit using \"p4 submit -d 'Releasing <release_version> of macro $macro to depot' $dir/...\"\n");
            }
      
       
      
         }
      
         else
         {
            iprint ("COPYING NOT DONE PROPERLY FOR ${error_md} FILES . PLEASE RE_RUN AGAIN\n");
            iprint ("PLEASE COMPARE LIB_WORKAREA_MD5SUM LIB_DEPOT_MD5SUM FILES IN copy_logs FOLDER TO CHECK THE ISSUE FILES\n");
            if ($p4_edit_count == 1)
            { 
               run_system_cmd ("p4 revert $dir/lib/compile.log $dir/lib_pg/compile.log >> copy_logs/p4_commands", "$VERBOSITY");
            }
            run_system_cmd ("p4 revert $dir/lib/... $dir/lib_pg/... >> copy_logs/p4_commands", "$VERBOSITY"); 
            run_system_cmd ("mv pvt copy_logs/", "$VERBOSITY");
            run_system_cmd ("mv pvt_dev copy_logs/", "$VERBOSITY");
            run_system_cmd ("mv pvt_depot copy_logs/", "$VERBOSITY");
         } 
    
    
      }
      
      
    
       else 
       {
           ## Added newly ##
           eprint ("THERE ARE ERRORS IN LIB AND DB TIME STAMP. COPYING TERMINATED\n");
           iprint ("PLEASE COMPILE ALL THE LIBS OR ISSUE LIBS ALSO PERFORM WHOLE SET OF QA at PRODUCTION AREA AND RE-RUN THE DEPOT SCRIPT\n");
           iprint ("PLEASE OPEN 'copy_logs/lib_db_time_stamp' FOR MORE INFO\n");
          
           run_system_cmd ("mv pvt copy_logs/", "$VERBOSITY");
           run_system_cmd ("mv pvt_dev copy_logs/", "$VERBOSITY");
           run_system_cmd ("mv pvt_depot copy_logs/", "$VERBOSITY");
           exit;
       }
      
    }   
      
     
    
    ##########################
    #### Copying LVF LIBS ####
    ##########################
    
    else 
    {
    
      run_system_cmd ("rm -rf copy_logs_lvf", "$VERBOSITY");
      
      run_system_cmd ("mkdir copy_logs_lvf", "$VERBOSITY");
      run_system_cmd ("touch copy_logs_lvf/lvf_lib_db_time_stamp", "$VERBOSITY");
      run_system_cmd ("touch copy_logs_lvf/lvf_lib_workarea_md5sum", "$VERBOSITY");
      run_system_cmd ("touch copy_logs_lvf/lvf_lib_depot_md5sum", "$VERBOSITY");
      
      
      @lvf_file = `ls $dir/lib_pg_lvf/${lib_name}*_pg.lib`;
      
      $lvf_file_count = @lvf_file;
      
      #print ("$lvf_file_count\n");
      
      if ($lvf_file_count != 0)
      {
        run_system_cmd ("ls lib_pg_lvf/${lib_name}*.lib | cut -d '.' -f1 | rev | cut -d '_' -f2 | rev | sort -u > pvt_depot", "$VERBOSITY");
      }
      else 
      {
        eprint ("Please Sync correct libs from Depot or Please check if you are in correct MACRO Folder\n");
        eprint ("EXITING....\n");
        exit;
      }
      
      @lvf_file_work_area = `ls $path/lib_pg/${lib_name}*_pg.lib`;
      
      $lvf_file_work_area_count = @lvf_file_work_area;
      
      #print "$lvf_file_work_area_count\n";
      
      if ($lvf_file_work_area_count != 0)
      {
        run_system_cmd ("ls $path/lib_pg/${lib_name}*.lib | rev| cut -d '.' -f2 |  cut -d '_' -f2 | rev | sort -u > pvt_dev", "$VERBOSITY");
      }
      else 
      {
        eprint ("Please check if ${macro} has correct libs or ${macro} folder is available in the given path\n");
        eprint ("EXITING....\n");
        exit;
      }
      
     # open ($FR_depot, "<pvt_depot");
      my @FR_depot = read_file("pvt_depot");

      $match = 0;
      $common = 0;
      $missing_dev_count = 0;
      outer_loop_lvf : 
     # while ($p_depot = <$FR_depot>)
      foreach my $p_depot (@FR_depot)
      {
        #open ($FR, "<pvt_dev");
        #while ($p_dev = <$FR>)
	
	my @FR = read_file("pvt_dev");
        foreach my $p_dev (@FR)
        {
      
          chomp($p_dev);
          chomp($p_depot);
          
          if ($p_dev eq $p_depot)
          {
            $common_pvt[$common] = "$p_depot\n";
            $common = $common + 1;
            goto outer_loop_lvf;
          }
        }
        
        $match = $match + 1;
        $missing_dev[$missing_dev_count] = "$p_depot\n";
        $missing_dev_count = $missing_dev_count + 1;
      
      }
      
      
      
      #open ($FR, "<pvt_dev");
      my @FR = read_file ("pvt_dev");
      $match1 = 0;
      $missing_depot_count = 0;
      outer_loop1_lvf :
      #while ($p_dev = <$FR>)
      foreach my $p_dev( @FR)
      {
        #open ($FR_depot, "<pvt_depot");
	#####while ($p_depot = <$FR_depot>)
	my @FR_depot = read_file("pvt_depot");
	foreach my $p_depot (@FR_depot)
        {
      
          chomp($p_depot);
          chomp($p_dev);
      
          if ($p_dev eq $p_depot)
          {
            goto outer_loop1_lvf;
          }
        }
        
        $match1 = $match1 + 1;
        $missing_depot[$missing_depot_count] = "$p_dev\n";
        $missing_depot_count = $missing_depot_count + 1;
      
      }
      
      
      if ($match != 0 || $match1 != 0)
      {
        #print ("Mismatch in depot and development area PVT. Please check mismatch_pvt.txt for more info\n");
        
        if ($match1 !=0)
        {
          wprint ("$match1 PVT missing in depot compared to development area\n ");
          #run_system_cmd ("echo 'PVT missing in depot compared to development area'", "$VERBOSITY");
          wprint ("@missing_depot\n");
        }
      
        if ($match !=0)
        {
          wprint ("$match PVT missing in development area compared to depot area\n ");
          wprint ("@missing_dev\n");
        }
      
      
        iprint ("Do you wish to continue copying common PVTs [Y/N] : \n");
        $option = <STDIN>;
        chomp($option);
      
        if (lc($option) eq "y")
        {
           nprint ("COPYING COMMON PVT. Common PVT will be found in copy_logs_lvf/pvt file ....\n");
           
           $count = @common_pvt;
           
           $i = 0;
      
           run_system_cmd ("touch pvt", "$VERBOSITY");
      
           #open ($CPVT, ">>pvt");
           while ($i<$count)
           {
              #run_system_cmd ("echo '$common_pvt[$i]' >> pvt", "$VERBOSITY");
              
              #print $CPVT $common_pvt[$i];
	      my $CPVT1 = write_file("$common_pvt[$i]","pvt");
      
              $i = $i + 1;
           }
      
      
        }
        else 
        {
          run_system_cmd ("mv pvt_dev copy_logs_lvf/", "$VERBOSITY");
          run_system_cmd ("mv pvt_depot copy_logs_lvf/", "$VERBOSITY");
      
          eprint ("NOT COPYING..... EXITING....\n");
          exit;
        }
      
      }
      
      else
      {
        run_system_cmd ("cp -rf pvt_depot pvt", "$VERBOSITY");
      }
      
      
      $flag_lvf = 0;
      
      #open ($FR, "<pvt");
      #while ($p = <$FR>)
      my @FR_2 = read_file("PVT");
      foreach my $p (@FR_2)
      {
        chomp($p);
        
        $lib_pg_time = `stat -c %Y $path/lib_pg/*${lib_name}_${p}*.lib`;
        $lib_time = `stat -c %Y $path/lib/*${lib_name}_${p}*.lib`;
        $db_pg_time = `stat -c %Y $path/lib_pg/*${lib_name}_${p}*.db`;
        $db_time = `stat -c %Y $path/lib/*${lib_name}_${p}*.db`;
      
        run_system_cmd ("echo '$p' >> copy_logs_lvf/lvf_lib_db_time_stamp", "$VERBOSITY");
        #run_system_cmd ("echo '$p' >> lib_db_time_stamp", "$VERBOSITY");
      
        
      
        if ($lib_pg_time > $db_pg_time || $lib_time > $db_time)
        {
           run_system_cmd ("echo 'ISSUE : PLEASE COMPILE AGAIN and do complete QA at development area' >> copy_logs_lvf/lvf_lib_db_time_stamp", "$VERBOSITY"); 
           $flag_lvf = 1;
        }
      
      }
      
      
      
      if ($flag_lvf == 0)
      {
        #$pfour = 0;
        $p4_edit_count_lvf = 0;
        $missing_files_lvf = 0;
        $miss_compile_lvf = 0;
    
        nprint ("ABOUT TO PERFORM P4 EDIT...\n");
    
        run_system_cmd ("touch copy_logs_lvf/p4_commands", "$VERBOSITY");
        #open ($FR, "<pvt");
        #while ($p = <$FR>)
	my @FR_3 = read_file("pvt");
	foreach my $p (@FR_3)
        {
          chomp($p);
      
    
         if (-e "$dir/lib_pg_lvf/${lib_name}_${p}_pg.lib" && -e "$dir/lib_pg_lvf/${lib_name}_${p}_pg.db" && -e "$dir/lib_lvf/${lib_name}_${p}.lib" && -e "$dir/lib_lvf/${lib_name}_${p}.lib")  
         { 
           
          
           if ($p4_edit_count_lvf < 1 && -e "$dir/lib_pg_lvf/compile.log" && -e "$dir/lib_lvf/compile.log")
           {
             run_system_cmd ("p4 edit $dir/lib_pg_lvf/compile.log $dir/lib_lvf/compile.log >> copy_logs_lvf/p4_commands", "$VERBOSITY");
             $p4_edit_count_lvf = $p4_edit_count_lvf + 1;
           }
    
           if ($p4_edit_count_lvf == 0 && $miss_compile_lvf == 0)
           {
              print ("compile.log IS NOT SEEDED FOR LIB_LVF OR LIB_PG_LVF OR BOTH. SO IT WILL NOT BE CHECKED_IN. PLEASE INFORM MANAGER\n");
              $miss_compile_lvf = $miss_compile_lvf + 1;
           } 
    
           run_system_cmd ("p4 edit $dir/lib_pg_lvf/${lib_name}_${p}_pg.lib $dir/lib_pg_lvf/${lib_name}_${p}_pg.db $dir/lib_lvf/${lib_name}_${p}.lib $dir/lib_lvf/${lib_name}_${p}.db >> copy_logs_lvf/p4_commands", "$VERBOSITY");
           run_system_cmd ("\\cp -rf $path/lib_pg/${lib_name}_${p}_pg.lib lib_pg_lvf/.", "$VERBOSITY");
           run_system_cmd ("rm -rf $dir/lib_pg_lvf/${lib_name}_${p}_pg.db", "$VERBOSITY");
           #run_system_cmd ("\\cp -rf $path/lib_pg/${lib_name}_${p}_pg.db lib_pg_lvf/.", "$VERBOSITY");
           run_system_cmd ("\\cp -rf $path/lib/${lib_name}_${p}.lib lib_lvf/.", "$VERBOSITY");
           run_system_cmd ("rm -rf $dir/lib_lvf/${lib_name}_${p}_pg.db", "$VERBOSITY");
           #run_system_cmd ("\\cp -rf $path/lib/${lib_name}_${p}.db lib_lvf/.", "$VERBOSITY");
      
           
           ## For Testing ##
    
           #if (${p} eq "ffg0p88vn40c")
           #{
           # run_system_cmd ("sed -i '1d' /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg_lvf/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88vn40c_pg.lib", "$VERBOSITY"); 
           # run_system_cmd ("sed -i '1d' /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_lvf/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88vn40c.db", "$VERBOSITY"); 
           #}
    
           ## Testing Ends ##
    
           run_system_cmd ("md5sum $path/lib_pg/${lib_name}_${p}_pg.lib >> copy_logs_lvf/lvf_lib_workarea_md5sum", "$VERBOSITY");
           #run_system_cmd ("md5sum $path/lib_pg/${lib_name}_${p}_pg.db >> copy_logs_lvf/lvf_lib_workarea_md5sum", "$VERBOSITY");
           run_system_cmd ("md5sum $path/lib/${lib_name}_${p}.lib >> copy_logs_lvf/lvf_lib_workarea_md5sum", "$VERBOSITY");
           #run_system_cmd ("md5sum $path/lib/${lib_name}_${p}.db >> copy_logs_lvf/lvf_lib_workarea_md5sum", "$VERBOSITY");
           
           run_system_cmd ("md5sum lib_pg_lvf/${lib_name}_${p}_pg.lib >> copy_logs_lvf/lvf_lib_depot_md5sum", "$VERBOSITY");
           #run_system_cmd ("md5sum lib_pg_lvf/${lib_name}_${p}_pg.db >> copy_logs_lvf/lvf_lib_depot_md5sum", "$VERBOSITY");
           run_system_cmd ("md5sum lib_lvf/${lib_name}_${p}.lib >> copy_logs_lvf/lvf_lib_depot_md5sum", "$VERBOSITY");
           #run_system_cmd ("md5sum lib_lvf/${lib_name}_${p}.db >> copy_logs_lvf/lvf_lib_depot_md5sum", "$VERBOSITY");
         }
      
         else
         {
           wprint ("$dir/lib_pg_lvf/${lib_name}_${p}_pg.lib or $dir/lib_pg_lvf/${lib_name}_${p}_pg.db or $dir/lib_lvf/${lib_name}_${p}.lib or $dir/lib_lvf/${lib_name}_${p}.db is not Present\n");
           wprint ("NOT COPYING THE ABOVE LIBS\n"); 
           $missing_files_lvf = 1;
         }
        }
         
         if ($missing_files_lvf == 1)
         {
            eprint ("PLEASE SYNC THE MISSING VIEWS AND RE_RUN\n");
            exit;
         }
    
         $error_md_lvf = 0;
         ## Added newly ##
         run_system_cmd ("cat copy_logs_lvf/lvf_lib_workarea_md5sum | awk '{print \$1}' > copy_logs_lvf/lvf_lib_workarea_md5sum_temp", "$VERBOSITY");
         run_system_cmd ("cat copy_logs_lvf/lvf_lib_depot_md5sum | awk '{print \$1}' > copy_logs_lvf/lvf_lib_depot_md5sum_temp", "$VERBOSITY");
         #open ($MDWORK_lvf,"<copy_logs_lvf/lvf_lib_workarea_md5sum_temp");
         my @MDWORK_lvf = read_file ("copy_logs_lvf/lvf_lib_workarea_md5sum_temp");
         $count_lvf = 0;
         MD5W_lvf : 
         #while ($MDW_lvf = <$MDWORK_lvf>)
	 foreach my $MDW_lvf (@MDWORK_lvf)
         {
            #open ($MDDEPOT_lvf,"<copy_logs_lvf/lvf_lib_depot_md5sum_temp");
            my @MDDEPOT_lvf = read_file("copy_logs_lvf/lvf_lib_depot_md5sum_temp");
            $count1_lvf = 0;
    
            #while ($MDD_lvf = <$MDDEPOT_lvf>)
	    foreach my $MDD_lvf (@MDDEPOT_lvf)
            {
              
              if ($count_lvf == $count1_lvf)
              {
                if ("$MDW_lvf" eq "$MDD_lvf")
                {
                }
                else
                {
                  $error_md_lvf = $error_md_lvf + 1;
                }
      
                $count_lvf = $count_lvf + 1;
                goto MD5W_lvf;
      
              }
              $count1_lvf = $count1_lvf + 1;
            }
      
         }
      
      
         run_system_cmd ("rm -rf copy_logs_lvf/lvf_lib_depot_md5sum_temp copy_logs_lvf/lvf_lib_workarea_md5sum_temp", "$VERBOSITY");
      
         if ($error_md_lvf == 0)
         {
            run_system_cmd ("PERFORMING COMPILATION.....\n", "$VERBOSITY");
            chdir "$dir/lib_pg_lvf";
            run_system_cmd ("perl $RealBin/alphaCompileLibsForLvf.pl", "$VERBOSITY");
            chdir "$dir/lib_lvf";
            run_system_cmd ("perl $RealBin/alphaCompileLibsForLvf.pl ", "$VERBOSITY");
            chdir "$dir";
    
            
            $grep_result_lib_lvf = `grep -i error $dir/lib_lvf/compile.log | head -1`;  
            $grep_result_lib_pg_lvf = `grep -i error $dir/lib_pg_lvf/compile.log | head -1`;
    
            if (lc ($grep_result_lib_lvf) =~ /error/ || lc ($grep_result_lib_pg_lvf) =~ /error/)
            {
              run_system_cmd ("grep -i error $dir/lib_lvf/compile.log > copy_logs_lvf/compile_error", "$VERBOSITY");
              run_system_cmd ("grep -i error $dir/lib_pg_lvf/compile.log >> copy_logs_lvf/compile_error", "$VERBOSITY");
              eprint ("COMPILATION HAS ERRORS. P4 REVERTING... PLEASE CHECK copy_logs_lvf/compile_error FOR MORE INFO. PLEASE CORRECT AND RE_RUN\n", "$VERBOSITY");
              if ($p4_edit_count_lvf == 1)
              { 
                run_system_cmd ("p4 revert $dir/lib_lvf/compile.log $dir/lib_pg_lvf/compile.log >> copy_logs_lvf/p4_commands", "$VERBOSITY");
              }
              run_system_cmd ("p4 revert $dir/lib_lvf/... $dir/lib_pg_lvf/... >> copy_logs_lvf/p4_commands", "$VERBOSITY");
              exit;
            }
          
            if ($p4_edit_count_lvf == 0)
            {
               #run_system_cmd ("mv $dir/lib_lvf/compile.log $dir/copy_logs_lvf/compile.log", "$VERBOSITY"); 
               #run_system_cmd ("mv $dir/lib_pg_lvf/compile.log $dir/copy_logs_lvf/compile_pg.log", "$VERBOSITY"); 
               #run_system_cmd ("rm -rf $dir/lib_lvf/compile.log $dir/lib_pg_lvf/compile.log", "$VERBOSITY"); 
            }
    
            iprint ("Performing SIZE CHECK and WORD COUNT CHECK AFTER COPYING and COMPILING....\n");
            run_system_cmd ("mv pvt copy_logs_lvf/", "$VERBOSITY");
            run_system_cmd ("mv pvt_dev copy_logs_lvf/", "$VERBOSITY");
            run_system_cmd ("mv pvt_depot copy_logs_lvf/", "$VERBOSITY");
      
      
            run_system_cmd ("touch copy_logs_lvf/lvf_lib_wc", "$VERBOSITY");
            run_system_cmd ("touch copy_logs_lvf/lvf_lib_size", "$VERBOSITY");
            run_system_cmd ("touch copy_logs_lvf/lvf_db_size", "$VERBOSITY");
            run_system_cmd ("touch copy_logs_lvf/lvf_lib_pg_wc", "$VERBOSITY");
            run_system_cmd ("touch copy_logs_lvf/lvf_lib_pg_size", "$VERBOSITY");
            run_system_cmd ("touch copy_logs_lvf/lvf_db_pg_size", "$VERBOSITY");
            run_system_cmd ("touch copy_logs_lvf/lvf_empty_pvt", "$VERBOSITY");
       
            # Used for testing #
            #run_system_cmd ("sed -i '1d' /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg_lvf/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88v0c_pg.lib", "$VERBOSITY");
            #run_system_cmd ("rm -rf /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg_lvf/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88v0c_pg.lib", "$VERBOSITY");
            #run_system_cmd ("touch /slowfs/us01dwt3p275/nandag/SCRIPTS/Dev_Area/depot_copy/lib_pg_lvf/HDBLVT14_MUXI2_U_0P5_11M_3Mx_4Cx_2Kx_2Gx_LB_ffg0p88v0c_pg.lib", "$VERBOSITY");
      
            $lib_lvf_wc_c = 0;
            $db_lib_lvf_size_c = 0;
            $empty_lib_lvf_flag = 0;
            $word_count_lib_lvf_flag = 0;
            $size_count_lib_db_lvf_flag = 0;
      
            #open ($FR_lvf_p4, "<copy_logs_lvf/pvt");
            #while ($p4_var_lvf = <$FR_lvf_p4>)
	    my @FR_lvf_p4 = read_file("copy_logs_lvf/pvt");
	    foreach my $p4_var_lvf (@FR_lvf_p4)
            {
              chomp($p4_var_lvf);
              run_system_cmd ("wc lib_lvf/${lib_name}_${p4_var_lvf}.lib >> copy_logs_lvf/lvf_lib_wc", "$VERBOSITY");
              run_system_cmd ("du -ch lib_lvf/${lib_name}_${p4_var_lvf}.lib | grep -v total >> copy_logs_lvf/lvf_lib_size", "$VERBOSITY");
              run_system_cmd ("du -ch lib_lvf/${lib_name}_${p4_var_lvf}.db | grep -v total >> copy_logs_lvf/lvf_db_size", "$VERBOSITY");
              run_system_cmd ("wc lib_pg_lvf/${lib_name}_${p4_var_lvf}_pg.lib >> copy_logs_lvf/lvf_lib_pg_wc", "$VERBOSITY");
              run_system_cmd ("du -ch lib_pg_lvf/${lib_name}_${p4_var_lvf}_pg.lib | grep -v total >> copy_logs_lvf/lvf_lib_pg_size", "$VERBOSITY");
              run_system_cmd ("du -ch lib_pg_lvf/${lib_name}_${p4_var_lvf}_pg.db | grep -v total >> copy_logs_lvf/lvf_db_pg_size", "$VERBOSITY");
              
              $lib_lvf_wc[$lib_lvf_wc_c] = `wc lib_lvf/${lib_name}_${p4_var_lvf}.lib | awk '{print \$1}'`;
              $lib_pg_lvf_wc[$lib_lvf_wc_c] = `wc lib_pg_lvf/${lib_name}_${p4_var_lvf}_pg.lib | awk '{print \$1}'`;
              
              $lib_lvf_size[$db_lib_lvf_size_c] = `du -ch lib_lvf/${lib_name}_${p4_var_lvf}.lib | grep -v total | awk '{print \$1}'`;
              $db_lvf_size[$db_lib_lvf_size_c] = `du -ch lib_lvf/${lib_name}_${p4_var_lvf}.db | grep -v total | awk '{print \$1}'`;
              $lib_pg_lvf_size[$db_lib_lvf_size_c] = `du -ch lib_pg_lvf/${lib_name}_${p4_var_lvf}_pg.lib | grep -v total | awk '{print \$1}'`;
              $db_pg_lvf_size[$db_lib_lvf_size_c] = `du -ch lib_pg_lvf/${lib_name}_${p4_var_lvf}_pg.db | grep -v total | awk '{print \$1}'`; 
              
              if (-z "lib_lvf/${lib_name}_${p4_var_lvf}.lib" || -z "lib_pg_lvf/${lib_name}_${p4_var_lvf}_pg.lib" || -z "lib_lvf/${lib_name}_${p4_var_lvf}.db" || -z "lib_pg_lvf/${lib_name}_${p4_var_lvf}_pg.db")
              {
               $empty_lib_lvf_flag = 1;
               #run_system_cmd ("echo '${p4_var_lvf}' >>  copy_logs_lvf/lvf_empty_pvt", "$VERBOSITY");
              }
              else {
                     if ($db_lib_lvf_size_c > 0)
                     {
                      chomp($lib_lvf_size[$db_lib_lvf_size_c]);
                      chomp($lib_pg_lvf_size[$db_lib_lvf_size_c]);
                      chomp($db_lvf_size[$db_lib_lvf_size_c]);
                      chomp($db_pg_lvf_size[$db_lib_lvf_size_c]);
                      chomp($lib_lvf_size[$db_lib_lvf_size_c - 1]);
                      chomp($lib_pg_lvf_size[$db_lib_lvf_size_c - 1]);
                      chomp($db_lvf_size[$db_lib_lvf_size_c - 1]);
                      chomp($db_pg_lvf_size[$db_lib_lvf_size_c - 1]);
                
                      if (($lib_lvf_size[$db_lib_lvf_size_c] != $lib_lvf_size[$db_lib_lvf_size_c - 1]) || ($db_lvf_size[$db_lib_lvf_size_c] != $db_lvf_size[$db_lib_lvf_size_c - 1]) || ($lib_pg_lvf_size[$db_lib_lvf_size_c] != $lib_pg_lvf_size[$db_lib_lvf_size_c - 1]) || ($db_pg_lvf_size[$db_lib_lvf_size_c] != $db_pg_lvf_size[$db_lib_lvf_size_c - 1]))
                      {
                        $size_count_lib_db_lvf_flag = 1;
                      }
                    }
      
                    $db_lib_lvf_size_c = $db_lib_lvf_size_c + 1;
                  } 
    
                   
      
              if ($lib_lvf_wc_c > 0)
              {
                chomp($lib_lvf_wc[$lib_lvf_wc_c]);
                chomp($lib_pg_lvf_wc[$lib_lvf_wc_c]);
                chomp($lib_lvf_wc[$lib_lvf_wc_c - 1]);
                chomp($lib_pg_lvf_wc[$lib_lvf_wc_c - 1]);
                
                if (($lib_pg_lvf_wc[$lib_lvf_wc_c] != $lib_pg_lvf_wc[$lib_lvf_wc_c - 1]) || ($lib_lvf_wc[$lib_lvf_wc_c] != $lib_lvf_wc[$lib_lvf_wc_c - 1]))
                {
                  $word_count_lib_lvf_flag = 1;
                }
              }
      
              $lib_lvf_wc_c = $lib_lvf_wc_c + 1;
            }
      
            if ($empty_lib_lvf_flag == 1 || $word_count_lib_lvf_flag == 1 || $size_count_lib_db_lvf_flag == 1)
            {
              if ($empty_lib_lvf_flag == 1)
              {
                wprint ("THERE ARE ZERO SIZED LIBS. PLEASE REVIEW copy_logs_lvf/lvf_lib_size and copy_logs_lvf/lvf_lib_pg_size FOR MORE INFO\n");
                wprint ("PLEASE FIX AND RE-RUN IF ITS ISSUE AT WORKAREA or RE-RUN THE SCRIPT IF WORKAREA IS CLEAN\n");
                if ($p4_edit_count_lvf == 1)
                { 
                   run_system_cmd ("p4 revert $dir/lib_lvf/compile.log $dir/lib_pg_lvf/compile.log >> copy_logs_lvf/p4_commands", "$VERBOSITY");
                }
                run_system_cmd ("p4 revert $dir/lib_lvf/... $dir/lib_pg_lvf/... >> copy_logs_lvf/p4_commands", "$VERBOSITY");
              }
      
              if ($word_count_lib_lvf_flag == 1)
              {
                wprint ("THERE ARE WORD COUNT MISMATCHES IN THE LIBS. PLEASE REVIEW  copy_logs_lvf/lvf_lib_wc and copy_logs_lvf/lvf_lib_pg_wc FOR MORE INFO\n");
                wprint ("PLEASE FIX AND RE-RUN IF ITS ISSUE AT WORKAREA or RE-RUN THE SCRIPT IF WORKAREA IS CLEAN\n");
                if ($p4_edit_count_lvf == 1)
                { 
                   run_system_cmd ("p4 revert $dir/lib_lvf/compile.log $dir/lib_pg_lvf/compile.log >> copy_logs_lvf/p4_commands", "$VERBOSITY");
                }
                run_system_cmd ("p4 revert $dir/lib_lvf/... $dir/lib_pg_lvf/... >> copy_logs_lvf/p4_commands", "$VERBOSITY");
              }
    
              if ($size_count_lib_db_lvf_flag == 1)
              {
                wprint ("THERE ARE SIZE MISMATCHES IN THE LIBS OR DBS. PLEASE REVIEW  copy_logs_lvf/lib_size, copy_logs_lvf/db_size, copy_logs_lvf/lib_pg_size and copy_logs_lvf/db_pg_size FOR MORE INFO. Please perform p4 submit if these are fine.\n");
                #Disabling this since need to confirm with Chetana if this is an Issue
                #print ("PLEASE FIX AND RE-RUN IF ITS ISSUE AT WORKAREA or RE-RUN THE SCRIPT IF WORKAREA IS CLEAN\n");
                #if ($p4_edit_count_lvf == 1)
                #{ 
                #  run_system_cmd ("p4 revert $dir/lib_lvf/compile.log $dir/lib_pg_lvf/compile.log >> copy_logs_lvf/p4_commands", "$VERBOSITY");
                #}
                #run_system_cmd ("p4 revert $dir/lib_lvf/... $dir/lib_pg_lvf/... >> copy_logs_lvf/p4_commands", "$VERBOSITY");
              }
            }
      
            else 
            {
              iprint ("PLEASE VERIFY USING \"p4 opened\" and submit using \"p4 submit -d 'Releasing <release_version> of macro $macro to depot' $dir/...\"\n"); 
            }
      
       
          }     
            
      
             else
             {
                iprint ("COPYING NOT DONE PROPERLY FOR ${error_md_lvf} FILES . PLEASE RE_RUN AGAIN\n");
                iprint ("PLEASE COMPARE LVF_LIB_WORKAREA_MD5SUM LVF_LIB_DEPOT_MD5SUM FILES IN copy_logs_lvf FOLDER TO CHECK THE ISSUE FILES\n");
                if ($p4_edit_count_lvf == 1)
                { 
                   run_system_cmd ("p4 revert $dir/lib_lvf/compile.log $dir/lib_pg_lvf/compile.log >> copy_logs_lvf/p4_commands", "$VERBOSITY");
                }
                run_system_cmd ("p4 revert $dir/lib_lvf/... $dir/lib_pg_lvf/... >> copy_logs_lvf/p4_commands", "$VERBOSITY");
                run_system_cmd ("mv pvt copy_logs_lvf/", "$VERBOSITY");
                run_system_cmd ("mv pvt_dev copy_logs_lvf/", "$VERBOSITY");
                run_system_cmd ("mv pvt_depot copy_logs_lvf/", "$VERBOSITY");
             }
        }
    
        else 
        {
           ## Added newly ##
           eprint ("THERE ARE ERRORS IN LIB AND DB TIME STAMP. COPYING TERMINATED\n");
           iprint ("PLEASE COMPILE ALL THE LIBS OR ISSUE LIBS ALSO PERFORM WHOLE SET OF QA at PRODUCTION AREA AND RE-RUN THE DEPOT SCRIPT\n");
           iprint ("PLEASE OPEN 'copy_logs_lvf/lvf_lib_db_time_stamp' FOR MORE INFO\n");
                  
          run_system_cmd ("mv pvt copy_logs_lvf/", "$VERBOSITY");
          run_system_cmd ("mv pvt_dev copy_logs_lvf/", "$VERBOSITY");
          run_system_cmd ("mv pvt_depot copy_logs_lvf/", "$VERBOSITY");       
          exit;
        }
      
    }   
      
}


sub process_cmd_line_args(){
    my ( $opt_help, $opt_nousage, $opt_dryrun, 
         $opt_debug,  $opt_verbosity );

    my $success = GetOptions(
        "help"        => \$opt_help,           # Prints help
        "nousage"     => \$opt_nousage,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "dryrun!"     => \$opt_dryrun,
     );

    if((defined $opt_dryrun) && ($opt_dryrun == 1)){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return;
};

sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

Description
    "Usage : depot_copy.pl <work area till macro directories are present> <macro name> <Metal Stack name/na if there is no MS> <lvf/nldm>"

EOusage

    nprint ("$USAGE");
    exit($exit_status);    
}
