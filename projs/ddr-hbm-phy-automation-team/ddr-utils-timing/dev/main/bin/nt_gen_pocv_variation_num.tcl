#!/global/freeware/Linux/2.X/tcltk-8.6.4/bin/tclsh
#nolint Main
### this has to be done in unix terminal before  running this file (module load tcl/8.6.4 )
proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-ddr-utils-timing-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww30"

#####!/usr/local/bin/tclsh
### note: START Step 1 #######need the list of cells need to be considered for calculating variation parameter###source $macro_info.tcl 
##b4 running this screate pocv folder in cellname directory
##copy nt_gen_variation_num.tcl file get_macro_info files
##create sowmya.config files 
##inside run directory
exec rm -rf xtor_variations

puts " Info : Removed existing xtor_variations directory \n "

exec mkdir xtor_variations 

puts " Info : Created new xtor_variations directory \n "

cd  xtor_variations 

puts " Info : sourcing the created Pocvsetup.tcl \n "

source ../Pocvsetup.tcl
######################## loop start ######################################################################

puts " Info : Copied  nt_tech.sp  into new xtor_variations directory \n "

exec cp ../nt_tech.sp   ./

puts " Info : executing run_get_macro_list script  \n "

source ../run_get_macro_list

puts " Info : loop start \n "


foreach instance $instance_list {

for {set x 0} {$x < [array size ptransistor]} {incr x} {

puts " \n Info :  ./set_var_${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x).tcl used \n "

global __cell  
global __spice_cells_file  
global __spice_model_file  
global __hspice_path  
global __submit
global __output  
global __input  
global __sensitization  
global __vdd  
global __gnd  
global __vdd_voltage  
global __pmos_type  
global __nmos_type  
global __nmos_length  
global __pmos_length  
global __nmos_nfin  
global __pmos_nfin  
global __max_fanout_cap 
global __max_fanin_trans  

set sensitization ""
if {[regexp -nocase {(NAND_2)} $instance]} {
set sensitization "NAND_2: a out b=1"
set input "a"
} elseif {[regexp -nocase {(NAND_3)} $instance]} {
set sensitization "NAND_3: a out b=1 c=1"
set input "a"
} elseif {[regexp -nocase {(NAND_4)} $instance]} {
set sensitization "NAND_4: a out b=1 c=1 d=1"
set input "a"
} elseif {[regexp -nocase {(NOR_2)} $instance]} {
set sensitization "NOR_2: a out b=0"
set input "a"
} elseif {[regexp -nocase {(NOR_3)} $instance]} {
set sensitization "NOR_3: a out b=0 c=0"
set input "a"
} elseif {[regexp -nocase {(NOR_4)} $instance]} {
set sensitization "NOR_4: a out b=0 c=0 d=0"
set input "a"
} elseif {[regexp -nocase {(inverter)} $instance]} {
set sensitization ""
set input "a"
}

set __cell $instance
set __spice_cells_file  "./${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x).sp" 
set __spice_model_file  ./nt_tech.sp
if { $argc == 1 } {
    set hspice_ver [lindex $argv 0]
    set __hspice_path  /global/apps5/hspice_$hspice_ver/hspice/bin/
} else {	
    set __hspice_path  /global/apps5/hspice_2021.09-1/hspice/bin/
}

set __submit  "qsub -P bnormal -cwd -b y  "
set __output  $output  
set __input  $input  
set __sensitization  $sensitization  
#set __vdd  $VDD_supply  
#set __gnd  $GND_supply  
set __vdd vdd 
set __gnd vss
set __vdd_voltage  $VDD_val 
set __pmos_type  $ptransistor($x) 
set __nmos_type  $ntransistor($x) 
set __nmos_length  $lengthtransistor($x) 
set __pmos_length  $lengthtransistor($x) 
set __nmos_nfin  1 
set __pmos_nfin  1 
set __max_fanout_cap  3.0 
set __max_fanin_trans  50 

puts "\n              HI !! u r here                       \n  "
puts "                                                     \n  "
puts "                                                     \n  "
puts "                                                       "
puts "                                                       "
puts "                                                       "
puts "                                                       "
puts "                                                       "
puts "                                                       "
puts "             $PVT                                          "
puts "                                                       "
puts "                                                       "
puts "                                                       "
puts "                                                       "
puts "                                                       "
puts "                                                       "
puts "              $PVT                                         "


puts " Info :sensitization  $sensitization "
puts " Info :__cell  $__cell "
puts " Info :__spice_cells_file  $__spice_cells_file "
puts " Info :__spice_model_file  $__spice_model_file "
puts " Info :__hspice_path $__hspice_path "
puts " Info :__submit $__submit"
puts " Info :__output  $__output "
puts " Info :__input $__input "
puts " Info :__sensitization  $__sensitization "
puts " Info :__vdd $__vdd "
puts " Info :__gnd $__gnd "
puts " Info :__vdd_voltage $__vdd_voltage "
puts " Info :__pmos_type  $__pmos_type "
puts " Info :__nmos_type $__nmos_type "
puts " Info :__nmos_length $__nmos_length "
puts " Info :__pmos_length $__pmos_length "
puts " Info :__nmos_nfin $__nmos_nfin "
puts " Info :__pmos_nfin $__pmos_nfin "
puts " Info :__max_fanout_cap $__max_fanout_cap"
puts " Info :__max_fanin_trans  $__max_fanin_trans "


set a v_variation.tcl
set b _nfin
set c v

set __coeff_file  nt_${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$a

puts " \n Info : __coeff_file set to  nt_${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$a  \n "

set __pocv_dir ./${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c  

puts " \n Info : __pocv_dir set to  ./${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c   \n"


global __scriptdir

if { [file exists $__scriptdir/tbcload] } {
append auto_path " $__scriptdir/tbcload"
}

set __date [clock format [clock seconds] -format {%a %b %d %H:%M:%S %Z %Y}]
global __date

if { [file exists $__scriptdir/Simple_pocv_generation.tcl] } {
source $__scriptdir/Simple_pocv_generation.tcl
} elseif { [file exists $__scriptdir/Simple_pocv_generation.tbc] } {
source $__scriptdir/Simple_pocv_generation.tbc
} else {
        puts " ERROR : Simple_pocv_generation.tbc/.tcl not found(Please place all POCV script files in same directory) \n "
        exit
}

if { [file exists $__scriptdir/general_pocv.tcl] } {
source $__scriptdir/general_pocv.tcl
} elseif { [file exists $__scriptdir/general_pocv.tbc] } {
source $__scriptdir/general_pocv.tbc
} else {
        puts " ERROR : general_pocv.tbc/.tcl not found(Please place all POCV script files in same directory) \n "
        exit
}

puts " \n Info : writing pocv_runscript for ${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c  \n "


write_pocv_runscript  \
-cell $__cell \
-nt_coeff_file $__coeff_file \
-spice_cells $__spice_cells_file \
-spice_model $__spice_model_file \
-spice_path  $__hspice_path \
-add_predrvr_cnt 3 \
-max_logic_depth 15  \
-output $__output  -input $__input \
-sensitization_data $__sensitization \
-supply $__gnd=0.0   -supply $__vdd=$__vdd_voltage \
-monte 2000  -monte_split 500  \
-meas_dir $__pocv_dir   -pocv_dir $__pocv_dir \
-tran_step .1 -time_unit "ps" \
-period 50000  -tran_stop 90000   -sig_digits 5 \
-nt_coeff_nmos $__nmos_type -nt_coeff_pmos $__pmos_type \
-nt_coeff_nmos_length $__nmos_length -nt_coeff_pmos_length $__pmos_length \
-nt_coeff_nmos_nfin $__nmos_nfin -nt_coeff_pmos_nfin $__pmos_nfin \
-inc_spice_cells \
-fanout_cap_mode max_fanout_cap_pct  -max_fanout_cap_pct 0.5 -max_fanout_cap $__max_fanout_cap \
-fanin_trans_mode max_fanin_trans_pct -max_fanin_trans_pct 0.5  -max_fanin_trans $__max_fanin_trans \
-nt_tcl_script $__script_dir/pocv_plus.tcl \
-submit $__submit \
-nt -no_nt_batch -path_ordered \
-mean_mode avg \
-sigma_mode avg 

#-rccap 0  -rcres 0  rcseg 0  \



puts " Info : Chaging  pwd to __pocv_dir ./$__pocv_dir  \n "

cd ./$__pocv_dir

#########  checks for existance of 3 files starts here #########################


if { [file exists ./run_create_pocv_setup ] }  {
   
     if { [file exists ./run_create_variation_coeff ] } {
      
          if { [file exists ./run_create_delay_variation ] } {
                      
          puts " Info : All the 3 runscripts got created .. proceeding further \n "
          
          } else {
	  
          puts " ERROR : run_create_delay_variation runscript is NOT CREATED for ${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c \n "
	  puts " Info : Two runscripts created .. so exited \n   "
	  exit
          }
     } else {
     
     puts " ERROR : run_create_variation_coeff and run_create_delay_variation runscript are NOT CREATED for ${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c \n "
     puts " Info : One runscript created .. so exited \n   "
     exit
     }

} else {
puts " ERROR : run_create_pocv_setup and run_create_variation_coeff and run_create_delay_variation runscript are NOT CREATED for ${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c \n "
puts " Info : Zero runscripts created .. so exited  \n  "
exit  
}

##########checks to existance of 3 files ended here #####################
############# (scripts need to be TCL 8.4 or newer) ########exec module load tcl/8.6.4 

puts " Info : Executing run_create_pocv_setup runscript \n "

exec ./run_create_pocv_setup

#run_hsp_pocv ; run_ntpocv ; $__cell.spi; s-0.NT.POCV.tcl ; s-0.NT.POCV.sp ; s-0.m-x.NT.POCV.tcl files shld get created at this stage 


###### checks for existance of above files and scripts starts here #########################
      ############################### run_hsp_pocv check start #############################
      
          if { [file exists ./run_hsp_pocv ] }  {
	  
      	  puts " Info : Generated/created run_hsp_pocv runscript \n "
          
          } else {
          
          puts " ERROR : run_hsp_pocv runscript is NOT CREATED for ${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c ...so exited  \n "
          exit 	    
          }
      
      ############################### run_ntpocv check start ###############################
          if { [file exists ./run_ntpocv ] }  {
      		
          puts " Info : Generated/created run_ntpocv runscript \n "
          
          } else {
          
          puts " ERROR: run_ntpocv runscript is NOT CREATED for ${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c ..so exited \n"
          exit        	    
          }
          
      ############################### Cell SPICE deck $__cell.spi ???? check start #############################  
          if { [file exists ./$__cell.spi ] }  {
	        		
          puts " Info : Generated/created $__cell.spi \n  "
          
          } else {
          
          puts " ERROR : $__cell.spi NOT CREATED for ${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c..so exited \n "
	  exit        	    
          }
          
      
      ############## ? NanoTime Tcl script $__cell_.o-<output>.i-<input>.s-0.NT.POCV.tcl check start #############################
	  
      	  if { [file exists ./$__cell.o-$__output.i-$__input.s-0.NT.POCV.tcl  ] }  {
	  	
          puts " Info : Generated/created run_ntpocv runscript($__cell.o-$__output.i-$__input.s-0.NT.POCV.tcl) \n "
          
          } else {
          
          puts " ERROR : Generated/created run_ntpocv runscript($__cell.o-$__output.i-$__input.s-0.NT.POCV.tcl) NOT CREATED for $cellName$__cell$__nmos_nfin$c$__vdd_voltage ..so exited \n "
          exit	    
          }
          
      ###########? NanoTime SPICE __input file <cellname>.o-<__output>.i-<__input>.s-0.NT.POCV.sp check start ####################
      
          if { [file exists ./$__cell.o-$__output.i-$__input.s-0.NT.POCV.sp  ] }  {
      		
          puts " Info : Generated/created $__cell.o-$__output.i-$__input.s-0.NT.POCV.sp \n "
          
          } else {
          
          puts " ERROR : $__cell.o-$__output.i-$__input.s-0.NT.POCV.sp  NOT CREATED for $cellName$__cell$__nmos_nfin$c$__vdd_voltage ..so exited \n "
          exit	    
          }
          
      ##########? Four HSPICE __input files corresponding to the four groups of MC simulations check(500 points each) specified in Step 8. ##########
           #####The file names are of the form <cellname>.o-<__output>.i-<__input>.s-0.m-x.POCV.sp, where m-x is replaced by m-1 through m-4. check start ############
         
	 
	   ######## m-1.pocv.sp########
             if { [file exists ./$__cell.o-$__output.i-$__input.s-0.m-1.POCV.sp  ] }  {
         		
             puts " Info : $__cell.o-$__output.i-$__input.s-0.m-1.POCV.sp HSPICE __input files corresponding to the four groups of Monte Carlo simulations got created \n "
             
             } else {
             
             puts " ERROR : $__cell.o-$__output.i-$__input.s-0.m-1.POCV.sp HSPICE __input files corresponding to the four groups of Monte Carlo simulations NOT CREATED for $cellName$__cell$__nmos_nfin$c$__vdd_voltage  \n "
             exit        	    
             }
	     
	   ######## m-2.pocv.sp########
             if { [file exists ./$__cell.o-$__output.i-$__input.s-0.m-2.POCV.sp  ] }  {
         		
             puts " Info : $__cell.o-$__output.i-$__input.s-0.m-2.POCV.sp HSPICE __input files corresponding to the four groups of Monte Carlo simulations got created \n "
             
             } else {
             
             puts " ERROR : $__cell.o-$__output.i-$__input.s-0.m-2.POCV.sp HSPICE __input files corresponding to the four groups of Monte Carlo simulations NOT CREATED for $cellName$__cell$__nmos_nfin$c$__vdd_voltage  \n "
             exit        	    
             }
	     
	   ######## m-3.pocv.sp########
             if { [file exists ./$__cell.o-$__output.i-$__input.s-0.m-3.POCV.sp  ] }  {
         		
             puts " Info : $__cell.o-$__output.i-$__input.s-0.m-3.POCV.sp HSPICE __input files corresponding to the four groups of Monte Carlo simulations got created \n "
             
             } else {
             
             puts "ERROR : $__cell.o-$__output.i-$__input.s-0.m-3.POCV.sp HSPICE __input files corresponding to the four groups of Monte Carlo simulations NOT CREATED for $cellName$__cell$__nmos_nfin$c$__vdd_voltage \n "
             exit        	    
             }
	     
	   ######## m-4.pocv.sp########
             if { [file exists ./$__cell.o-$__output.i-$__input.s-0.m-4.POCV.sp  ] }  {
         		
             puts " Info : $__cell.o-$__output.i-$__input.s-0.m-4.POCV.sp HSPICE __input files corresponding to the four groups of Monte Carlo simulations got created  \n "
             
             } else {
             
             puts " ERROR : $__cell.o-$__output.i-$__input.s-0.m-4.POCV.sp HSPICE __input files corresponding to the four groups of Monte Carlo simulations NOT CREATED for $cellName$__cell$__nmos_nfin$c$__vdd_voltage \n "
             exit        	    
             }
  
 
##########################  checks to existance of above files and runscripts ended  here #################################################


puts " Info : Searching & replacing incorrectly generated supply & ground pins \n "

set Scriptone $__cell.o-$__output.i-$__input.s-0.m-1.POCV.sp
set Scripttwo $__cell.o-$__output.i-$__input.s-0.m-2.POCV.sp
set Scriptthree $__cell.o-$__output.i-$__input.s-0.m-3.POCV.sp
set Scriptfour $__cell.o-$__output.i-$__input.s-0.m-4.POCV.sp
set Scriptmain $__cell.o-$__output.i-$__input.s-0.NT.POCV.sp



exec sed -i "s/pocv_$__vdd/$__vdd/g" ./$Scriptone
exec sed -i "s/pocv_$__vdd/$__vdd/g" ./$Scripttwo
exec sed -i "s/pocv_$__vdd/$__vdd/g" ./$Scriptthree
exec sed -i "s/pocv_$__vdd/$__vdd/g" ./$Scriptfour
exec sed -i "s/pocv_$__vdd/$__vdd/g" ./$Scriptmain

exec sed -i "s/pocv_$__gnd/$__gnd/g" ./$Scriptone
exec sed -i "s/pocv_$__gnd/$__gnd/g" ./$Scripttwo
exec sed -i "s/pocv_$__gnd/$__gnd/g" ./$Scriptthree
exec sed -i "s/pocv_$__gnd/$__gnd/g" ./$Scriptfour
exec sed -i "s/pocv_$__gnd/$__gnd/g" ./$Scriptmain

exec sed -i "s/out#/$__output#/g" ./$Scriptone
exec sed -i "s/out#/$__output#/g" ./$Scripttwo
exec sed -i "s/out#/$__output#/g" ./$Scriptthree
exec sed -i "s/out#/$__output#/g" ./$Scriptfour
exec sed -i "s/out#/$__output#/g" ./$Scriptmain


exec sed -i "s/in#/$__input#/g" ./$Scriptone
exec sed -i "s/in#/$__input#/g" ./$Scripttwo
exec sed -i "s/in#/$__input#/g" ./$Scriptthree
exec sed -i "s/in#/$__input#/g" ./$Scriptfour
exec sed -i "s/in#/$__input#/g" ./$Scriptmain


puts " Info : Edited the following files(5 files) as required\n
   
$Scriptone    >>>>>>>>>>>>>>>>>>>>>>>>>>
$Scripttwo    >>>>>>>>>>>>>>>>>>>>>>>>>>
$Scriptthree  >>>>>>>>>>>>>>>>>>>>>>>>>>
$Scriptfour   >>>>>>>>>>>>>>>>>>>>>>>>>>
$Scriptmain   >>>>>>>>>>>>>>>>>>>>>>>>>>

 \n "

puts " Info : Started executing run_hsp_pocv \n "


exec ./run_hsp_pocv 



set i 0
if  [catch {set jobFile [open job.List "r"]}] {puts "ERROR:  Cannot open job.List for read\n"}

while {[gets $jobFile line] >= 0} {
lappend jobsList $line
set i [expr $i+1]
}
close $jobFile

set status "running"

while {$status == "running"} {
set j 0
set k 0
set status ""
#exec sleep 10
foreach job $jobsList {
set qstat($job) ""
}
foreach lines  [split [exec qstat] "\n"] {
#puts $lines
set line  [split $lines " "]
set qstat([lindex $line 3]) [lindex $line 12]
}
foreach job $jobsList {
#puts "qstat($job) == \"$qstat($job)\""
if {$qstat($job) == "qw" } {
set status "running"
#puts "qstat($job)=$qstat($job)"
set j [expr $j+1]
} elseif {$qstat($job) == "r"} {
#puts "qstat($job)=$qstat($job)"
set status "running"
set k [expr $k+1]
}
}
puts "##Info : Waiting for $jobsList jobs to complete, Total:$i, Pending Jobs:$j, Running Jobs:$k  \n"

exec sleep 15
}

 
puts " Info : Done executing run_hsp_pocv script \n"

puts " Info : Started executing run_create_variation_coeff script for ${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$c \n"

exec sleep 60

exec ./run_create_variation_coeff
cd ../

#Info : __coeff_file set to  nt_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$a 
exec sleep 60

if { [file exists ./$__coeff_file] }  {
         		
   	   puts " Info : __coeff_file $__coeff_file ;   created at this step got created NOW  \n" 
	   puts " Info : Done executing rupocv_create_variation_coeff for  ${PVT}_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage volts successfully \n"
           } else {puts " ERROR : __coeff_file : $__coeff_file ;  nt_${instance}_$ptransistor($x)_$ntransistor($x)_$lengthtransistor($x)_$__vdd_voltage$a  NOT created  UFFFFFFFFFFFFFFFF  :( ) \n "
	   }
}
}







puts "INFO : END OF THE LOOP ; WRITE CODE FOR MERGING VALUES "

puts "INFO : END OF THE LOOP ; WRITE CODEFOR  MERGING VALUES "
puts "INFO : END OF THE LOOP   WRI     TECODE FOR MERGING VA "
puts "INFO : END             ; WRI     TECODE      FORME "
puts "INFO : END             ; WRITE CODEFOR       MERGI "
puts "INFO : END OF THE LOOP ; WRITE CODEFO        MERGI "
puts "INFO : END OF THE LOOP ; WRI   TECODEF       MERGI "
puts "INFO :            LOOP ; WRI    TECODEF      MERGI "
puts "INFO :            LOOP ; WRI      TECODE FOR MERGING VAU "
puts "INFO : END OF THE LOOP ; WRI      TECODE FOR MERGING VAL "
puts "INFO : END OF THE LOOP ; WRi      TECODE FOR MERGING VAL "

puts "\n   \n"
puts "\n   end ####################################################################################\n"
puts "\n   end ####################################################################################\n"
puts "\n   end ######################## $PVT ################################################\n"
exit



#################################################################### PART_2 OF THE CODE ################################################################################################################################################



















cd  ../


           puts " Info : Done executing rupocv_create_variation_coeff successfully \n"

   	   puts " Info : Started executing run_ntpocv \n"
   	   
           cd ./$__cell$b$__nmos_nfin$c$__vdd_voltage
	    
	    puts  " hi  nt"
	    exec sleep 15 
	    
	    exec module load nt
	     
	    puts   " hi ------------------------------"
             
	    exec sleep 15 
	    
	    exec ./run_ntpocv
                  
                   if { [file exists  $__cell.o-$__output.i-$__input.s-0.min.NT.POCV.csv  ] && [file exists $__cell.o-$__output.i-$__input.s-0.max.NT.POCV.csv  ] }  {
		   
                   puts " Info : $__cell.o-$__output.i-$__input.s-0.min.NT.POCV.csv and  $__cell.o-$__output.i-$__input.s-0.max.NT.POCV.csv  created after executing run_ntpocv  script \n"
		   
		   
		   exec sleep 15
		    
		   exec sleep 15
		     
		   exec ./run_create_delay_variation
		   
                   puts " Info : Started executing run_create_delay_variation script \n"      
		 
		   exec sleep 15
		        
                           	  if { [file exists  $cellName.o-$__output.i-$__input.s-0.HSP.csv] }  {
                           	
                                  puts " Info : Done executing run_create_delay_variation script \n "

                           	  } else {
				
                           	  puts " ERROR : UNSUCCESSFUL execution of  run_create_delay_variation script as $cellName.o-$__output.i-$__input.s-0.HSP.csv  is not created	\n" 
      	                   	  exit 
	                   	  }
		   
                   } else {
		   
                   puts " ERROR : UNSUCCESSFUL execution of run_ntpocv script   \n" 
		   puts "Info : file exists  $__cell.o-$__output.i-$__input.s-0.min.NT.POCV.csv is [file exists  $__cell.o-$__output.i-$__input.s-0.min.NT.POCV.csv ] "
		   puts "Info : file exists  $__cell.o-$__output.i-$__input.s-0.max.NT.POCV.csv is [file exists  $__cell.o-$__output.i-$__input.s-0.max.NT.POCV.csv ] "
      	           exit 
	           }
	      
             } else {  
	        
             puts " ERROR : $__coeff_file is nt_$__cell$__vdd_voltage$a at this step not created \n"
             puts " ERROR : UNSUCCESSFUL execution of run_create_variation_coeff \n" 
	     exit        	    
             }

 
pocv.log
puts " Info : Obtained variation parameters for  $__cell of $cellName using $__nmos_nfin$c with vdd value $__vdd_voltage  \n "
 
puts " Info : proceeding to create more combinations (logicpocv.log gates/device types/length/voltages) of variation parameters.\n "

###################################################### loop end ####################################  loop end ###########################


puts "Info : all covered for $cellName you are about to merge the variation results obtained as a single file using runpocv_merge from & in  xtor directory \n "


exit 
		 
exec cd ../  
if { [file exists set_variation_parameters.tcl ] }  {	    
#if { [file exists ./../set_variation_parameters.tcl ] }  {
	  
      		
          puts " Info : set_variation_parameters.tcl got created for \n ********************** $cellName ***********************"
          exit 
          } else {
          
          puts " ERROR : set_variation_parameters.tcl not created for $cellName"
          exit 	    
          }
}
