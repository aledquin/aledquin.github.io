#!/bin/bash

#######################################################
# Author : Nandagopan G                               #               
# To grep only the required data from plotarcs report #
#######################################################


rm -rf quality_iterative

cat quality_checks/alphaPlotArcs/compare_iterative/* > quality_iterative

vi quality_iterative -c ':g/List of matched arcs/d' -c ':g/\<Matched arc\>/d' -c ':g/\<Pin comparison report.*\nNo.*mismatch\>/d' -c ':g/\<Pin direction comparison report.*\nNo pin.*mismatch\>/d' -c ':g/\<Pin capacitance comparison report.*absolute threshold used.*\nNo pin capacitance mismatch\>/d' -c ':g/\<Max capacitance comparison report\nNo max capacitance mismatch\>/d' -c ':g/\<Max transition comparison report\nNo max transition mismatch\>/d' -c ':wq'

vi quality_iterative -c ':g/\<Related power comparison report\nNo related power mismatch\>/d' -c ':g/\<Related ground comparison report\nNo related ground mismatch\>/d' -c ':g/\<Timing difference report.*\nTiming difference,  0.0000, 0.0000%\>/d'  -c ':wq'

#vi quality -c ':g/\<Related power comparison report\nNo related power mismatch\>/d' -c ':g/\<Related ground comparison report\nNo related ground mismatch\>/d' -c ':g/\<Timing difference report.*\nTiming difference,  0.0000, 0.0000%\>/d' -c ':g/^\s*$/d' -c ':wq'

#Add a new line before reference lib line and add new line after Current lib line

sed -i 's/Reference/\n&/g' quality_iterative
sed -i 's/Current.*/&\n/g' quality_iterative

#The g/^\s*$/ commands search for a line matching ^ (begin line), then zero or more occurrences of whitespace, then $ (end line), that is, blank lines.
#$,$s/$/\r/ --> for taking the cursor to the next line [$,$s --> last line in text file, last will be replaced by new line]


vi quality_iterative -c ':g/List of mismatched arcs.*\n^\s*$/d' -c ':g/\<Timing difference,  0.0000, 0.0000%.*\>/d' -c ':g/\<No.*mismatch\>/d' -c ':$,$s/$/\r/g' -c ':g/Timing difference report.*\n^\s*$/d' -c ':wq'
