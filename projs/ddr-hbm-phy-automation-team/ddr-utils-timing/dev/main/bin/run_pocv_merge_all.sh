#!/bin/bash
#source ./gen_var.tcl

ls -p | grep etm/ > xlist

while read line
do
	dir1="$line"
	pwd
	cd $dir1
	cd xtor_variations
		../run_pocv_merge
	cd ../..
done < ./xlist
rm -f xlist
