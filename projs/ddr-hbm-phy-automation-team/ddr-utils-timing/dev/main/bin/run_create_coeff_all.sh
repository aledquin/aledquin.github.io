#!/bin/bash
#source ./gen_var.tcl

ls -p | grep etm/ > xlist1

while read line
do
	dir1="$line"
	pwd
	cd $dir1
	cd xtor_variations
	ls -p | grep / > xlist2
	while read line
	do
		dir2="$line"
		cd $dir2
		./run_create_variation_coeff
		cd ..
	done < ./xlist2
	rm -f xlist2
	cd ../..
done < ./xlist1
rm -f xlist1
