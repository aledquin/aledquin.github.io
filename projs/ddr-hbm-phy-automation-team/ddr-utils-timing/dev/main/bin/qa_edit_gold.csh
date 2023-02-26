#!/bin/bash

#######################################################
# Author : Nandagopan G                               #               
# To grep only the required data from plotarcs report #
#######################################################

rm -rf quality_gold

cat quality_checks/alphaPlotArcs/compare_gold/* > quality_gold

vi quality_gold -c ':g/List of matched arcs/d' -c ':g/\<Matched arc\>/d' -c ':g/\<Pin comparison report.*\nNo.*mismatch\>/d' -c ':g/\<Pin direction comparison report.*\nNo pin.*mismatch\>/d' -c ':g/\<Pin capacitance comparison report.*absolute threshold used.*\nNo pin capacitance mismatch\>/d' -c ':g/\<Max capacitance comparison report\nNo max capacitance mismatch\>/d' -c ':g/\<Max transition comparison report\nNo max transition mismatch\>/d' -c ':wq'

vi quality_gold -c ':g/\<Related power comparison report\nNo related power mismatch\>/d' -c ':g/\<Related ground comparison report\nNo related ground mismatch\>/d' -c ':g/\<Timing difference report.*\nTiming difference,  0.0000, 0.0000%\>/d'  -c ':wq'

#vi quality -c ':g/\<Related power comparison report\nNo related power mismatch\>/d' -c ':g/\<Related ground comparison report\nNo related ground mismatch\>/d' -c ':g/\<Timing difference report.*\nTiming difference,  0.0000, 0.0000%\>/d' -c ':g/^\s*$/d' -c ':wq'

sed -i 's/Reference/\n&/g' quality_gold
sed -i 's/Current.*/&\n/g' quality_gold

vi quality_gold -c ':g/List of mismatched arcs.*\n^\s*$/d' -c ':g/\<Timing difference,  0.0000, 0.0000%.*\>/d' -c ':g/\<No.*mismatch\>/d' -c ':$,$s/$/\r/g' -c ':g/Timing difference report.*\n^\s*$/d' -c ':wq'
