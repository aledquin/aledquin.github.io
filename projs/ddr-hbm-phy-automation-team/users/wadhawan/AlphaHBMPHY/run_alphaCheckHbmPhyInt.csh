#!/bin/csh

##  PHY origins:      846.64,9469.753 for upper instance
##                    846.64,5587.273 for lower instance

echo "Running bottom PHY instance"
./alphaCheckHbmPhyInt \
    --phyGds scratch/d714_hbm2e_top_fill_merged.gds \
    --intGds scratch/dwc_hbm2e_cowos.gds \
    --intCell dwc_hbm2e_cowos \
    --phyCell d714_hbm2e_top \
    --intPinTextLayer "125;0" \
    --phyPinTextLayer "202;74" \
    --phyOrientation MY \
    --phyOrigin "846.64,5587.273" \
    --phyBoundaryLayer "108;250" \
    --pinMapfile bot.map | tee d714_hbm2e_top_bot.bumpcheck


echo "Running top PHY instance"
./alphaCheckHbmPhyInt \
    --phyGds scratch/d714_hbm2e_top_fill_merged.gds \
    --intGds scratch/dwc_hbm2e_cowos.gds \
    --intCell dwc_hbm2e_cowos \
    --phyCell d714_hbm2e_top \
    --intPinTextLayer "125;0" \
    --phyPinTextLayer "202;74" \
    --phyOrientation MY \
    --phyOrigin "846.64,9469.753" \
    --phyBoundaryLayer "108;250" \
    --pinMapfile top.map | tee d714_hbm2e_top_top.bumpcheck


    
