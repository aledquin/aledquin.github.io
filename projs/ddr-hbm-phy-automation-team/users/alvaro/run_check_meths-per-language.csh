#!/usr/bin/tcsh -f





set local_dir = /u/alvaro/GitLab/ddr-hbm-phy-automation-team/users/alvaro
# change dir
cd /u/alvaro/GitLab/ddr-hbm-phy-automation-team/sharedlib

#Search for perl modules, python libs, and TCL packages to get function names
# sed '/Excel/d' | sed '/QA/d' | sed '/DS/d'
find lib/Util/ -name \*pm | sed '/Excel/d' | sed '/QA/d' | sed '/DS/d' | xargs grep "^sub " | cut -d " " -f2 | cut -d "(" -f1 | sed 's|{||g' | sort | uniq > perl_sub_list
find -name \*py | xargs grep "^def " | cut -d " " -f2 | cut -d "(" -f1 | sed 's|{||g' | sort | uniq > python_def_list
find -name \*.tcl | xargs grep "^proc " | cut -d " " -f2 | sed 's/:/ /g' | cut -d " " -f5- | sort | uniq > tcl_proc_list

cat perl_sub_list > ALL_LIST
cat tcl_proc_list >> ALL_LIST
cat python_def_list >> ALL_LIST

cat ALL_LIST | sort | uniq > All_list
rm -f ALL_LIST

rm -f bin_table.csv
touch bin_table.csv

echo "method, perl, python, tcl, total " >> bin_table.csv

set ams = `cat All_list`

foreach function_ref ( $ams )
    @ total = 0
    
    echo "TCL --> `grep -w "$function_ref" tcl_proc_list`"
    if (`grep -w "$function_ref" tcl_proc_list` =~ $function_ref) then
        set tcl_bin = 1
        @ total = $total + 1
    else
        set tcl_bin = 0
    endif

    if (`grep -w "$function_ref" python_def_list` =~ $function_ref) then
        set python_bin = 1
        @ total = $total + 1
    else
        set python_bin = 0
    endif

    if (`grep -w "$function_ref" perl_sub_list` =~ $function_ref) then
        set perl_bin = 1
        @ total = $total + 1
    else
        set perl_bin = 0
    endif

    echo "$function_ref , $perl_bin , $python_bin , $tcl_bin , $total" >> bin_table.csv

end

rm -f $local_dir/1hot_methods_per_PL.csv
mv bin_table.csv $local_dir/1hot_methods_per_PL.csv
rm -f  perl_sub_list tcl_proc_list python_def_list All_list
