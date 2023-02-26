# Floorplans in following format: macro columns rows d_x d_y x y angle mirror, etc.
# Note that any arrayed instances will not have their pin names uniquified. Therefore all hard macro instantiations need to be done separately.

# abutment_ac1r_ew
set floorplans(abutment_ac1r_ew) [list \
  dwc_ddrphyse_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 \$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 2*\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphy_endcell_ew 1 8 0 \$y_dwc_ddrphy_endcell_ew 0 3*\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphysec_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphyse_top_ew}+8*\$y_dwc_ddrphy_endcell_ew 0 0 \
  dwc_ddrphydiff_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphyse_top_ew}+8*\${y_dwc_ddrphy_endcell_ew}+\$y_dwc_ddrphysec_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphyse_top_ew}+8*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphysec_top_ew}+\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 4*\${y_dwc_ddrphyse_top_ew}+8*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphysec_top_ew}+\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 5*\${y_dwc_ddrphyse_top_ew}+8*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphysec_top_ew}+\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 6*\${y_dwc_ddrphyse_top_ew}+8*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphysec_top_ew}+\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 2 0 \$y_dwc_ddrphy_vddqclamp_2x2_ew -\$x_dwc_ddrphy_vddqclamp_2x2_ew 0 0 0 \
  dwc_ddrphy_vdd2clamp_2x2_ew 1 1 0 0 -\$x_dwc_ddrphy_vdd2clamp_2x2_ew 2*\$y_dwc_ddrphy_vddqclamp_2x2_ew 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqclamp_2x2_ew 2*\${y_dwc_ddrphy_vddqclamp_2x2_ew}+\$y_dwc_ddrphy_vdd2clamp_2x2_ew 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqclamp_4x1_ew 3*\${y_dwc_ddrphy_vddqclamp_2x2_ew}+\$y_dwc_ddrphy_vdd2clamp_2x2_ew 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_2x2_ew}-\$x_dwc_ddrphy_decapvddq_4x1_ew 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_2x2_ew}-\${x_dwc_ddrphy_decapvddq_4x1_ew}-\$x_dwc_ddrphy_decapvdd_4x1_ew 0 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ew 2 2 \$x_dwc_ddrphy_decapvdd2_1x1_ew \$y_dwc_ddrphy_decapvdd2_1x1_ew -\${x_dwc_ddrphy_vdd2clamp_2x2_ew}-2*\$x_dwc_ddrphy_decapvdd2_1x1_ew \$y_dwc_ddrphy_decapvddq_4x1_ew 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_1x1_ew -\${x_dwc_ddrphy_vddqclamp_2x2_ew}-\$x_dwc_ddrphy_decapvddq_1x1_ew \${y_dwc_ddrphy_decapvddq_4x1_ew}+2*\$y_dwc_ddrphy_decapvdd2_1x1_ew 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 2 1 \$x_dwc_ddrphy_decapvddq_4x1_ew 0 -\${x_dwc_ddrphy_vddqclamp_4x1_ew}-2*\$x_dwc_ddrphy_decapvddq_4x1_ew 3*\${y_dwc_ddrphy_vddqclamp_2x2_ew}+\$y_dwc_ddrphy_vdd2clamp_2x2_ew 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \$y_dwc_ddrphy_decapvdd_1x1_ew -\${x_dwc_ddrphy_vddqclamp_2x2_ew}-\${x_dwc_ddrphy_decapvddq_1x1_ew}-\$x_dwc_ddrphy_decapvdd_1x1_ew \${y_dwc_ddrphy_decapvdd_4x1_ew}+2*\$y_dwc_ddrphy_decapvdd2_1x1_ew 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_4x1_ew}-2*\${x_dwc_ddrphy_decapvddq_4x1_ew}-\$x_dwc_ddrphy_decapvdd_4x1_ew \${y_dwc_ddrphy_decapvdd_4x1_ew}+2*\${y_dwc_ddrphy_decapvdd2_1x1_ew}+2*\$y_dwc_ddrphy_decapvdd_1x1_ew \
  ]

# abutment_ac1r_ns
set floorplans(abutment_ac1r_ns) [list \
  dwc_ddrphyse_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 2*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 3*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphydiff_top_ns 1 1 0 0 4*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphysec_top_ns 1 1 0 0 4*\${x_dwc_ddrphyse_top_ns}+\$x_dwc_ddrphydiff_top_ns 0 0 0 \
  dwc_ddrphy_endcell_ns 8 1 \$x_dwc_ddrphy_endcell_ns 0 4*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+\$x_dwc_ddrphysec_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 4*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+\${x_dwc_ddrphysec_top_ns}+8*\$x_dwc_ddrphy_endcell_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 5*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+\${x_dwc_ddrphysec_top_ns}+8*\$x_dwc_ddrphy_endcell_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 6*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+\${x_dwc_ddrphysec_top_ns}+8*\$x_dwc_ddrphy_endcell_ns 0 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ns 1 1 0 0 0 \$y_dwc_ddrphyse_top_ns 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 1 1 0 0 \$x_dwc_ddrphy_vddqclamp_4x1_ns \$y_dwc_ddrphydiff_top_ns 0 0 \
  dwc_ddrphy_vdd2clamp_2x2_ns 1 1 0 0 \${x_dwc_ddrphy_vddqclamp_4x1_ns}+\$x_dwc_ddrphy_vddqclamp_2x2_ns \$y_dwc_ddrphysec_top_ns 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 2 1 \$x_dwc_ddrphy_vddqclamp_2x2_ns 0 \${x_dwc_ddrphy_vddqclamp_4x1_ns}+\${x_dwc_ddrphy_vddqclamp_2x2_ns}+\$x_dwc_ddrphy_vdd2clamp_2x2_ns \$y_dwc_ddrphy_endcell_ns 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 2 0 \$y_dwc_ddrphy_decapvddq_4x1_ns 0 \${y_dwc_ddrphyse_top_ns}+\$y_dwc_ddrphy_vddqclamp_4x1_ns 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 2 1 \$x_dwc_ddrphy_decapvddq_1x1_ns 0 \$x_dwc_ddrphy_decapvddq_4x1_ns \${y_dwc_ddrphydiff_top_ns}+\$y_dwc_ddrphy_vddqclamp_2x2_ns 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ns 2 2 \$x_dwc_ddrphy_decapvdd2_1x1_ns \$y_dwc_ddrphy_decapvdd2_1x1_ns \${x_dwc_ddrphy_decapvddq_4x1_ns}+2*\$x_dwc_ddrphy_decapvddq_1x1_ns \${y_dwc_ddrphysec_top_ns}+\$y_dwc_ddrphy_vdd2clamp_2x2_ns 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns}+2*\${x_dwc_ddrphy_decapvddq_1x1_ns}+2*\$x_dwc_ddrphy_decapvdd2_1x1_ns \${y_dwc_ddrphy_endcell_ns}+\$y_dwc_ddrphy_vddqclamp_2x2_ns 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns}+\${y_dwc_ddrphy_vddqclamp_4x1_ns}+2*\$y_dwc_ddrphy_decapvddq_4x1_ns 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \$x_dwc_ddrphy_decapvdd_1x1_ns 0 \$x_dwc_ddrphy_decapvdd_4x1_ns \${y_dwc_ddrphydiff_top_ns}+\${y_dwc_ddrphy_vddqclamp_2x2_ns}+\$y_dwc_ddrphy_decapvddq_1x1_ns 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvdd_4x1_ns}+2*\${x_dwc_ddrphy_decapvdd_1x1_ns}+2*\$x_dwc_ddrphy_decapvdd2_1x1_ns \${y_dwc_ddrphy_endcell_ns}+\${y_dwc_ddrphy_vddqclamp_2x2_ns}+\$dwc_ddrphy_decapvddq_4x1_ns 0 0 \
  ]

# abutment_ac2r_ew
set floorplans(abutment_ac2r_ew) [list \
  dwc_ddrphyse_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 \$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 2*\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphydiff_top_ew 1 1 0 0 0 4*\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphysec_top_ew 1 1 0 0 0 4*\${y_dwc_ddrphyse_top_ew}+\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphysec_top_ew 1 1 0 0 0 4*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphydiff_top_ew}+\$y_dwc_ddrphysec_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 4*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphydiff_top_ew}+2*\$y_dwc_ddrphysec_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 5*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphydiff_top_ew}+2*\$y_dwc_ddrphysec_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 6*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphydiff_top_ew}+2*\$y_dwc_ddrphysec_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 7*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphydiff_top_ew}+2*\$y_dwc_ddrphysec_top_ew 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqclamp_4x1_ew 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_4x1_ew}-\$x_dwc_ddrphy_decapvddq_4x1_ew 0 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqclamp_2x2_ew \$y_dwc_ddrphy_vddqclamp_4x1_ew 0 0 \
  dwc_ddrphy_vdd2clamp_2x2_ew 1 1 0 0 -\$x_dwc_ddrphy_vdd2clamp_2x2_ew \${y_dwc_ddrphy_vddqclamp_4x1_ew}+\$y_dwc_ddrphy_vddqclamp_2x2_ew 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 2 0 \$y_dwc_ddrphy_vddqclamp_2x2_ew -\$x_dwc_ddrphy_vddqclamp_2x2_ew \${y_dwc_ddrphy_vddqclamp_4x1_ew}+\${y_dwc_ddrphy_vddqclamp_2x2_ew}+\$y_dwc_ddrphy_vdd2clamp_2x2_ew 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_4x1_ew}-\${x_dwc_ddrphy_decapvddq_4x1_ew}-\$x_dwc_ddrphy_decapvdd_4x1_ew 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \$y_dwc_ddrphy_decapvdd_1x1_ew -\${x_dwc_ddrphy_vddqclamp_2x2_ew}-\$x_dwc_ddrphy_decapvdd_1x1_ew \$y_dwc_ddrphy_decapvdd_4x1_ew 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_4x1_ew}-2*\${x_dwc_ddrphy_decapvddq_4x1_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_1x1_ew -\${x_dwc_ddrphy_vddqclamp_2x2_ew}-\${x_dwc_ddrphy_decapvdd_1x1_ew}-\$x_dwc_ddrphy_decapvddq_1x1_ew \$y_dwc_ddrphy_decapvddq_4x1_ew 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ew 2 2 \$x_dwc_ddrphy_decapvdd2_1x1_ew \$y_dwc_ddrphy_decapvdd2_1x1_ew -\${x_dwc_ddrphy_vdd2clamp_2x2_ew}-2*\$x_dwc_ddrphy_decapvdd2_1x1_ew \${y_dwc_ddrphy_decapvddq_4x1_ew}+2*\$y_dwc_ddrphy_decapvddq_1x1_ew 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_2x2_ew}-\$x_dwc_ddrphy_decapvdd_4x1_ew \${y_dwc_ddrphy_decapvdd_4x1_ew}+2*\${y_dwc_ddrphy_decapvdd_1x1_ew}+2*\$y_dwc_ddrphy_decapvdd2_1x1_ew 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_2x2_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew}-\$x_dwc_ddrphy_decapvddq_4x1_ew \${y_dwc_ddrphy_decapvddq_4x1_ew}+2*\${y_dwc_ddrphy_decapvddq_1x1_ew}+2*\$y_dwc_ddrphy_decapvdd2_1x1_ew 0 0 \
  ]

# abutment_ac2r_ns
set floorplans(abutment_ac2r_ns) [list \
  dwc_ddrphyse_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 2*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 3*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphydiff_top_ns 1 1 0 0 4*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphysec_top_ns 1 1 0 0 4*\${x_dwc_ddrphyse_top_ns}+\$x_dwc_ddrphydiff_top_ns 0 0 0 \
  dwc_ddrphysec_top_ns 1 1 0 0 4*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+\$x_dwc_ddrphysec_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 4*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+2*\$x_dwc_ddrphysec_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 5*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+2*\$x_dwc_ddrphysec_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 6*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+2*\$x_dwc_ddrphysec_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 7*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphydiff_top_ns}+2*\$x_dwc_ddrphysec_top_ns 0 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ns 1 1 0 0 0 \$y_dwc_ddrphyse_top_ns 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns}+\$y_dwc_ddrphy_vddqclamp_4x1_ns 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 1 1 0 0 \$x_dwc_ddrphy_vddqclamp_4x1_ns \$y_dwc_ddrphydiff_top_ns 0 0 \
  dwc_ddrphy_vdd2clamp_2x2_ns 1 1 0 0 \${x_dwc_ddrphy_vddqclamp_4x1_ns}+\$x_dwc_ddrphy_vddqclamp_2x2_ns \$y_dwc_ddrphysec_top_ns 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 2 1 \$x_dwc_ddrphy_vddqclamp_2x2_ns 0 \${x_dwc_ddrphy_vddqclamp_4x1_ns}+\${x_dwc_ddrphy_vddqclamp_2x2_ns}+\$x_dwc_ddrphy_vdd2clamp_2x2_ns \$y_dwc_ddrphyse_top_ns 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns}+\${y_dwc_ddrphy_vddqclamp_4x1_ns}+\$y_dwc_ddrphy_decapvddq_4x1_ns 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \$x_dwc_ddrphy_decapvdd_1x1_ns 0 \$x_dwc_ddrphy_decapvdd_4x1_ns \${y_dwc_ddrphydiff_top_ns}+\$y_dwc_ddrphy_vddqclamp_2x2_ns 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ns 2 2 \$x_dwc_ddrphy_decapvdd2_1x1_ns \$y_dwc_ddrphy_decapvdd2_1x1_ns \${x_dwc_ddrphy_decapvdd_4x1_ns}+2*\$x_dwc_ddrphy_decapvdd_1x1_ns \${y_dwc_ddrphysec_top_ns}+\$y_dwc_ddrphy_vdd2clamp_2x2_ns 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvdd_4x1_ns}+2*\${x_dwc_ddrphy_decapvdd_1x1_ns}+2*\$x_dwc_ddrphy_decapvdd2_1x1_ns \${y_dwc_ddrphyse_top_ns}+\$y_dwc_ddrphy_vddqclamp_2x2_ns 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns}+\${y_dwc_ddrphy_vddqclamp_4x1_ns}+\${y_dwc_ddrphy_decapvddq_4x1_ns}+\$y_dwc_ddrphy_decapvdd_4x1_ns 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 2 1 \$x_dwc_ddrphy_decapvddq_1x1_ns 0 \$x_dwc_ddrphy_decapvddq_4x1_ns \${y_dwc_ddrphydiff_top_ns}+\${y_dwc_ddrphy_vddqclamp_2x2_ns}+\$y_dwc_ddrphy_decapvdd_1x1_ns 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns}+2*\${x_dwc_ddrphy_decapvddq_1x1_ns}+2*\$x_dwc_ddrphy_decapvdd2_1x1_ns \${y_dwc_ddrphyse_top_ns}+\${y_dwc_ddrphy_vddqclamp_2x2_ns}+\$y_dwc_ddrphy_decapvdd_4x1_ns 0 0 \
  ]
  
# abutment_acx4_a0_aM_aM_a0_ew
set floorplans(abutment_acx4_a0_aM_aM_a0_ew) [list \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 2*\$y_dwc_ddrphyacx4_top_ew 0 1 \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 3*\$y_dwc_ddrphyacx4_top_ew 0 1 \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 3*\$y_dwc_ddrphyacx4_top_ew 0 0 \
  ]

# abutment_acx4_a0_aM_aM_a0_ns
set floorplans(abutment_acx4_a0_aM_aM_a0_ns) [list \
  dwc_ddrphyacx4_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphyacx4_top_ns 1 1 0 0 2*\$x_dwc_ddrphyacx4_top_ns 0 180 1 \
  dwc_ddrphyacx4_top_ns 1 1 0 0 3*\$x_dwc_ddrphyacx4_top_ns 0 180 1 \
  dwc_ddrphyacx4_top_ns 1 1 0 0 3*\$x_dwc_ddrphyacx4_top_ns 0 0 0 \
  ]

# abutment_acx4_d0_a0_d0_ew
set floorplans(abutment_acx4_d0_a0_d0_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 \$y_dwc_ddrphydbyte_top_ew 0 0 \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 \${y_dwc_ddrphydbyte_top_ew}+\$y_dwc_ddrphyacx4_top_ew 0 0 \
  ]

# abutment_acx4_d0_a0_d0_ns
set floorplans(abutment_acx4_d0_a0_d0_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 0 -\$y_dwc_ddrphydbyte_top_ns 0 0 \
  dwc_ddrphyacx4_top_ns 1 1 0 0 \$x_dwc_ddrphydbyte_top_ns -\$y_dwc_ddrphyacx4_top_ns 0 0 \
  dwc_ddrphydbyte_top_ns 1 1 0 0 \${x_dwc_ddrphydbyte_top_ns}+\$x_dwc_ddrphyacx4_top_ns -\$y_dwc_ddrphydbyte_top_ns 0 0 \
  ]

# abutment_acx4_d0_aM_d0_ew
set floorplans(abutment_acx4_d0_aM_d0_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 \${y_dwc_ddrphydbyte_top_ew}+\$y_dwc_ddrphyacx4_top_ew 0 1 \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 \${y_dwc_ddrphydbyte_top_ew}+\$y_dwc_ddrphyacx4_top_ew 0 0 \
  ]

# abutment_acx4_d0_aM_d0_ns
set floorplans(abutment_acx4_d0_aM_d0_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 0 -\$y_dwc_ddrphydbyte_top_ns 0 0 \
  dwc_ddrphyacx4_top_ns 1 1 0 0 \${x_dwc_ddrphydbyte_top_ns}+\$x_dwc_ddrphyacx4_top_ns -\$y_dwc_ddrphyacx4_top_ns 180 1 \
  dwc_ddrphydbyte_top_ns 1 1 0 0 \${x_dwc_ddrphydbyte_top_ns}+\$x_dwc_ddrphyacx4_top_ns -\$y_dwc_ddrphydbyte_top_ns 0 0 \
  ]

# abutment_dbyte_d0_d0_dM_d0_ew
set floorplans(abutment_dbyte_d0_d0_dM_d0_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 \$y_dwc_ddrphydbyte_top_ew 0 0 \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 3*\$y_dwc_ddrphydbyte_top_ew 0 1 \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 3*\$y_dwc_ddrphydbyte_top_ew 0 0 \
  ]

# abutment_dbyte_d0_d0_dM_d0_ns
set floorplans(abutment_dbyte_d0_d0_dM_d0_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphydbyte_top_ns 1 1 0 0 \$x_dwc_ddrphydbyte_top_ns 0 0 0 \
  dwc_ddrphydbyte_top_ns 1 1 0 0 3*\$x_dwc_ddrphydbyte_top_ns 0 180 1 \
  dwc_ddrphydbyte_top_ns 1 1 0 0 3*\$x_dwc_ddrphydbyte_top_ns 0 0 0 \
  ]

# abutment_dbyte_ew
set floorplans(abutment_dbyte_ew) [list \
  dwc_ddrphyse_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 \$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 2*\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphydiff_top_ew 1 1 0 0 0 4*\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphydiff_top_ew 1 1 0 0 0 4*\${y_dwc_ddrphyse_top_ew}+\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 4*\${y_dwc_ddrphyse_top_ew}+2*\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 5*\${y_dwc_ddrphyse_top_ew}+2*\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 6*\${y_dwc_ddrphyse_top_ew}+2*\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 7*\${y_dwc_ddrphyse_top_ew}+2*\$y_dwc_ddrphydiff_top_ew 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ew 1 3 0 \$y_dwc_ddrphy_vddqclamp_4x1_ew -\$x_dwc_ddrphy_vddqclamp_4x1_ew 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_4x1_ew -\${x_dwc_ddrphy_vddqclamp_4x1_ew}-\$x_dwc_ddrphy_decapvddq_4x1_ew 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \$y_dwc_ddrphy_decapvdd_4x1_ew -\${x_dwc_ddrphy_vddqclamp_4x1_ew}-\$x_dwc_ddrphy_decapvddq_4x1_ew-\$x_dwc_ddrphy_decapvdd_4x1_ew 0 0 0 \
  ]

# abutment_dbyte_ns
set floorplans(abutment_dbyte_ns) [list \
  dwc_ddrphyse_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 2*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 3*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphydiff_top_ns 1 1 0 0 4*\$x_dwc_ddrphyse_top_ns 0 0 0 \
  dwc_ddrphydiff_top_ns 1 1 0 0 4*\${x_dwc_ddrphyse_top_ns}+\$x_dwc_ddrphydiff_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 4*\${x_dwc_ddrphyse_top_ns}+2*\$x_dwc_ddrphydiff_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 5*\${x_dwc_ddrphyse_top_ns}+2*\$x_dwc_ddrphydiff_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 6*\${x_dwc_ddrphyse_top_ns}+2*\$x_dwc_ddrphydiff_top_ns 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 7*\${x_dwc_ddrphyse_top_ns}+2*\$x_dwc_ddrphydiff_top_ns 0 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ns 3 1 \$x_dwc_ddrphy_vddqclamp_4x1_ns 0 0 \$y_dwc_ddrphyse_top_ns 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 3 1 \$x_dwc_ddrphy_decapvddq_4x1_ns 0 0 \${y_dwc_ddrphyse_top_ns}+\$y_dwc_ddrphy_vddqclamp_4x1_ns 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \$x_dwc_ddrphy_decapvdd_4x1_ns 0 0 \${y_dwc_ddrphyse_top_ns}+\${y_dwc_ddrphy_vddqclamp_4x1_ns}+\$y_dwc_ddrphy_decapvddq_4x1_ns 0 0 \
  ]

# abutment_end0_m0_end0_ew
set floorplans(abutment_end0_m0_end0_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ew 1 2 0 \$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ew \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \$y_dwc_ddrphy_endcell_ew 0 -2*\$y_dwc_ddrphy_endcell_ew 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \$y_dwc_ddrphy_endcell_ew 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 2 2 \$x_dwc_ddrphy_decapvdd_1x1_ew \$y_dwc_ddrphy_decapvdd_1x1_ew -2*\$x_dwc_ddrphy_decapvdd_1x1_ew -2*\$y_dwc_ddrphy_decapvdd_1x1_ew 0 0 \
  dwc_ddrphy_vdd2clamp_2x2_ew 1 2 0 \$y_dwc_ddrphy_vdd2clamp_2x2_ew -\$x_dwc_ddrphy_vdd2clamp_2x2_ew 0 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 2 0 \$y_dwc_ddrphy_vddqclamp_2x2_ew -\$x_dwc_ddrphy_vddqclamp_2x2_ew \${y_dwc_ddrphymaster_top}-2*\$y_dwc_ddrphy_vddqclamp_2x2_ew 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 2 2 \$x_dwc_ddrphy_decapvdd_1x1_ew \$y_dwc_ddrphy_decapvdd_1x1_ew -2*\$x_dwc_ddrphy_decapvdd_1x1_ew \$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_end0_m0_end0_ns
set floorplans(abutment_end0_m0_end0_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ns 2 1 \$x_dwc_ddrphy_vaa_vdd2clamp_4x1_ns 0 0 -\$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ns 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \$x_dwc_ddrphy_endcell_ns 0 -2*\$x_dwc_ddrphy_endcell_ns \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_endcell_ns 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \$x_dwc_ddrphy_endcell_ns 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_endcell_ns 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 2 \$x_dwc_ddrphy_decapvdd_1x1_ns \$y_dwc_ddrphy_decapvdd_1x1_ns -2*\$x_dwc_ddrphy_decapvdd_1x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vdd2clamp_2x2_ns 2 1 \$x_dwc_ddrphy_vdd2clamp_2x2_ns 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 2 1 \$x_dwc_ddrphy_vddqclamp_2x2_ns 0 \$x_dwc_ddrphymaster_top-2*\$x_dwc_ddrphy_vddqclamp_2x2_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 2 \$x_dwc_ddrphy_decapvdd_1x1_ns \$y_dwc_ddrphy_decapvdd_1x1_ns \$x_dwc_ddrphymaster_top \$y_dwc_ddrphymaster_top 0 0 \
  ]
  
# abutment_end0_mM_end0_ew
set floorplans(abutment_end0_mM_end0_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 1 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ew 1 2 0 \$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ew \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \$y_dwc_ddrphy_endcell_ew 0 -2*\$y_dwc_ddrphy_endcell_ew 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \$y_dwc_ddrphy_endcell_ew 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 2 2 \$x_dwc_ddrphy_decapvdd_1x1_ew \$y_dwc_ddrphy_decapvdd_1x1_ew -2*\$x_dwc_ddrphy_decapvdd_1x1_ew -2*\$y_dwc_ddrphy_decapvdd_1x1_ew 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 2 0 \$y_dwc_ddrphy_vddqclamp_2x2_ew -\$x_dwc_ddrphy_vddqclamp_2x2_ew 0 0 0 \
  dwc_ddrphy_vdd2clamp_2x2_ew 1 2 0 \$y_dwc_ddrphy_vdd2clamp_2x2_ew -\$x_dwc_ddrphy_vdd2clamp_2x2_ew \${y_dwc_ddrphymaster_top}-2*\$y_dwc_ddrphy_vdd2clamp_2x2_ew 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 2 2 \$x_dwc_ddrphy_decapvdd_1x1_ew \$y_dwc_ddrphy_decapvdd_1x1_ew -2*\$x_dwc_ddrphy_decapvdd_1x1_ew \$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_end0_mM_end0_ns
set floorplans(abutment_end0_mM_end0_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 \$x_dwc_ddrphymaster_top 0 180 1 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ns 2 1 \$x_dwc_ddrphy_vaa_vdd2clamp_4x1_ns 0 0 -\$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ns 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \$x_dwc_ddrphy_endcell_ns 0 -2*\$x_dwc_ddrphy_endcell_ns \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_endcell_ns 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \$x_dwc_ddrphy_endcell_ns 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_endcell_ns 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 2 \$x_dwc_ddrphy_decapvdd_1x1_ns \$y_dwc_ddrphy_decapvdd_1x1_ns -2*\$x_dwc_ddrphy_decapvdd_1x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 2 1 \$x_dwc_ddrphy_vddqclamp_2x2_ns 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vdd2clamp_2x2_ns 2 1 \$x_dwc_ddrphy_vdd2clamp_2x2_ns 0 \$x_dwc_ddrphymaster_top-2*\$x_dwc_ddrphy_vdd2clamp_2x2_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 2 \$x_dwc_ddrphy_decapvdd_1x1_ns \$y_dwc_ddrphy_decapvdd_1x1_ns \$x_dwc_ddrphymaster_top \$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_end0_se0_rpt0_end0_ew
set floorplans(abutment_end0_se0_rpt0_end0_ew) [list \
  dwc_ddrphy_endcell_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 0 2*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 0 2*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphy_rpt2ch_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphy_rpt2ch_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphy_rpt2ch_ew}+\${y_dwc_ddrphy_rpt1ch_ew}+\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphy_rpt2ch_ew}+\${y_dwc_ddrphy_rpt1ch_ew}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}+\${y_dwc_ddrphy_rpt1ch_ew}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}+\${y_dwc_ddrphy_rpt1ch_ew}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}+\${y_dwc_ddrphy_rpt1ch_ew}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}+2*\${y_dwc_ddrphy_rpt1ch_ew}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}+2*\${y_dwc_ddrphy_rpt1ch_ew}+5*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 0 3*\${y_dwc_ddrphy_endcell_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}+2*\${y_dwc_ddrphy_rpt1ch_ew}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ew} 0 -2*\${x_dwc_ddrphy_decapvdd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 2 1 \${x_dwc_ddrphy_decapvddq_1x1_ew} 0 -2*\${x_dwc_ddrphy_decapvddq_1x1_ew} \${y_dwc_ddrphy_decapvdd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ew} 0 -2*\${x_dwc_ddrphy_decapvdd_1x1_ew} \${y_dwc_ddrphy_decapvdd_1x1_ew}+\${y_dwc_ddrphy_decapvddq_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 2 1 \${x_dwc_ddrphy_decapvddq_1x1_ew} 0 -2*\${x_dwc_ddrphy_decapvddq_1x1_ew} 2*\${y_dwc_ddrphy_decapvdd_1x1_ew}+\${y_dwc_ddrphy_decapvddq_1x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ew} 0 -2*\${x_dwc_ddrphy_decapvdd_1x1_ew} 2*\${y_dwc_ddrphy_decapvdd_1x1_ew}+2*\${y_dwc_ddrphy_decapvddq_1x1_ew} 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_2x2_ew} 3*\${y_dwc_ddrphy_decapvdd_1x1_ew}+2*\${y_dwc_ddrphy_decapvddq_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 2 1 \${x_dwc_ddrphy_decapvddq_1x1_ew} 0 -2*\${x_dwc_ddrphy_decapvddq_1x1_ew} 3*\${y_dwc_ddrphy_decapvdd_1x1_ew}+2*\${y_dwc_ddrphy_decapvddq_1x1_ew}+\${y_dwc_ddrphy_vddqclamp_2x2_ew} 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_2x2_ew} 3*\${y_dwc_ddrphy_decapvdd_1x1_ew}+3*\${y_dwc_ddrphy_decapvddq_1x1_ew}+\${y_dwc_ddrphy_vddqclamp_2x2_ew} 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 2 1 \${x_dwc_ddrphy_decapvddq_1x1_ew} 0 -2*\${x_dwc_ddrphy_decapvddq_1x1_ew} 3*\${y_dwc_ddrphy_decapvdd_1x1_ew}+3*\${y_dwc_ddrphy_decapvddq_1x1_ew}+2*\${y_dwc_ddrphy_vddqclamp_2x2_ew} 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqclamp_2x2_ew} 3*\${y_dwc_ddrphy_decapvdd_1x1_ew}+4*\${y_dwc_ddrphy_decapvddq_1x1_ew}+2*\${y_dwc_ddrphy_vddqclamp_2x2_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ew} 0 -2*\${x_dwc_ddrphy_decapvdd_1x1_ew} 3*\${y_dwc_ddrphy_decapvdd_1x1_ew}+4*\${y_dwc_ddrphy_decapvddq_1x1_ew}+3*\${y_dwc_ddrphy_vddqclamp_2x2_ew} 0 0 \
  ]

# abutment_end0_se0_rpt0_end0_ns
set floorplans(abutment_end0_se0_rpt0_end0_ns) [list \
  dwc_ddrphy_endcell_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+\${x_dwc_ddrphyse_top_ns} 0 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+2*\${x_dwc_ddrphyse_top_ns} 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+2*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt1ch_ns} 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+3*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt1ch_ns} 0 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+4*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt1ch_ns} 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+4*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt1ch_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+5*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt1ch_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+6*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt1ch_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 2*\${x_dwc_ddrphy_endcell_ns}+6*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt1ch_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 2*\${x_dwc_ddrphy_endcell_ns}+6*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt1ch_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 3*\${x_dwc_ddrphy_endcell_ns}+6*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt1ch_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 3*\${x_dwc_ddrphy_endcell_ns}+6*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt1ch_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ns} 0 \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 1 1 0 0 \${x_dwc_ddrphy_decapvdd_1x1_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddq_1x1_ns} \${x_dwc_ddrphy_decapvdd_1x1_ns}+\${x_dwc_ddrphy_vddqclamp_2x2_ns} \${y_dwc_ddrphy_rpt1ch_ns} 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 1 1 0 0 \${x_dwc_ddrphy_decapvdd_1x1_ns}+\${x_dwc_ddrphy_vddqclamp_2x2_ns}+\${x_dwc_ddrphy_decapvddq_1x1_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddq_1x1_ns} \${x_dwc_ddrphy_decapvdd_1x1_ns}+2*\${x_dwc_ddrphy_vddqclamp_2x2_ns}+\${x_dwc_ddrphy_decapvddq_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_vddqclamp_2x2_ns 1 1 0 0 \${x_dwc_ddrphy_decapvdd_1x1_ns}+2*\${x_dwc_ddrphy_vddqclamp_2x2_ns}+2*\${x_dwc_ddrphy_decapvddq_1x1_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ns} \${x_dwc_ddrphy_decapvdd_1x1_ns}+3*\${x_dwc_ddrphy_vddqclamp_2x2_ns}+2*\${x_dwc_ddrphy_decapvddq_1x1_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddq_1x1_ns} 2*\${x_dwc_ddrphy_decapvdd_1x1_ns}+3*\${x_dwc_ddrphy_vddqclamp_2x2_ns}+2*\${x_dwc_ddrphy_decapvddq_1x1_ns} \${y_dwc_ddrphy_rpt1ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ns} 2*\${x_dwc_ddrphy_decapvdd_1x1_ns}+3*\${x_dwc_ddrphy_vddqclamp_2x2_ns}+3*\${x_dwc_ddrphy_decapvddq_1x1_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddq_1x1_ns} 3*\${x_dwc_ddrphy_decapvdd_1x1_ns}+3*\${x_dwc_ddrphy_vddqclamp_2x2_ns}+3*\${x_dwc_ddrphy_decapvddq_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ns} 3*\${x_dwc_ddrphy_decapvdd_1x1_ns}+3*\${x_dwc_ddrphy_vddqclamp_2x2_ns}+4*\${x_dwc_ddrphy_decapvddq_1x1_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  ]

# abutment_end0_sec0_diff0_end0_ew
set floorplans(abutment_end0_sec0_diff0_end0_ew) [list \
  dwc_ddrphy_endcell_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphydiff_top_ew 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphydiff_top_ew} 0 0 \
  dwc_ddrphysec_top_ew 1 1 0 0 0 2*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphydiff_top_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 0 2*\${y_dwc_ddrphy_endcell_ew}+\${y_dwc_ddrphydiff_top_ew}+\${y_dwc_ddrphysec_top_ew} 0 0 \
  ]

# abutment_end0_sec0_diff0_end0_ns
set floorplans(abutment_end0_sec0_diff0_end0_ns) [list \
  dwc_ddrphy_endcell_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphysec_top_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphy_endcell_ns}+\${x_dwc_ddrphysec_top_ns} 0 0 0 \
  dwc_ddrphydiff_top_ns 1 1 0 0 2*\${x_dwc_ddrphy_endcell_ns}+\${x_dwc_ddrphysec_top_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 2*\${x_dwc_ddrphy_endcell_ns}+\${x_dwc_ddrphysec_top_ns}+\${x_dwc_ddrphydiff_top_ns} 0 0 0 \
  ]

# abutment_master_a0_m0_a0_ew
set floorplans(abutment_master_a0_m0_a0_ew) [list \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphymaster_top 1 1 0 0 0 \$y_dwc_ddrphyacx4_top_ew 0 0 \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 \${y_dwc_ddrphyacx4_top_ew}+\$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_master_a0_m0_a0_ns
set floorplans(abutment_master_a0_m0_a0_ns) [list \
  dwc_ddrphyacx4_top_ns 1 1 0 0 0 -\$y_dwc_ddrphyacx4_top_ns 0 0 \
  dwc_ddrphymaster_top 1 1 0 0 \$x_dwc_ddrphyacx4_top_ns -\$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphyacx4_top_ns 1 1 0 0 \${x_dwc_ddrphyacx4_top_ns}+\$x_dwc_ddrphymaster_top -\$y_dwc_ddrphyacx4_top_ns 0 0 \
  ]

# abutment_master_aM_m0_aM_ew
set floorplans(abutment_master_aM_m0_aM_ew) [list \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 \$y_dwc_ddrphyacx4_top_ew 0 1 \
  dwc_ddrphymaster_top 1 1 0 0 0 \$y_dwc_ddrphyacx4_top_ew 0 0 \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 2*\${y_dwc_ddrphyacx4_top_ew}+\$y_dwc_ddrphymaster_top 0 1 \
  ]

# abutment_master_aM_m0_aM_ns
set floorplans(abutment_master_aM_m0_aM_ns) [list \
  dwc_ddrphyacx4_top_ns 1 1 0 0 \$x_dwc_ddrphyacx4_top_ns -\$y_dwc_ddrphyacx4_top_ns 180 1 \
  dwc_ddrphymaster_top 1 1 0 0 \$x_dwc_ddrphyacx4_top_ns -\$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphyacx4_top_ns 1 1 0 0 2*\${x_dwc_ddrphyacx4_top_ns}+\$x_dwc_ddrphymaster_top -\$y_dwc_ddrphyacx4_top_ns 180 1 \
  ]

# abutment_master_d0_m0_d0_ew
set floorplans(abutment_master_d0_m0_d0_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphymaster_top 1 1 0 0 0 \$y_dwc_ddrphydbyte_top_ew 0 0 \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 \${y_dwc_ddrphydbyte_top_ew}+\$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_master_d0_m0_d0_ns
set floorplans(abutment_master_d0_m0_d0_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 0 -\$y_dwc_ddrphydbyte_top_ns 0 0 \
  dwc_ddrphymaster_top 1 1 0 0 \$x_dwc_ddrphydbyte_top_ns -\$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphydbyte_top_ns 1 1 0 0 \${x_dwc_ddrphydbyte_top_ns}+\$x_dwc_ddrphymaster_top -\$y_dwc_ddrphydbyte_top_ns 0 0 \
  ]

# abutment_master_dM_m0_dM_ew
set floorplans(abutment_master_dM_m0_dM_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 \$y_dwc_ddrphydbyte_top_ew 0 1 \
  dwc_ddrphymaster_top 1 1 0 0 0 \$y_dwc_ddrphydbyte_top_ew 0 0 \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 2*\${y_dwc_ddrphydbyte_top_ew}+\$y_dwc_ddrphymaster_top 0 1 \
  ]

# abutment_master_dM_m0_dM_ns
set floorplans(abutment_master_dM_m0_dM_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 \$x_dwc_ddrphydbyte_top_ns -\$y_dwc_ddrphydbyte_top_ns 180 1 \
  dwc_ddrphymaster_top 1 1 0 0 \$x_dwc_ddrphydbyte_top_ns -\$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphydbyte_top_ns 1 1 0 0 2*\${x_dwc_ddrphydbyte_top_ns}+\$x_dwc_ddrphymaster_top -\$y_dwc_ddrphydbyte_top_ns 180 1 \
  ]

# abutment_master_m0_mM_m0_ew
set floorplans(abutment_master_m0_mM_m0_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphymaster_top 1 1 0 0 0 2*\$y_dwc_ddrphymaster_top 0 1 \
  dwc_ddrphymaster_top 1 1 0 0 0 2*\$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_master_m0_mM_m0_ns
set floorplans(abutment_master_m0_mM_m0_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphymaster_top 1 1 0 0 2*\$x_dwc_ddrphymaster_top 0 180 1 \
  dwc_ddrphymaster_top 1 1 0 0 2*\$x_dwc_ddrphymaster_top 0 0 0 \
  ]

# abutment_se0_m0_se0_ew
set floorplans(abutment_se0_m0_se0_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ew 1 1 0 0 \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_decapvdd2_4x1_ew 1 1 0 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_decapvdd2_4x1_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 -\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 1 1 0 0 -\$x_dwc_ddrphy_decapvddq_1x1_ew - \$y_dwc_ddrphy_decapvddq_1x1_ew 0 0 \
  dwc_ddrphy_vdd2clamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vdd2clamp_4x1_ew 0 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqclamp_4x1_ew \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_vddqclamp_4x1_ew 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 1 1 0 0 -\$x_dwc_ddrphy_decapvddq_1x1_ew \$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_se0_m0_se0_ns
set floorplans(abutment_se0_m0_se0_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ns 1 1 0 0 0 -\$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ns 0 0 \
  dwc_ddrphy_decapvdd2_4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top}-\$x_dwc_ddrphy_decapvdd2_4x1_ns -\$y_dwc_ddrphy_decapvdd2_4x1_ns 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 -\$x_dwc_ddrphyse_top_ns \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphyse_top_ns 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphyse_top_ns 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 1 0 0 -\$x_dwc_ddrphy_decapvddq_1x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vdd2clamp_4x1_ns 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top}-\$x_dwc_ddrphy_vddqclamp_4x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 1 0 0 \$x_dwc_ddrphymaster_top \$y_dwc_ddrphymaster_top 0 0 \
  ]
  
# abutment_se0_mM_se0_ew
set floorplans(abutment_se0_mM_se0_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 1 \
  dwc_ddrphy_decapvdd2_4x1_ew 1 1 0 0 \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ew 1 1 0 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 -\$y_dwc_ddrphyse_top_ew 0 0 \
  dwc_ddrphyse_top_ew 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 1 1 0 0 -\$x_dwc_ddrphy_decapvddq_1x1_ew -\$y_dwc_ddrphy_decapvddq_1x1_ew 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqclamp_4x1_ew 0 0 0 \
  dwc_ddrphy_vdd2clamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vdd2clamp_4x1_ew \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_vdd2clamp_4x1_ew 0 0 \
  dwc_ddrphy_decapvddq_1x1_ew 1 1 0 0 -\$x_dwc_ddrphy_decapvddq_1x1_ew \$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_se0_mM_se0_ns
set floorplans(abutment_se0_mM_se0_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 \$x_dwc_ddrphymaster_top 0 180 1 \
  dwc_ddrphy_decapvdd2_4x1_ns 1 1 0 0 0 -\$y_dwc_ddrphy_decapvdd2_4x1_ns 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top}-\$x_dwc_ddrphy_vaa_vdd2clamp_4x1_ns -\$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ns 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 -\$x_dwc_ddrphyse_top_ns \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphyse_top_ns 0 0 \
  dwc_ddrphyse_top_ns 1 1 0 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphyse_top_ns 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 1 0 0 -\$x_dwc_ddrphy_decapvddq_1x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ns 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vdd2clamp_4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top}-\$x_dwc_ddrphy_vdd2clamp_4x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 1 0 0 \$x_dwc_ddrphymaster_top \$y_dwc_ddrphymaster_top 0 0 \
  ]  

# abutment_sec0_m0_sec0_ew
set floorplans(abutment_sec0_m0_sec0_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ew 1 1 0 0 \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_decapvdd2_4x1_ew 1 1 0 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_decapvdd2_4x1_ew 0 0 \
  dwc_ddrphysec_top_ew 1 1 0 0 0 -\$y_dwc_ddrphysec_top_ew 0 0 \
  dwc_ddrphysec_top_ew 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ew 1 1 0 0 -\$x_dwc_ddrphy_decapvdd2_1x1_ew - \$y_dwc_ddrphy_decapvdd2_1x1_ew 0 0 \
  dwc_ddrphy_vdd2clamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vdd2clamp_4x1_ew 0 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqclamp_4x1_ew \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_vddqclamp_4x1_ew 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ew 1 1 0 0 -\$x_dwc_ddrphy_decapvdd2_1x1_ew \$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_sec0_m0_sec0_ns
set floorplans(abutment_sec0_m0_sec0_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ns 1 1 0 0 0 -\$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ns 0 0 \
  dwc_ddrphy_decapvdd2_4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top}-\$x_dwc_ddrphy_decapvdd2_4x1_ns -\$y_dwc_ddrphy_decapvdd2_4x1_ns 0 0 \
  dwc_ddrphysec_top_ns 1 1 0 0 -\$x_dwc_ddrphysec_top_ns \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphysec_top_ns 0 0 \
  dwc_ddrphysec_top_ns 1 1 0 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphysec_top_ns 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ns 1 1 0 0 -\$x_dwc_ddrphy_decapvdd2_1x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vdd2clamp_4x1_ns 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top}-\$x_dwc_ddrphy_vddqclamp_4x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ns 1 1 0 0 \$x_dwc_ddrphymaster_top \$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_sec0_mM_sec0_ew
set floorplans(abutment_sec0_mM_sec0_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 1 \
  dwc_ddrphy_decapvdd2_4x1_ew 1 1 0 0 \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ew 1 1 0 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ew 0 0 \
  dwc_ddrphysec_top_ew 1 1 0 0 0 -\$y_dwc_ddrphysec_top_ew 0 0 \
  dwc_ddrphysec_top_ew 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ew 1 1 0 0 -\$x_dwc_ddrphy_decapvdd2_1x1_ew -\$y_dwc_ddrphy_decapvdd2_1x1_ew 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqclamp_4x1_ew 0 0 0 \
  dwc_ddrphy_vdd2clamp_4x1_ew 1 1 0 0 -\$x_dwc_ddrphy_vdd2clamp_4x1_ew \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphy_vdd2clamp_4x1_ew 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ew 1 1 0 0 -\$x_dwc_ddrphy_decapvdd2_1x1_ew \$y_dwc_ddrphymaster_top 0 0 \
  ]

# abutment_sec0_mM_sec0_ns
set floorplans(abutment_sec0_mM_sec0_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 \$x_dwc_ddrphymaster_top 0 180 1 \
  dwc_ddrphy_decapvdd2_4x1_ns 1 1 0 0 0 -\$y_dwc_ddrphy_decapvdd2_4x1_ns 0 0 \
  dwc_ddrphy_vaa_vdd2clamp_4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top}-\$x_dwc_ddrphy_vaa_vdd2clamp_4x1_ns -\$y_dwc_ddrphy_vaa_vdd2clamp_4x1_ns 0 0 \
  dwc_ddrphysec_top_ns 1 1 0 0 -\$x_dwc_ddrphysec_top_ns \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphysec_top_ns 0 0 \
  dwc_ddrphysec_top_ns 1 1 0 0 \$x_dwc_ddrphymaster_top \${y_dwc_ddrphymaster_top}-\$y_dwc_ddrphysec_top_ns 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ns 1 1 0 0 -\$x_dwc_ddrphy_decapvdd2_1x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vddqclamp_4x1_ns 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vdd2clamp_4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top}-\$x_dwc_ddrphy_vdd2clamp_4x1_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvdd2_1x1_ns 1 1 0 0 \$x_dwc_ddrphymaster_top \$y_dwc_ddrphymaster_top 0 0 \
  ]

# boundary_acx4_decapvddq_acx4_ew
set floorplans(boundary_acx4_decapvddq_acx4_ew) [list \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 2 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphyacx4_top_ew}-2*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 2 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphyacx4_top_ew}-2*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphyacx4_top_ew 0 0 \
  dwc_ddrphy_decapvddq_acx4_ew 2 1 \$x_dwc_ddrphy_decapvddq_acx4_ew 0 -2*\$x_dwc_ddrphy_decapvddq_acx4_ew 0 0 0 \
  ]

# boundary_acx4_decapvddq_acx4_ns
set floorplans(boundary_acx4_decapvddq_acx4_ns) [list \
  dwc_ddrphyacx4_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphyacx4_top_ns 0 0 0 \
  dwc_ddrphy_decapvddq_acx4_ns 1 2 0 \$y_dwc_ddrphy_decapvddq_acx4_ns 0 \$y_dwc_ddrphyacx4_top_ns 0 0 \
  ]

# boundary_acx4_decapvddq_ew
set floorplans(boundary_acx4_decapvddq_ew) [list \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 2 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphyacx4_top_ew}-2*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 2 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphyacx4_top_ew}-2*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphyacx4_top_ew 0 0 \
  dwc_ddrphy_decapvddq_ew 2 1 \$x_dwc_ddrphy_decapvddq_ew 0 -2*\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  ]

# boundary_acx4_decapvddq_ns
set floorplans(boundary_acx4_decapvddq_ns) [list \
  dwc_ddrphyacx4_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphyacx4_top_ns 0 0 0 \
  dwc_ddrphy_decapvddq_ns 1 2 0 \$y_dwc_ddrphy_decapvddq_ns 0 \$y_dwc_ddrphyacx4_top_ns 0 0 \
  ]

# boundary_acx4_vddqlpclamp_acx4_ew
set floorplans(boundary_acx4_vddqlpclamp_acx4_ew) [list \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 2 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphyacx4_top_ew}-2*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 2 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphyacx4_top_ew}-2*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphyacx4_top_ew 0 0 \
  dwc_ddrphy_vddqlpclamp_acx4_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqlpclamp_acx4_ew 0 0 0 \
  dwc_ddrphy_decapvddq_acx4_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqlpclamp_acx4_ew}-\$x_dwc_ddrphy_decapvddq_acx4_ew 0 0 0 \
  ]

# boundary_acx4_vddqlpclamp_acx4_ns
set floorplans(boundary_acx4_vddqlpclamp_acx4_ns) [list \
  dwc_ddrphyacx4_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphyacx4_top_ns 0 0 0 \
  dwc_ddrphy_vddqlpclamp_acx4_ns 1 1 0 0 0 \$y_dwc_ddrphyacx4_top_ns 0 0 \
  dwc_ddrphy_decapvddq_axc4_ns 1 1 0 0 0 \${y_dwc_ddrphyacx4_top_ns}+\$y_dwc_ddrphy_vddqlpclamp_acx4_ns 0 0 \
  ]

# boundary_acx4_vddqlpclamp_ew
set floorplans(boundary_acx4_vddqlpclamp_ew) [list \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 2 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphyacx4_top_ew}-2*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 2 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphyacx4_top_ew}-2*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphyacx4_top_ew 0 0 \
  dwc_ddrphy_vddqlpclamp_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqlpclamp_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqlpclamp_ew}-\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  ]

# boundary_acx4_vddqlpclamp_ns
set floorplans(boundary_acx4_vddqlpclamp_ns) [list \
  dwc_ddrphyacx4_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 2 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphyacx4_top_ns 0 0 0 \
  dwc_ddrphy_vddqlpclamp_ns 1 1 0 0 0 \$y_dwc_ddrphyacx4_top_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 1 1 0 0 0 \${y_dwc_ddrphyacx4_top_ns}+\$y_dwc_ddrphy_vddqlpclamp_ns 0 0 \
  ]

# boundary_dbyte_decapvddq_dbyte_ew
set floorplans(boundary_dbyte_decapvddq_dbyte_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphydbyte_top_ew}-3*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphydbyte_top_ew}-3*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphydbyte_top_ew 0 0 \
  dwc_ddrphy_decapvddq_dbyte_ew 3 1 \$x_dwc_ddrphy_decapvddq_dbyte_ew 0 -3*\$x_dwc_ddrphy_decapvddq_dbyte_ew 0 0 0 \
  ]

# boundary_dbyte_decapvddq_dbyte_ns
set floorplans(boundary_dbyte_decapvddq_dbyte_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphydbyte_top_ns 0 0 0 \
  dwc_ddrphy_decapvddq_dbyte_ns 1 3 0 \$y_dwc_ddrphy_decapvddq_dbyte_ns 0 \$y_dwc_ddrphydbyte_top_ns 0 0 \
  ]

# boundary_dbyte_decapvddq_ew
set floorplans(boundary_dbyte_decapvddq_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphydbyte_top_ew}-3*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphydbyte_top_ew}-3*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphydbyte_top_ew 0 0 \
  dwc_ddrphy_decapvddq_ew 3 3 \$x_dwc_ddrphy_decapvddq_ew \$y_dwc_ddrphy_decapvddq_ew -3*\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  ]

# boundary_dbyte_decapvddq_ns
set floorplans(boundary_dbyte_decapvddq_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphydbyte_top_ns 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 3 \$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphy_decapvddq_ns 0 \$y_dwc_ddrphydbyte_top_ns 0 0 \
  ]

# boundary_dbyte_vddqlpclamp_dbyte_ew
set floorplans(boundary_dbyte_vddqlpclamp_dbyte_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphydbyte_top_ew}-3*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphydbyte_top_ew}-3*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphydbyte_top_ew 0 0 \
  dwc_ddrphy_decapvddq_dbyte_ew 2 1 \$x_dwc_ddrphy_decapvddq_dbyte_ew 0 -2*\${x_dwc_ddrphy_decapvddq_dbyte_ew}-\$x_dwc_ddrphy_vddqlpclamp_dbyte_ew 0 0 0 \
  dwc_ddrphy_vddqlpclamp_dbyte_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqlpclamp_dbyte_ew 0 0 0 \
  ]

# boundary_dbyte_vddqlpclamp_dbyte_ns
set floorplans(boundary_dbyte_vddqlpclamp_dbyte_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphydbyte_top_ns 0 0 0 \
  dwc_ddrphy_vddqlpclamp_dbyte_ns 1 1 0 0 0 \$y_dwc_ddrphydbyte_top_ns 0 0 \
  dwc_ddrphy_decapvddq_dbyte_ns 1 2 0 \$y_dwc_ddrphy_decapvddq_dbyte_ns 0 \${y_dwc_ddrphydbyte_top_ns}+\$y_dwc_ddrphy_vddqlpclamp_dbyte_ns 0 0 \
  ]

# boundary_dbyte_vddqlpclamp_ew
set floorplans(boundary_dbyte_vddqlpclamp_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphydbyte_top_ew}-3*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphydbyte_top_ew}-3*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphydbyte_top_ew 0 0 \
  dwc_ddrphy_decapvddq_ew 2 3 \$x_dwc_ddrphy_decapvddq_ew \$y_dwc_ddrphy_decapvddq_ew -2*\${x_dwc_ddrphy_decapvddq_ew}-\$x_dwc_ddrphy_vddqlpclamp_ew 0 0 0 \
  dwc_ddrphy_vddqlpclamp_ew 1 3 0 \$y_dwc_ddrphy_vddqlpclamp_ew -\$x_dwc_ddrphy_vddqlpclamp_ew 0 0 0 \
  ]

# boundary_dbyte_vddqlpclamp_ns
set floorplans(boundary_dbyte_vddqlpclamp_ns) [list \
  dwc_ddrphydbyte_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphydbyte_top_ns 0 0 0 \
  dwc_ddrphy_vddqlpclamp_ns 3 1 \$x_dwc_ddrphy_vddqlpclamp_ns 0 0 \$y_dwc_ddrphydbyte_top_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 2 \$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphy_decapvddq_ns 0 \${y_dwc_ddrphydbyte_top_ns}+\$y_dwc_ddrphy_vddqlpclamp_ns 0 0 \
  ]

# boundary_master_decapvddq_ew
set floorplans(boundary_master_decapvddq_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphymaster_top}-3*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphymaster_top}-3*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvddq_ew 2 3 \$x_dwc_ddrphy_decapvddq_ew \$y_dwc_ddrphy_decapvddq_ew -2*\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  ]

# boundary_master_decapvddq_master_ew
set floorplans(boundary_master_decapvddq_master_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphymaster_top}-3*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphymaster_top}-3*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvddq_master_ew 2 1 \$x_dwc_ddrphy_decapvddq_master_ew 0 -2*\$x_dwc_ddrphy_decapvddq_master_ew 0 0 0 \
  ]

# boundary_master_decapvddq_master_ns
set floorplans(boundary_master_decapvddq_master_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_decapvddq_master_ns 1 2 0 \$y_dwc_ddrphy_decapvddq_master_ns 0 \$y_dwc_ddrphymaster_top 0 0 \
  ]

# boundary_master_decapvddq_ns
set floorplans(boundary_master_decapvddq_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 2 \$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphy_decapvddq_ns 0 \$y_dwc_ddrphymaster_top 0 0 \
  ]

# boundary_master_vddqlpclamp_ew
set floorplans(boundary_master_vddqlpclamp_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphymaster_top}-3*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphymaster_top}-3*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vddqlpclamp_ew 1 3 0 \$y_dwc_ddrphy_vddqlpclamp_ew -\$x_dwc_ddrphy_vddqlpclamp_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\${x_dwc_ddrphy_vddqlpclamp_ew}-\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  ]

# boundary_master_vddqlpclamp_master_ew
set floorplans(boundary_master_vddqlpclamp_master_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphymaster_top}-3*\$x_dwc_ddrphy_decapvddq_ns -\$y_dwc_ddrphy_decapvddq_ns 0 0 \
  dwc_ddrphy_decapvddq_ns 3 1 \$x_dwc_ddrphy_decapvddq_ns 0 \${x_dwc_ddrphymaster_top}-3*\$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_vddqlpclamp_master_ew 1 1 0 0 -\$x_dwc_ddrphy_vddqlpclamp_master_ew 0 0 0 \
  dwc_ddrphy_decapvddq_master_ew 1 1 0 0 -\${x_dwc_ddrphy_vddqlpclamp_master_ew}-\$x_dwc_ddrphy_decapvddq_master_ew 0 0 0 \
  ]

# boundary_master_vddqlpclamp_master_ns
set floorplans(boundary_master_vddqlpclamp_master_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_vddqlpclamp_master_ns 1 1 0 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvddq_master_ns 1 2 0 \$y_dwc_ddrphy_decapvddq_master_ns 0 \${y_dwc_ddrphymaster_top}+\$y_dwc_ddrphy_vddqlpclamp_master_ns 0 0 \
  ]

# boundary_master_vddqlpclamp_ns
set floorplans(boundary_master_vddqlpclamp_ns) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew -\$x_dwc_ddrphy_decapvddq_ew 0 0 0 \
  dwc_ddrphy_decapvddq_ew 1 3 0 \$y_dwc_ddrphy_decapvddq_ew \$x_dwc_ddrphymaster_top 0 0 0 \
  dwc_ddrphy_vddqlpclamp_ns 3 1 \$x_dwc_ddrphy_vddqlpclamp_ns 0 0 \$y_dwc_ddrphymaster_top 0 0 \
  dwc_ddrphy_decapvddq_ns 3 2 \$x_dwc_ddrphy_decapvddq_ns \$y_dwc_ddrphy_decapvddq_ns 0 \${y_dwc_ddrphymaster_top}+\$y_dwc_ddrphy_vddqlpclamp_ns 0 0 \
  ]

# perc_acx4_vddclamp_ew
set floorplans(perc_acx4_vddclamp_ew) [list \
  dwc_ddrphyacx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vddclamp_ew 1 1 0 0 \$x_dwc_ddrphyacx4_top_ew 0 0 0 \
  ]
  
# perc_dbyte_vddclamp_ew
set floorplans(perc_dbyte_vddclamp_ew) [list \
  dwc_ddrphydbyte_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vddclamp_ew 1 1 0 0 \$x_dwc_ddrphydbyte_top_ew 0 0 0 \
  ]

# perc_master_vddclamp_ew
set floorplans(perc_master_vddclamp_ew) [list \
  dwc_ddrphymaster_top 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vddclamp_ew 1 1 0 0 \$x_dwc_ddrphymaster_top 0 0 0 \
  ]

# DDR5 testcases

# ddr5_abutment_ac_ac_ew
set floorplans(ddr5_abutment_ac_ac_ew) [list \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 0 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 2*\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 2*\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 2*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 2*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 3*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 3*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 3*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  ]

# ddr5_abutment_ac_ck_ew
set floorplans(ddr5_abutment_ac_ck_ew) [list \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 0 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 2*\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 2*\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 3*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 3*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 3*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 4*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 4*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 4*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  ]

# ddr5_abutment_ac_cmos_ew
set floorplans(ddr5_abutment_ac_cmos_ew) [list \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ac_ew} 0 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ac_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ac_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 3*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 3*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ac_ew} 3*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 4*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 4*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ac_ew} 4*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  ]

# ddr5_abutment_ac_pclk_snapcap_ns
set floorplans(ddr5_abutment_ac_pclk_snapcap_ns) [list \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ns} 0 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+3*\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 180 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+4*\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 180 1 \
  dwc_ddr5phy_pclk_routing_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+3*\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew} 180 1 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+4*\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew} 180 1 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phy_pclk_routing_ac_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phy_pclk_routing_ac_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phy_pclk_routing_ac_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+3*\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phy_pclk_routing_ac_ew} 180 1 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phyacx2_top_ew}+4*\${x_dwc_ddr5phy_decapvsh_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phy_pclk_routing_ac_ew} 180 1 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns}+2*\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phy_pclk_routing_ac_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ns} \${y_dwc_ddr5phy_decapvddq_ld_ns}+2*\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phy_pclk_routing_ac_ew} 0 0 \
  ]

# ddr5_abutment_ac_zcal_ew
set floorplans(ddr5_abutment_ac_zcal_ew) [list \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvsh_zcal_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 0 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_zcal_ew 1 1 0 0 0 \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_zcal_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phyacx2_top_ew} 0 0 \
  ]

# ddr5_abutment_ck_ck_ew
set floorplans(ddr5_abutment_ck_ck_ew) [list \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 0 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 2*\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 2*\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 3*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 3*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 3*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  ]

# ddr5_abutment_ck_cmos_ew
set floorplans(ddr5_abutment_ck_cmos_ew) [list \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 0 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 3*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 3*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 3*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 4*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 4*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 4*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  ]

# ddr5_abutment_ck_snapcap_ns
set floorplans(ddr5_abutment_ck_snapcap_ns) [list \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ns} 0 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 \${x_dwc_ddr5phyckx2_top_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phyckx2_top_ew}+\${x_dwc_ddr5phy_decapvsh_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phyckx2_top_ew}+2*\${x_dwc_ddr5phy_decapvsh_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ns} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  ]

# ddr5_abutment_ck_zcal_ew
set floorplans(ddr5_abutment_ck_zcal_ew) [list \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvsh_zcal_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 0 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_zcal_ew 1 1 0 0 0 \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_zcal_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phyckx2_top_ew} 0 0 \
  ]

# ddr5_abutment_cmos_snapcap_ns
set floorplans(ddr5_abutment_cmos_snapcap_ns) [list \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ns} 0 0 0 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phycmosx2_top_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phycmosx2_top_ew}+\${x_dwc_ddr5phy_decapvddq_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phycmosx2_top_ew}+2*\${x_dwc_ddr5phy_decapvddq_ld_ac_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ns} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  ]

# ddr5_abutment_cmos_zcal_ew
set floorplans(ddr5_abutment_cmos_zcal_ew) [list \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_zcal_ew} 0 0 0 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_zcal_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 0 \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_zcal_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_zcal_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_zcal_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phycmosx2_top_ew} 0 0 \
  ]
  
  
# ddr5_abutment_dx_pclk_snapcap_ns
set floorplans(ddr5_abutment_dx_pclk_snapcap_ns) [list \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ns} 0 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_ns} 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 3*\${x_dwc_ddr5phy_decapvddq_ns} 0 0 0 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew}+\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew}+2*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew}+4*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 180 0 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew}+5*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 180 0 \
  dwc_ddr5phy_pclk_routing_dx_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+2*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+3*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+4*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+5*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+6*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+7*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+9*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 180 1 \
  dwc_ddr5phy_pclk_routing_decap_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+10*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew} 180 1 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  dwc_ddr5phy_decapvsh_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew}+\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew}+2*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew}+4*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 180 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_top_ew}+\${x_dwc_ddr5phydx4_tcoil_ew}+5*\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 180 1 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ns}+2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ns} \${y_dwc_ddr5phy_decapvddq_ns}+2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_ns} \${y_dwc_ddr5phy_decapvddq_ns}+2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 3*\${x_dwc_ddr5phy_decapvddq_ns} \${y_dwc_ddr5phy_decapvddq_ns}+2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phy_pclk_routing_dx_ew} 0 0 \
  ]

# ddr5_abutment_dx4_ac_ew
set floorplans(ddr5_abutment_dx4_ac_ew) [list \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_dx4_ew} 0 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 0 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_dx4_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyacx2_top_ew} 0 1 \
  ]

# ddr5_abutment_dx4_ck_ew
set floorplans(ddr5_abutment_dx4_ck_ew) [list \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_dx4_ew} 0 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 0 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_dx4_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyckx2_top_ew} 0 1 \
  ]

# ddr5_abutment_dx4_cmos_ew
set floorplans(ddr5_abutment_dx4_cmos_ew) [list \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_dx4_ew} 0 0 0 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 0 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_dx4_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phycmosx2_top_ew} 0 1 \
  ]

# ddr5_abutment_dx4_dx4_ew
set floorplans(ddr5_abutment_dx4_dx4_ew) [list \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvsh_ld_dx4_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ld_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_dx4_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ld_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  ]

# ddr5_abutment_dx4_tcoil_ew
set floorplans(ddr5_abutment_dx4_tcoil_ew) [list \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_tcoil_ew} \${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_tcoil_ew}+\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_tcoil_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_tcoil_ew}+\${x_dwc_ddr5phy_decapvddq_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 3*\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 3*\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_tcoil_ew} 3*\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phydx4_tcoil_ew}+\${x_dwc_ddr5phy_decapvddq_dx4_ew} 3*\${y_dwc_ddr5phydx4_top_ew} 0 1 \
  ]

# ddr5_abutment_dx4_zcal_ew
set floorplans(ddr5_abutment_dx4_zcal_ew) [list \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_dx4_ew} 0 0 0 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyzcal_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 0 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyzcal_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_dx4_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phyzcal_top_ew} 0 1 \
  ]

# ddr5_abutment_pac_ac_ew
set floorplans(ddr5_abutment_pac_ac_ew) [list \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 0 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} \${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 0 \${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} \${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} \${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} \${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} 2*\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 2*\${y_dwc_ddr5phyacx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phyacx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyacx2_top_ew} 2*\${y_dwc_ddr5phyacx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyacx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 2*\${y_dwc_ddr5phyacx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  ]
  
# ddr5_abutment_pac_ck_ew
set floorplans(ddr5_abutment_pac_ck_ew) [list \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvsh_ac_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 0 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} \${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 0 \${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} \${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} \${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} \${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} 2*\${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 2*\${y_dwc_ddr5phyckx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phyckx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phyckx2_top_ew} 2*\${y_dwc_ddr5phyckx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyckx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ac_ew} 2*\${y_dwc_ddr5phyckx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  ]

# ddr5_abutment_pac_cmos_ew
set floorplans(ddr5_abutment_pac_cmos_ew) [list \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 0 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} \${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 0 \${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} \${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} \${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 0 \${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} \${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 0 2*\${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phycmosx2_top_ew 1 1 0 0 -\${x_dwc_ddr5phycmosx2_top_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 0 2*\${y_dwc_ddr5phycmosx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ac_ew} 2*\${y_dwc_ddr5phycmosx2_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  ]
    
# ddr5_abutment_pac_dx4_ew
set floorplans(ddr5_abutment_pac_dx4_ew) [list \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvsh_ld_dx4_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ld_dx4_ew} 0 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ld_dx4_ew} \${y_dwc_ddr5phydx4_top_ew} 0 0 \
  dwc_ddr5phydx4_top_ew 1 1 0 0 -\${x_dwc_ddr5phydx4_top_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvsh_dx4_ew 1 1 0 0 0 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_ld_dx4_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_ld_dx4_ew} 2*\${y_dwc_ddr5phydx4_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  ]

# ddr5_abutment_pac_snapcap_ns
set floorplans(ddr5_abutment_pac_snapcap_ns) [list \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ns} 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_ld_ns} 0 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phymaster_top_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 \${x_dwc_ddr5phymaster_top_ew}+\${x_dwc_ddr5phy_decapvddq_ld_master_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phymaster_top_ew}+2*\${x_dwc_ddr5phy_decapvddq_ld_master_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phymaster_top_ew}+3*\${x_dwc_ddr5phy_decapvddq_ld_master_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 \${x_dwc_ddr5phymaster_top_ew}+4*\${x_dwc_ddr5phy_decapvddq_ld_master_ew} \${y_dwc_ddr5phy_decapvddq_ld_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ld_ns} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_ld_ns} \${y_dwc_ddr5phy_decapvddq_ld_ns}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  ]

# ddr5_abutment_pac_zcal_ew
set floorplans(ddr5_abutment_pac_zcal_ew) [list \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} 0 0 0 \
  dwc_ddr5phy_decapvsh_zcal_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 0 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 0 \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 1 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_zcal_ew 1 1 0 0 0 \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} \${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phymaster_top_ew 1 1 0 0 -\${x_dwc_ddr5phymaster_top_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 -\${x_dwc_ddr5phyzcal_top_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_zcal_ew 1 1 0 0 0 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvsh_zcal_ew} 2*\${y_dwc_ddr5phyzcal_top_ew}+2*\${y_dwc_ddr5phymaster_top_ew} 0 0 \
  ]

# ddr5_abutment_tcoil_ew
set floorplans(ddr5_abutment_tcoil_ew) [list \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 0 \${y_dwc_ddr5phydx4_tcoil_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_master_ew} \${y_dwc_ddr5phydx4_tcoil_ew} 0 0 \
  dwc_ddr5phy_decapvddq_master_ew 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_master_ew} \${y_dwc_ddr5phydx4_tcoil_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 3*\${x_dwc_ddr5phy_decapvddq_master_ew} \${y_dwc_ddr5phydx4_tcoil_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_master_ew 1 1 0 0 4*\${x_dwc_ddr5phy_decapvddq_master_ew} \${y_dwc_ddr5phydx4_tcoil_ew} 0 0 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 2*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew} 0 1 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 2*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_zcal_ew 1 1 0 0 0 3*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_master_ew} 3*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_master_ew} 3*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 3*\${x_dwc_ddr5phy_decapvddq_master_ew} 3*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 4*\${x_dwc_ddr5phy_decapvddq_master_ew} 3*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew} 0 0 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 4*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew}+\${y_dwc_ddr5phy_decapvsh_ld_zcal_ew} 0 1 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 4*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew}+\${y_dwc_ddr5phy_decapvsh_ld_zcal_ew} 0 0 \
  dwc_ddr5phy_decapvsh_ld_ac_ew 1 1 0 0 0 5*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew}+\${y_dwc_ddr5phy_decapvsh_ld_zcal_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_master_ew} 5*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew}+\${y_dwc_ddr5phy_decapvsh_ld_zcal_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_master_ew} 5*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew}+\${y_dwc_ddr5phy_decapvsh_ld_zcal_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ac_ew 1 1 0 0 3*\${x_dwc_ddr5phy_decapvddq_master_ew} 5*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew}+\${y_dwc_ddr5phy_decapvsh_ld_zcal_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ac_ew 1 1 0 0 4*\${x_dwc_ddr5phy_decapvddq_master_ew} 5*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew}+\${y_dwc_ddr5phy_decapvsh_ld_zcal_ew} 0 0 \
  dwc_ddr5phydx4_tcoil_ew 1 1 0 0 0 6*\${y_dwc_ddr5phydx4_tcoil_ew}+\${y_dwc_ddr5phy_decapvddq_master_ew}+\${y_dwc_ddr5phy_decapvsh_ld_zcal_ew}+\${y_dwc_ddr5phy_decapvsh_ld_ac_ew} 0 1 \
  ]

# ddr5_abutment_zcal_snapcap_ns
set floorplans(ddr5_abutment_zcal_snapcap_ns) [list \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 0 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ns} 0 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_ns} 0 0 0 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ns} 0 0 \
  dwc_ddr5phy_decapvsh_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew} \${y_dwc_ddr5phy_decapvddq_ns} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew}+\${x_dwc_ddr5phy_decapvsh_ld_zcal_ew} \${y_dwc_ddr5phy_decapvddq_ns} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew}+2*\${x_dwc_ddr5phy_decapvsh_ld_zcal_ew} \${y_dwc_ddr5phy_decapvddq_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew}+3*\${x_dwc_ddr5phy_decapvsh_ld_zcal_ew} \${y_dwc_ddr5phy_decapvddq_ns} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew}+4*\${x_dwc_ddr5phy_decapvsh_ld_zcal_ew} \${y_dwc_ddr5phy_decapvddq_ns} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ns} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_ns} \${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 0 2*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ns} 2*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_ns} 2*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phyzcal_top_ew 1 1 0 0 0 3*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvsh_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew} 3*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew}+\${x_dwc_ddr5phy_decapvsh_ld_zcal_ew} 3*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew}+2*\${x_dwc_ddr5phy_decapvsh_ld_zcal_ew} 3*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew}+3*\${x_dwc_ddr5phy_decapvsh_ld_zcal_ew} 3*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_zcal_ew 1 1 0 0 \${x_dwc_ddr5phyzcal_top_ew}+4*\${x_dwc_ddr5phy_decapvsh_ld_zcal_ew} 3*\${y_dwc_ddr5phy_decapvddq_ns}+\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 0 3*\${y_dwc_ddr5phy_decapvddq_ns}+2*\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ld_ns 1 1 0 0 \${x_dwc_ddr5phy_decapvddq_ns} 3*\${y_dwc_ddr5phy_decapvddq_ns}+2*\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  dwc_ddr5phy_decapvddq_ns 1 1 0 0 2*\${x_dwc_ddr5phy_decapvddq_ns} 3*\${y_dwc_ddr5phy_decapvddq_ns}+2*\${y_dwc_ddr5phyzcal_top_ew} 0 0 \
  ]

# LPDDR54 testcases

# Procedures for placing hard macros as per AC and DBYTE constructs.
proc place_dbyte_dmi_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+5*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+7*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+10*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+11*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+12*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_dbyte_dmi_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+5*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+7*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+10*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+11*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+12*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_dbyte_dmi_mirrored_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+6*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+10*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+11*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+12*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_dbyte_dmi_mirrored_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+10*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+11*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+12*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_dbyte_nodmi_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+6*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+10*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+11*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_dbyte_nodmi_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+10*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+11*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_dbyte_dmilp4_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+5*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+7*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+10*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_dbyte_dmilp4_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+5*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+7*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+10*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_dbyte_dmilp4_mirrored_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+6*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+7*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+10*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_dbyte_dmilp4_mirrored_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+7*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+10*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_dbyte_nodmilp4_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+6*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+7*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_dbyte_nodmilp4_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+7*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_ac1r_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphysec_top_ns 1 1 0 0 ${x_offset}+6*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+7*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_ac1r_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphysec_top_ew 1 1 0 0 ${x_offset} ${y_offset}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+7*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_ac1r_mirrored_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphysec_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+6*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+7*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_ac1r_mirrored_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphysec_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+7*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_ac2r_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphysec_top_ns 1 1 0 0 ${x_offset}+6*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphysec_top_ns 1 1 0 0 ${x_offset}+7*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+10*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+11*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_ac2r_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphysec_top_ew 1 1 0 0 ${x_offset} ${y_offset}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphysec_top_ew 1 1 0 0 ${x_offset} ${y_offset}+7*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+10*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+11*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

proc place_ac2r_mirrored_ns {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+2*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+3*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphysec_top_ns 1 1 0 0 ${x_offset}+4*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphysec_top_ns 1 1 0 0 ${x_offset}+5*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphydiff_top_ns 1 1 0 0 ${x_offset}+6*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+8*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+9*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+10*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    dwc_ddrphyse_top_ns 1 1 0 0 ${x_offset}+11*\${x_dwc_ddrphyse_top_ns} $y_offset 0 0 \
    ]
}

proc place_ac2r_mirrored_ew {x_offset y_offset} {
  return [list \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+2*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+3*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphysec_top_ew 1 1 0 0 ${x_offset} ${y_offset}+4*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphysec_top_ew 1 1 0 0 ${x_offset} ${y_offset}+5*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphydiff_top_ew 1 1 0 0 ${x_offset} ${y_offset}+6*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+8*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+9*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+10*\${y_dwc_ddrphyse_top_ew} 0 0 \
    dwc_ddrphyse_top_ew 1 1 0 0 ${x_offset} ${y_offset}+11*\${y_dwc_ddrphyse_top_ew} 0 0 \
    ]
}

# boundary_cornerclamp_stdcell
set floorplans(boundary_cornerclamp_stdcell) [concat \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_corner 1 1 0 0 0 \${y_dwc_ddrphy_clamp_master_corner} 0 1 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  ]

# dwc_ddrphy_dbyte_dmi_ns
set floorplans(dwc_ddrphy_dbyte_dmi_ns) [concat \
  [place_dbyte_dmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  ]

# dwc_ddrphy_dbyte_dmi_ew
set floorplans(dwc_ddrphy_dbyte_dmi_ew) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  ]

# dwc_ddrphy_dbyte_dmi_mirrored_ns
set floorplans(dwc_ddrphy_dbyte_dmi_mirrored_ns) [concat \
  [place_dbyte_dmi_mirrored_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  ]

# dwc_ddrphy_dbyte_dmi_mirrored_ew
set floorplans(dwc_ddrphy_dbyte_dmi_mirrored_ew) [concat \
  [place_dbyte_dmi_mirrored_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  ]

# dwc_ddrphy_dbyte_nodmi_ns
set floorplans(dwc_ddrphy_dbyte_nodmi_ns) [concat \
  [place_dbyte_nodmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  ]

# dwc_ddrphy_dbyte_nodmi_ew
set floorplans(dwc_ddrphy_dbyte_nodmi_ew) [concat \
  [place_dbyte_nodmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 0 \
  ]

# dwc_ddrphy_dbyte_dmilp4_ns
set floorplans(dwc_ddrphy_dbyte_dmilp4_ns) [concat \
  [place_dbyte_dmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  ]

# dwc_ddrphy_dbyte_dmilp4_ew
set floorplans(dwc_ddrphy_dbyte_dmilp4_ew) [concat \
  [place_dbyte_dmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 0 0 0 \
  ]

# dwc_ddrphy_dbyte_dmilp4_mirrored_ns
set floorplans(dwc_ddrphy_dbyte_dmilp4_mirrored_ns) [concat \
  [place_dbyte_dmilp4_mirrored_ns 0 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  ]

# dwc_ddrphy_dbyte_dmilp4_mirrored_ew
set floorplans(dwc_ddrphy_dbyte_dmilp4_mirrored_ew) [concat \
  [place_dbyte_dmilp4_mirrored_ew 0 0] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 0 0 0 \
  ]

# dwc_ddrphy_dbyte_nodmilp4_ns
set floorplans(dwc_ddrphy_dbyte_nodmilp4_ns) [concat \
  [place_dbyte_nodmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  ]

# dwc_ddrphy_dbyte_nodmilp4_ew
set floorplans(dwc_ddrphy_dbyte_nodmilp4_ew) [concat \
  [place_dbyte_nodmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 0 0 0 \
  ]

# dwc_ddrphy_ac1r_ns
set floorplans(dwc_ddrphy_ac1r_ns) [concat \
  [place_ac1r_ns 0 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  ]

# dwc_ddrphy_ac1r_ew
set floorplans(dwc_ddrphy_ac1r_ew) [concat \
  [place_ac1r_ew 0 0] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 0 \
  ]

# dwc_ddrphy_ac1r_mirrored_ns
set floorplans(dwc_ddrphy_ac1r_mirrored_ns) [concat \
  [place_ac1r_mirrored_ns 0 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  ]

# dwc_ddrphy_ac1r_mirrored_ew
set floorplans(dwc_ddrphy_ac1r_mirrored_ew) [concat \
  [place_ac1r_mirrored_ew 0 0] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew} 0 1 \
  ]

# dwc_ddrphy_ac2r_ns
set floorplans(dwc_ddrphy_ac2r_ns) [concat \
  [place_ac2r_ns 0 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  ]
  
# dwc_ddrphy_ac2r_ew
set floorplans(dwc_ddrphy_ac2r_ew) [concat \
  [place_ac2r_ew 0 0] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 0 0 0 \
  ]  
  
# dwc_ddrphy_ac2r_mirrored_ns
set floorplans(dwc_ddrphy_ac2r_mirrored_ns) [concat \
  [place_ac2r_mirrored_ns 0 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  ]

# dwc_ddrphy_ac2r_mirrored_ew
set floorplans(dwc_ddrphy_ac2r_mirrored_ew) [concat \
  [place_ac2r_mirrored_ew 0 0] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 1 \
  ]
  
# dwc_ddrphy_master_ns
set floorplans(dwc_ddrphy_master_ns) [list \
  dwc_ddrphymaster_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 0 -\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns} 0 0 \
  ]

# dwc_ddrphy_master_ew
set floorplans(dwc_ddrphy_master_ew) [list \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 0 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 0 0 0 \
  ]

# abutment_ac1r_master_ns
set floorplans(abutment_ac1r_master_ns) [concat \
  dwc_ddrphymaster_top_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} 0 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  [place_ac1r_ns \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+10*\${x_dwc_ddrphyse_top_ns} 0 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+10*\${x_dwc_ddrphyse_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+10*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+10*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  [place_ac1r_mirrored_ns 2*\${x_dwc_ddrphymaster_top_ns}+10*\${x_dwc_ddrphyse_top_ns}  \${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  dwc_ddrphymaster_top_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  [place_ac1r_ns 3*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+30*\${x_dwc_ddrphyse_top_ns} 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+30*\${x_dwc_ddrphyse_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+30*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+30*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  [place_ac1r_mirrored_ns 4*\${x_dwc_ddrphymaster_top_ns}+30*\${x_dwc_ddrphyse_top_ns}  \${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 4*\${x_dwc_ddrphymaster_top_ns}+40*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 4*\${x_dwc_ddrphymaster_top_ns}+40*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  ]

# abutment_ac2r_master_ns
set floorplans(abutment_ac2r_master_ns) [concat \
  dwc_ddrphymaster_top_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} 0 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  [place_ac2r_ns \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+12*\${x_dwc_ddrphyse_top_ns} 0 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+12*\${x_dwc_ddrphyse_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+12*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+12*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  [place_ac2r_mirrored_ns 2*\${x_dwc_ddrphymaster_top_ns}+12*\${x_dwc_ddrphyse_top_ns}  \${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  dwc_ddrphymaster_top_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 2*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  [place_ac2r_ns 3*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+36*\${x_dwc_ddrphyse_top_ns} 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+36*\${x_dwc_ddrphyse_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+36*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 3*\${x_dwc_ddrphymaster_top_ns}+36*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  [place_ac2r_mirrored_ns 4*\${x_dwc_ddrphymaster_top_ns}+36*\${x_dwc_ddrphyse_top_ns}  \${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 4*\${x_dwc_ddrphymaster_top_ns}+48*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 4*\${x_dwc_ddrphymaster_top_ns}+48*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  ]

# abutment_cornerclamp_ac1r
set floorplans(abutment_cornerclamp_ac1r) [concat \
  [place_ac1r_ew 0 0] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_4x1_ew} -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} 2*\${y_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} 10*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_corner 1 1 0 0 0 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 1 \
  [place_ac1r_mirrored_ns \${x_dwc_ddrphy_clamp_master_corner} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}+\${y_dwc_ddrphy_clamp_ac1r_ns} 180 1 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns}-\${x_dwc_ddrphy_decapvddhd_1x1_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns}-\${x_dwc_ddrphy_decapvddhd_1x1_ns}-\${x_dwc_ddrphy_decapvdd_4x1_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns}-2*\${x_dwc_ddrphy_decapvddhd_1x1_ns}-\${x_dwc_ddrphy_decapvdd_4x1_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvddhd_4x1_ns} 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns}-2*\${x_dwc_ddrphy_decapvddhd_1x1_ns}-4*\${x_dwc_ddrphy_decapvdd_4x1_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns}-3*\${x_dwc_ddrphy_decapvddhd_1x1_ns}-4*\${x_dwc_ddrphy_decapvdd_4x1_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  ]

# abutment_cornerclamp_ac2r
set floorplans(abutment_cornerclamp_ac2r) [concat \
  [place_ac2r_ew 0 0] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 5 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_corner 1 1 0 0 0 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 1 \
  [place_ac2r_mirrored_ns \${x_dwc_ddrphy_clamp_master_corner} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+12*\${x_dwc_ddrphyse_top_ns} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+12*\${x_dwc_ddrphyse_top_ns} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}+\${y_dwc_ddrphy_clamp_ac2r_ns} 180 1 \
  dwc_ddrphy_decapvdd_4x1_ns 5 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphy_clamp_master_corner}+12*\${x_dwc_ddrphyse_top_ns}-5*\${x_dwc_ddrphy_decapvdd_4x1_ns} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+12*\${x_dwc_ddrphyse_top_ns}-5*\${x_dwc_ddrphy_decapvdd_4x1_ns}-\${x_dwc_ddrphy_decapvdd_1x1_ns} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  ]

# abutment_cornerclamp_d13
set floorplans(abutment_cornerclamp_d13) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_1x1_ew} \${y_dwc_ddrphy_decapvdd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvdd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvdd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvdd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_4x1_ew}+\${y_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvdd_1x1_ew} 2*\${y_dwc_ddrphy_decapvddhd_4x1_ew}+\${y_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_1x1_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvdd_1x1_ew} 13*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_corner 1 1 0 0 0 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 1 \
  [place_dbyte_dmi_ns \${x_dwc_ddrphy_clamp_master_corner} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}+\${y_dwc_ddrphy_clamp_dbyte13_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphy_clamp_master_corner}+\${x_dwc_ddrphy_decapvdd_1x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}+\${y_dwc_ddrphy_clamp_dbyte13_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+13*\${x_dwc_ddrphyse_top_ns}-\${x_dwc_ddrphy_decapvddqhd_4x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+13*\${x_dwc_ddrphyse_top_ns}-2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+13*\${x_dwc_ddrphyse_top_ns}-3*\${x_dwc_ddrphy_decapvddqhd_4x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddq_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+13*\${x_dwc_ddrphyse_top_ns}-3*\${x_dwc_ddrphy_decapvddqhd_4x1_ns}-\${x_dwc_ddrphy_decapvddq_1x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+13*\${x_dwc_ddrphyse_top_ns}-4*\${x_dwc_ddrphy_decapvddqhd_4x1_ns}-\${x_dwc_ddrphy_decapvddq_1x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+13*\${x_dwc_ddrphyse_top_ns}-5*\${x_dwc_ddrphy_decapvddqhd_4x1_ns}-\${x_dwc_ddrphy_decapvddq_1x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+13*\${x_dwc_ddrphyse_top_ns}-5*\${x_dwc_ddrphy_decapvddqhd_4x1_ns}-2*\${x_dwc_ddrphy_decapvddq_1x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 0 \
  ]

# abutment_d13_master_ns
set floorplans(abutment_d13_master_ns) [concat \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_dmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_dmi_ns 13*\${x_dwc_ddrphyse_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 14*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 26*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 26*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 26*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 26*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_dmi_ns 26*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 26*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 26*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 27*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 39*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 39*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 39*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 39*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 180 1 \
  [place_dbyte_dmi_ns 39*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 39*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 39*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 52*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 52*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  ]

# abutment_d13_ac1r_ns
set floorplans(abutment_d13_ac1r_ns) [concat \
  [place_dbyte_dmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac1r_ns 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmi_ns 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_ns 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmi_ns 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 47*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 59*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 59*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_ns 59*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 59*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 59*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmi_ns 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 70*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]

# abutment_d13_ac1r_mirrored_ns
set floorplans(abutment_d13_ac1r_mirrored_ns) [concat \
  [place_dbyte_dmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac1r_mirrored_ns 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmi_ns 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_mirrored_ns 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmi_ns 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 47*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 59*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 59*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_mirrored_ns 59*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmi_ns 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 70*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]

# abutment_d13_ac2r_ns
set floorplans(abutment_d13_ac2r_ns) [concat \
  [place_dbyte_dmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac2r_ns 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmi_ns 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 26*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_ns 38*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 38*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 38*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmi_ns 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 51*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_ns 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmi_ns 75*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 75*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 75*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 76*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]

# abutment_d13_ac2r_mirrored_ns
set floorplans(abutment_d13_ac2r_mirrored_ns) [concat \
  [place_dbyte_dmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac2r_mirrored_ns 13*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmi_ns 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 26*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_mirrored_ns 38*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmi_ns 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 51*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_mirrored_ns 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 75*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 75*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmi_ns 75*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 75*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 75*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 76*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]

# abutment_d12_master_ns
set floorplans(abutment_d12_master_ns) [concat \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_nodmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_nodmi_ns 12*\${x_dwc_ddrphyse_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 12*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_nodmi_ns 24*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 24*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 180 1 \
  [place_dbyte_nodmi_ns 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 48*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 48*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  ]

# abutment_d12_ac1r_ns
set floorplans(abutment_d12_ac1r_ns) [concat \
  [place_dbyte_nodmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac1r_ns 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmi_ns 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_ns 34*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 34*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 34*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmi_ns 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 56*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 56*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_ns 56*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 56*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 56*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmi_ns 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]

# abutment_d12_ac1r_mirrored_ns
set floorplans(abutment_d12_ac1r_mirrored_ns) [concat \
  [place_dbyte_nodmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac1r_mirrored_ns 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmi_ns 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_mirrored_ns 34*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmi_ns 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 56*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 56*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_mirrored_ns 56*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmi_ns 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]

# abutment_d12_ac2r_ns
set floorplans(abutment_d12_ac2r_ns) [concat \
  [place_dbyte_nodmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac2r_ns 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmi_ns 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_ns 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 48*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 48*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmi_ns 48*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 48*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 48*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_ns 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmi_ns 72*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 72*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 72*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]

# abutment_d12_ac2r_mirrored_ns
set floorplans(abutment_d12_ac2r_mirrored_ns) [concat \
  [place_dbyte_nodmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac2r_mirrored_ns 12*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmi_ns 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 24*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_mirrored_ns 36*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 48*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 48*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 48*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 48*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmi_ns 48*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 48*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 48*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_mirrored_ns 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 72*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 72*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmi_ns 72*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 72*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 72*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]
  
# abutment_d11_master_ns
set floorplans(abutment_d11_master_ns) [concat \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_dmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 4*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 7*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_dmilp4_ns 11*\${x_dwc_ddrphyse_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 15*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 18*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_dmilp4_ns 22*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 26*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 29*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 33*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 33*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 33*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 33*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 180 1 \
  [place_dbyte_dmilp4_ns 33*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 33*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 33*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 37*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  ]

# abutment_d11_ac1r_ns
set floorplans(abutment_d11_ac1r_ns) [concat \
  [place_dbyte_dmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 4*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 7*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac1r_ns 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmilp4_ns 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 28*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_ns 32*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 32*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 32*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmilp4_ns 42*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 49*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 53*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 53*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_ns 53*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 53*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 53*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmilp4_ns 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 67*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 70*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]

# abutment_d11_ac1r_mirrored_ns
set floorplans(abutment_d11_ac1r_mirrored_ns) [concat \
  [place_dbyte_dmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 4*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 7*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac1r_mirrored_ns 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmilp4_ns 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 21*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 25*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 28*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_mirrored_ns 32*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmilp4_ns 42*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 42*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 49*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 53*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 53*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_mirrored_ns 53*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmilp4_ns 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 63*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 67*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 70*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]
  
# abutment_d11_ac2r_ns
set floorplans(abutment_d11_ac2r_ns) [concat \
  [place_dbyte_dmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 4*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 7*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac2r_ns 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmilp4_ns 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 27*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_ns 34*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 34*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 34*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmilp4_ns 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 53*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 57*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 57*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_ns 57*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 57*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 57*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmilp4_ns 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 73*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 76*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]
  
# abutment_d11_ac2r_mirrored_ns
set floorplans(abutment_d11_ac2r_mirrored_ns) [concat \
  [place_dbyte_dmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 4*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 7*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac2r_mirrored_ns 11*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1\
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmilp4_ns 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 23*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 27*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_mirrored_ns 34*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_dmilp4_ns 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 46*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 53*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 57*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 57*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_mirrored_ns 57*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_dmilp4_ns 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 69*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 73*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 76*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]  
    
# abutment_d10_master_ns
set floorplans(abutment_d10_master_ns) [concat \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 8*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 10*\${x_dwc_ddrphyse_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 10*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 18*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 20*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 20*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 28*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphymaster_top_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns}-\${y_dwc_ddrphymaster_top_ns}-\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 180 1 \
  [place_dbyte_nodmilp4_ns 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 38*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  ]

# abutment_d10_ac1r_ns
set floorplans(abutment_d10_ac1r_ns) [concat \
  [place_dbyte_nodmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 8*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac1r_ns 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmilp4_ns 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 28*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_ns 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 40*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 40*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 48*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_ns 50*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 68*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]
  
# abutment_d10_ac1r_mirrored_ns
set floorplans(abutment_d10_ac1r_mirrored_ns) [concat \
  [place_dbyte_nodmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 8*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac1r_mirrored_ns 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmilp4_ns 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 20*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 28*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_mirrored_ns 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 40*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 40*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 40*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 48*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 50*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac1r_mirrored_ns 50*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmilp4_ns 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 60*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 68*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]  
  
# abutment_d10_ac2r_ns
set floorplans(abutment_d10_ac2r_ns) [concat \
  [place_dbyte_nodmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 8*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac2r_ns 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmilp4_ns 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_ns 32*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 32*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 32*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 52*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 54*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 54*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_ns 54*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 54*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 54*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 74*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]
  
# abutment_d10_ac2r_mirrored_ns
set floorplans(abutment_d10_ac2r_mirrored_ns) [concat \
  [place_dbyte_nodmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 8*\${x_dwc_ddrphyse_top_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_ac2r_mirrored_ns 10*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmilp4_ns 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 22*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 30*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_mirrored_ns 32*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_dbyte_nodmilp4_ns 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 44*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 52*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 54*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 54*\${x_dwc_ddrphyse_top_ns}+3*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  [place_ac2r_mirrored_ns 54*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  [place_dbyte_nodmilp4_ns 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 66*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1x1_ns} 0 74*\${x_dwc_ddrphyse_top_ns}+4*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  ]
  
# abutment_ac1r_master_ew
set floorplans(abutment_ac1r_master_ew) [concat \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  [place_ac1r_ew 0 \${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 2*\${y_dwc_ddrphymaster_top_ew}+10*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 2*\${y_dwc_ddrphymaster_top_ew}+10*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+10*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+10*\${y_dwc_ddrphyse_top_ew} 0 1 \
  [place_ac1r_mirrored_ew 0 2*\${y_dwc_ddrphymaster_top_ew}+10*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 2*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 2*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_ac1r_ew 0 3*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 3*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 3*\${y_dwc_ddrphymaster_top_ew}+20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphymaster_top_ew}+30*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 3*\${y_dwc_ddrphymaster_top_ew}+30*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 3*\${y_dwc_ddrphymaster_top_ew}+30*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 3*\${y_dwc_ddrphymaster_top_ew}+30*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 4*\${y_dwc_ddrphymaster_top_ew}+30*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 4*\${y_dwc_ddrphymaster_top_ew}+40*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 4*\${y_dwc_ddrphymaster_top_ew}+40*\${y_dwc_ddrphyse_top_ew} 0 1 \
  ]
  
# abutment_ac2r_master_ew
set floorplans(abutment_ac2r_master_ew) [concat \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  [place_ac2r_ew 0 \${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 2*\${y_dwc_ddrphymaster_top_ew}+12*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 2*\${y_dwc_ddrphymaster_top_ew}+12*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+12*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+12*\${y_dwc_ddrphyse_top_ew} 0 1 \
  [place_ac2r_mirrored_ew 0 2*\${y_dwc_ddrphymaster_top_ew}+12*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 2*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 2*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 2*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_ac2r_ew 0 3*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 3*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 3*\${y_dwc_ddrphymaster_top_ew}+24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 3*\${y_dwc_ddrphymaster_top_ew}+36*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 3*\${y_dwc_ddrphymaster_top_ew}+36*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 3*\${y_dwc_ddrphymaster_top_ew}+36*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 3*\${y_dwc_ddrphymaster_top_ew}+36*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 4*\${y_dwc_ddrphymaster_top_ew}+36*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 4*\${y_dwc_ddrphymaster_top_ew}+48*\${y_dwc_ddrphyse_top_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 4*\${y_dwc_ddrphymaster_top_ew}+48*\${y_dwc_ddrphyse_top_ew} 0 1 \
  ]

# abutment_d13_master_ew
set floorplans(abutment_d13_master_ew) [concat \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} \${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_dbyte_dmi_ew 0 13*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 13*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 14*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 26*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 26*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 26*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 26*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_dbyte_dmi_ew 0 26*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 26*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 26*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 27*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 39*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 39*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 39*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 39*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  [place_dbyte_dmi_ew 0 39*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 39*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 39*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew} 52*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 52*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  ]

# abutment_d13_ac1r_ew
set floorplans(abutment_d13_ac1r_ew) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} \${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac1r_ew 0 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmi_ew 0 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_ew 0 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmi_ew 0 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 47*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 59*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 59*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_ew 0 59*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 59*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 59*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmi_ew 0 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 70*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]

# abutment_d13_ac1r_mirrored_ew
set floorplans(abutment_d13_ac1r_mirrored_ew) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} \${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac1r_mirrored_ew 0 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 23*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmi_ew 0 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmi_ew 0 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 47*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 59*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 59*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 59*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmi_ew 0 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 70*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]

# abutment_d13_ac2r_ew
set floorplans(abutment_d13_ac2r_ew) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} \${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac2r_ew 0 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmi_ew 0 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 26*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_ew 0 38*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 38*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 38*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 50*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmi_ew 0 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 51*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 63*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 63*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_ew 0 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmi_ew 0 75*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 75*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 75*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 76*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]

# abutment_d13_ac2r_mirrored_ew
set floorplans(abutment_d13_ac2r_mirrored_ew) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} \${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac2r_mirrored_ew 0 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 25*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 25*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmi_ew 0 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 26*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 38*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 50*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 50*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmi_ew 0 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 51*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 63*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 63*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 75*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 75*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmi_ew 0 75*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 75*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 75*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 76*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]

# abutment_d12_master_ew
set floorplans(abutment_d12_master_ew) [concat \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  [place_dbyte_nodmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  [place_dbyte_nodmi_ew 0 12*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 12*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 12*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_dbyte_nodmi_ew 0 24*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 24*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  [place_dbyte_nodmi_ew 0 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew} 48*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 48*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  ]
  
# abutment_d12_ac1r_ew
set floorplans(abutment_d12_ac1r_ew) [concat \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 1 \
  [place_dbyte_nodmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac1r_ew 0 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmi_ew 0 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_ew 0 34*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 34*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 34*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmi_ew 0 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 56*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 56*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_ew 0 56*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 56*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 56*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmi_ew 0 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]

# abutment_d12_ac1r_mirrored_ew
set floorplans(abutment_d12_ac1r_mirrored_ew) [concat \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 1 \
  [place_dbyte_nodmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac1r_mirrored_ew 0 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 22*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmi_ew 0 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 34*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmi_ew 0 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 56*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 56*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 56*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmi_ew 0 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]  

# abutment_d12_ac2r_ew
set floorplans(abutment_d12_ac2r_ew) [concat \
  [place_dbyte_nodmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac2r_ew 0 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmi_ew 0 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_ew 0 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 48*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 48*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmi_ew 0 48*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 48*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 48*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 60*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 60*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_ew 0 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmi_ew 0 72*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 72*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 72*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]

# abutment_d12_ac2r_mirrored_ew
set floorplans(abutment_d12_ac2r_mirrored_ew) [concat \
  [place_dbyte_nodmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac2r_mirrored_ew 0 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 24*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmi_ew 0 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 24*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 36*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 48*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 48*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 48*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 48*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmi_ew 0 48*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 48*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 48*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 60*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 60*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 72*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 72*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmi_ew 0 72*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 72*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 72*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]
  
# abutment_d11_master_ew
set floorplans(abutment_d11_master_ew) [concat \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 4*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 7*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 11*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 11*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 11*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 15*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 18*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 22*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 22*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 22*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 22*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 22*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 26*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 29*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 33*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 33*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 33*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 33*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  [place_dbyte_dmilp4_ew 0 33*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 33*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 33*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 37*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  ]

# abutment_d11_ac1r_ew
set floorplans(abutment_d11_ac1r_ew) [concat \
  [place_dbyte_dmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 4*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 7*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac1r_ew 0 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmilp4_ew 0 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 28*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_ew 0 32*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 32*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 32*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 42*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 42*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 42*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 42*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 42*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 49*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 53*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 53*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_ew 0 53*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 53*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 53*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 67*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 70*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]

# abutment_d11_ac1r_mirrored_ew
set floorplans(abutment_d11_ac1r_mirrored_ew) [concat \
  [place_dbyte_dmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 4*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 7*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac1r_mirrored_ew 0 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 21*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 21*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmilp4_ew 0 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 21*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 25*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 28*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 32*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 42*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 42*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 42*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 42*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 42*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 42*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 42*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 49*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 53*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 53*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 53*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmilp4_ew 0 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 63*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 67*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 70*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]
  
# abutment_d11_ac2r_ew
set floorplans(abutment_d11_ac2r_ew) [concat \
  [place_dbyte_dmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 4*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 7*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac2r_ew 0 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmilp4_ew 0 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 27*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_ew 0 34*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 34*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 34*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 53*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 57*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 57*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_ew 0 57*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 57*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 57*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 73*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 76*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]
  
# abutment_d11_ac2r_mirrored_ew
set floorplans(abutment_d11_ac2r_mirrored_ew) [concat \
  [place_dbyte_dmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 4*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 7*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac2r_mirrored_ew 0 11*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 23*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmilp4_ew 0 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 23*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 27*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 34*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_dmilp4_ew 0 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 46*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 53*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 57*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 57*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 57*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_dmilp4_ew 0 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 69*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 73*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 76*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]
  
# abutment_d10_master_ew
set floorplans(abutment_d10_master_ew) [concat \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 8*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 10*\${y_dwc_ddrphyse_top_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 10*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 10*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 18*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 20*\${y_dwc_ddrphyse_top_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 20*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 20*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 20*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 28*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 1 \
  [place_dbyte_nodmilp4_ew 0 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 38*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphymaster_top_ew} 0 0 \
  ]
  
# abutment_d10_ac1r_ew
set floorplans(abutment_d10_ac1r_ew) [concat \
  [place_dbyte_nodmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 8*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac1r_ew 0 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmilp4_ew 0 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 28*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_ew 0 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 40*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 40*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 40*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 48*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_ew 0 50*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 50*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 68*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]
  
# abutment_d10_ac1r_mirrored_ew
set floorplans(abutment_d10_ac1r_mirrored_ew) [concat \
  [place_dbyte_nodmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 8*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac1r_mirrored_ew 0 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 20*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 20*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmilp4_ew 0 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 20*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 28*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 40*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 40*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 40*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 40*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 48*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 50*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac1r_mirrored_ew 0 50*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmilp4_ew 0 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 60*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 68*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]
  
# abutment_d10_ac2r_ew
set floorplans(abutment_d10_ac2r_ew) [concat \
  [place_dbyte_nodmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 8*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac2r_ew 0 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmilp4_ew 0 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_ew 0 32*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 32*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 32*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 52*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 54*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 54*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_ew 0 54*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 54*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 54*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 74*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]

# abutment_d10_ac2r_mirrored_ew
set floorplans(abutment_d10_ac2r_mirrored_ew) [concat \
  [place_dbyte_nodmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 8*\${y_dwc_ddrphyse_top_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_ac2r_mirrored_ew 0 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 22*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmilp4_ew 0 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 22*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 30*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 32*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_dbyte_nodmilp4_ew 0 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 44*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 52*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 54*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 54*\${y_dwc_ddrphyse_top_ew}+3*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  [place_ac2r_mirrored_ew 0 54*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  [place_dbyte_nodmilp4_ew 0 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew}] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 66*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1x1_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew}-\${x_dwc_ddrphy_decapvdd_4x1_ew} 74*\${y_dwc_ddrphyse_top_ew}+4*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  ]
  
# boundary_master_decap_ns
set floorplans(boundary_master_decap_ns) [list \
  dwc_ddrphymaster_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 0 -\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 -\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}-\${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}-\${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  ]

# boundary_master_flipped_decap_ns
set floorplans(boundary_master_flipped_decap_ns) [list \
  dwc_ddrphymaster_top_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} 0 180 1 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} -\${y_dwc_ddrphy_vaaclamp_master_ns} 180 1 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns} 180 1 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 180 1 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 -\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}-\${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}-\${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  ]
  
# boundary_ac1r_decap_ns
set floorplans(boundary_ac1r_decap_ns) [concat \
  [place_ac1r_ns 0 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+2*\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  ]

# boundary_ac1r_mirrored_decap_ns
set floorplans(boundary_ac1r_mirrored_decap_ns) [concat \
  [place_ac1r_mirrored_ns 0 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+2*\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 0 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  ]

# boundary_ac2r_decap_ns
set floorplans(boundary_ac2r_decap_ns) [concat \
  [place_ac2r_ns 0 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  ]

# boundary_ac2r_mirrored_decap_ns
set floorplans(boundary_ac2r_mirrored_decap_ns) [concat \
  [place_ac2r_mirrored_ns 0 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphyse_top_ns} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 0 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 180 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 180 1 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns}+\${x_dwc_ddrphy_rpt2ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 180 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns}+\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 180 1 \
  ]

# boundary_master_decap_ew
set floorplans(boundary_master_decap_ew) [list \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 0 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 0 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphy_decapvddq_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphy_decapvddq_4x1_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} -\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} -\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} -\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} -\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  ]

# boundary_master_flipped_decap_ew
set floorplans(boundary_master_flipped_decap_ew) [list \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphy_decapvddq_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphy_decapvddq_4x1_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} -\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} -\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} -\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} -\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  ]
  
# boundary_ac1r_decap_ew
set floorplans(boundary_ac1r_decap_ew) [concat \
  [place_ac1r_ew 0 0] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0  -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew}+\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0  -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_4x1_ew}+\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1x1_ew} -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew}+2*\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} -\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} -\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} -\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} -\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew} 0 0 \
  ]

# boundary_ac1r_mirrored_decap_ew
set floorplans(boundary_ac1r_mirrored_decap_ew) [concat \
  [place_ac1r_mirrored_ew 0 0] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew} 0 1 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew} 0 1 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0  -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew}+\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0  -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_4x1_ew}+\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1x1_ew} -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew}+2*\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  ]

# boundary_ac2r_decap_ew
set floorplans(boundary_ac2r_decap_ew) [concat \
  [place_ac2r_ew 0 0] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} -\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} -\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} -\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} -\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  ]

# boundary_ac2r_mirrored_decap_ew
set floorplans(boundary_ac2r_mirrored_decap_ew) [concat \
  [place_ac2r_mirrored_ew 0 0] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 1 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 1 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 0 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 1 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew}+\${y_dwc_ddrphy_rpt2ch_ew} 0 1 \
  ]

# boundary_master_decap_stdcell_ns
set floorplans(boundary_master_decap_stdcell_ns) [list \
  dwc_ddrphymaster_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 0 -\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_decap_master_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+3*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+4*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+3*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddq_4x1_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+4*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}-\${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddq_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+3*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+4*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}-\${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ns} 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddq_1by4x1_ns} 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+2*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ns} 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+3*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 \${x_dwc_ddrphymaster_top_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}+4*\${y_dwc_ddrphy_decap_master_ns} 0 0 \
  ]

# boundary_master_decap_stdcell_ew
set floorplans(boundary_master_decap_stdcell_ew) [list \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 0 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 0 0 0 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-4*\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-5*\${x_dwc_ddrphy_decap_master_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphy_decapvddq_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphy_decapvddq_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-4*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphy_decapvddq_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew}-5*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphy_decapvddq_4x1_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddq_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-4*\${x_dwc_ddrphy_decap_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-5*\${x_dwc_ddrphy_decap_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-2*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddq_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-3*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-4*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_master_ew}-5*\${x_dwc_ddrphy_decap_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
  ]

# boundary_ac1r_decap_stdcell_ns
set floorplans(boundary_ac1r_decap_stdcell_ns) [concat \
  [place_ac1r_ns 0 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 2 1 \${x_dwc_ddrphy_decapvddqhd_1x1_ns} 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+2*\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvddhd_4x1_ns} 0 2*\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns}+\${x_dwc_ddrphy_decapvddqhd_1x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 0 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  dwc_ddrphy_decapvddq_1by4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ns} 0 \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  dwc_ddrphy_endcell_ns 1 1 0 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 1 0 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ns 1 1 0 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ns} -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} 0 180 1 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 180 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1by4x1_ns} \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ns} \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac1r_ns} 180 1 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1by4x1_ns} \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ns} \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac1r_ns} 0 0 \
  ]
  
# boundary_ac1r_decap_stdcell_ew
set floorplans(boundary_ac1r_decap_stdcell_ew) [concat \
  [place_ac1r_ew 0 0] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1x1_ew} -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0  -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew}+2*\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew}+\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_4x1_ew}+\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-4*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-4*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_4x1_ew} -\${x_dwc_ddrphy_clamp_ac1r_ew}-4*\${x_dwc_ddrphy_decap_ac1r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-5*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-5*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-5*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew}+\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-5*\${x_dwc_ddrphy_decap_ac1r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_4x1_ew}+\${y_dwc_ddrphy_decapvddqhd_1x1_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 1 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ew} 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-5*\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 1 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-2*\${x_dwc_ddrphy_decap_ac1r_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ew} 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-5*\${x_dwc_ddrphy_decap_ac1r_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 1 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 1 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 2 1 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ew} 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 1 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ew} 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-5*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 1 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 2 1 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ew} 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-3*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ew} 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-5*\${x_dwc_ddrphy_decap_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  ]

# boundary_ac2r_decap_stdcell_ns
set floorplans(boundary_ac2r_decap_stdcell_ns) [concat \
  [place_ac2r_ns 0 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvddhd_4x1_ns} 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphy_decapvddqhd_4x1_ns} \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 -\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddq_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_rpt2ch_ns} \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns}+\${x_dwc_ddrphy_rpt1ch_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns}+\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddq_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns}+2*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns}+3*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_ac2r_ns} \${y_dwc_ddrphy_rpt2ch_ns}+4*\${y_dwc_ddrphy_decap_ac2r_ns} 0 0 \
  ]

# boundary_ac2r_decap_stdcell_ew
set floorplans(boundary_ac2r_decap_stdcell_ew) [concat \
  [place_ac2r_ew 0 0 ] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} 2*\${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-4*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-4*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0  -\${x_dwc_ddrphy_clamp_ac2r_ew}-5*\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-5*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_decapvddqhd_4x1_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} -\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} -2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} -2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} -2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddq_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} -2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-4*\${x_dwc_ddrphy_decap_ac2r_ew} -2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-5*\${x_dwc_ddrphy_decap_ac2r_ew} -2*\${y_dwc_ddrphy_rpt2ch_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew}+\${y_dwc_ddrphy_rpt1ch_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-2*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddq_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-3*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-4*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_ac2r_ew}-5*\${x_dwc_ddrphy_decap_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  ]

# boundary_dbyte_decap_stdcell_ns
set floorplans(boundary_dbyte_decap_stdcell_ns) [concat \
  [place_dbyte_dmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns}+\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns}+2*\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 2 0 \${y_dwc_ddrphy_decapvddqhd_4x1_ns} 0 \${y_dwc_ddrphy_endcell_ns}+\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 2*\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 3*\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+2*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns}+\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+2*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns}+2*\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+2*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ns}+3*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+3*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns}+\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+3*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns}+2*\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+3*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ns 1 1 0 0 0 \${y_dwc_ddrphy_endcell_ns}+4*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns} \${y_dwc_ddrphy_endcell_ns}+4*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns}+\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+4*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 1 1 0 0 \${x_dwc_ddrphy_decapvddhd_1x1_ns}+2*\${x_dwc_ddrphy_decapvdd_4x1_ns} \${y_dwc_ddrphy_endcell_ns}+4*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 2 2 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ns} \${y_dwc_ddrphy_decapvddqhd_1by4x1_ns} -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphy_endcell_ns}+\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 2 2 \${x_dwc_ddrphy_decapvddhd_1by4x1_ns} \${y_dwc_ddrphy_decapvddhd_1by4x1_ns} -2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphy_endcell_ns}+3*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 \${x_dwc_ddrphy_clamp_dbyte13_ns} 0 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_dbyte13_ns} \${y_dwc_ddrphy_endcell_ns} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_dbyte13_ns} \${y_dwc_ddrphy_endcell_ns}+\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddq_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_dbyte13_ns} \${y_dwc_ddrphy_endcell_ns}+2*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvddhd_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_dbyte13_ns} \${y_dwc_ddrphy_endcell_ns}+3*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ns 2 1 \${x_dwc_ddrphy_decapvdd_1by4x1_ns} 0 \${x_dwc_ddrphy_clamp_dbyte13_ns} \${y_dwc_ddrphy_endcell_ns}+4*\${y_dwc_ddrphy_decapvddhd_1x1_ns} 0 0 \
  ]
  
# boundary_dbyte_decap_stdcell_ew
set floorplans(boundary_dbyte_decap_stdcell_ew) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew}+\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew}+2*\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 2 1 \${x_dwc_ddrphy_decapvddqhd_4x1_ew} 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-3*\${x_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvddhd_1x1_ew} 2*\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvddhd_1x1_ew} 3*\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-3*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-3*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew}+\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddq_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-3*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew}+2*\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-4*\${x_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-4*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-4*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew}+\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-4*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew}+2*\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-5*\${x_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-5*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew} 0 0 \
  dwc_ddrphy_decapvddhd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-5*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew}+\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-5*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_decapvddhd_1x1_ew}+2*\${y_dwc_ddrphy_decapvdd_4x1_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 2 2 \${x_dwc_ddrphy_decapvddqhd_1by4x1_ew} \${y_dwc_ddrphy_decapvddqhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-3*\${x_dwc_ddrphy_decapvddhd_1x1_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 2 2 \${x_dwc_ddrphy_decapvddhd_1by4x1_ew} \${y_dwc_ddrphy_decapvddhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-5*\${x_dwc_ddrphy_decapvddhd_1x1_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew} \${y_dwc_ddrphy_clamp_dbyte13_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_clamp_dbyte13_ew} 0 0 \
  dwc_ddrphy_decapvddqhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddqhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-2*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_clamp_dbyte13_ew} 0 0 \
  dwc_ddrphy_decapvddq_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddq_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-3*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_clamp_dbyte13_ew} 0 0 \
  dwc_ddrphy_decapvddhd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvddhd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-4*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_clamp_dbyte13_ew} 0 0 \
  dwc_ddrphy_decapvdd_1by4x1_ew 1 2 0 \${y_dwc_ddrphy_decapvdd_1by4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-5*\${x_dwc_ddrphy_decapvddhd_1x1_ew} \${y_dwc_ddrphy_clamp_dbyte13_ew} 0 0 \
  ]

# PERC_11M_dwc_ddrphy_ac1r_cornerclamp
set floorplans(PERC_11M_dwc_ddrphy_ac1r_cornerclamp) [concat \
  [place_ac1r_ew 0 0] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 0 \
  dwc_ddrphy_decap_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} 0 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew}-\${x_dwc_ddrphy_decap_ac1r_ew} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_corner 1 1 0 0 0 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 1 \
  [place_ac1r_mirrored_ns \${x_dwc_ddrphy_clamp_master_corner} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 180 1 \
  dwc_ddrphy_decap_ac1r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+10*\${x_dwc_ddrphyse_top_ns} 10*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}+\${y_dwc_ddrphy_clamp_ac1r_ns} 180 1 \
  ]

# PERC_11M_dwc_ddrphy_ac2r_cornerclamp
set floorplans(PERC_11M_dwc_ddrphy_ac2r_cornerclamp) [concat \
  [place_ac2r_ew 0 0] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 0 0 0 \
  dwc_ddrphy_decap_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} 0 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew}-\${x_dwc_ddrphy_decap_ac2r_ew} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_corner 1 1 0 0 0 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 1 \
  [place_ac2r_mirrored_ns \${x_dwc_ddrphy_clamp_master_corner} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+12*\${x_dwc_ddrphyse_top_ns} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 180 1 \
  dwc_ddrphy_decap_ac2r_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner}+12*\${x_dwc_ddrphyse_top_ns} 12*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}+\${y_dwc_ddrphy_clamp_ac2r_ns} 180 1 \
  ]

# PERC_11M_dwc_ddrphy_dbyte_cornerclamp
set floorplans(PERC_11M_dwc_ddrphy_dbyte_cornerclamp) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_1x1_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_1x1_ew} 0 0 0 \
  dwc_ddrphy_decapvdd_4x1_ew 1 3 0 \${y_dwc_ddrphy_decapvdd_4x1_ew} -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_1x1_ew} \${y_dwc_ddrphy_decapvdd_1x1_ew} 0 0 \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_decap_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew}-\${x_dwc_ddrphy_decapvdd_1x1_ew} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 1 \
  dwc_ddrphy_clamp_master_corner 1 1 0 0 0 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphy_clamp_master_corner} 0 1 \
  [place_dbyte_dmi_ns \${x_dwc_ddrphy_clamp_master_corner} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}-\${y_dwc_ddrphyse_top_ns}] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew} 0 0 \
  dwc_ddrphy_decapvdd_1x1_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_master_corner} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}+\${y_dwc_ddrphy_clamp_dbyte13_ns} 0 0 \
  dwc_ddrphy_decapvdd_4x1_ns 3 1 \${x_dwc_ddrphy_decapvdd_4x1_ns} 0 \${x_dwc_ddrphy_clamp_master_corner}+\${x_dwc_ddrphy_decapvdd_1x1_ns} 13*\${y_dwc_ddrphyse_top_ew}+\${y_dwc_ddrphymaster_top_ew}+\${y_dwc_ddrphy_clamp_dbyte13_ns} 0 0 \
  ]

# PERC_11M_dwc_ddrphy_master_ns
set floorplans(PERC_11M_dwc_ddrphy_master_ns) [list \
  dwc_ddrphymaster_top_ns 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ns 1 1 0 0 0 -\${y_dwc_ddrphy_vaaclamp_master_ns} 0 0 \
  dwc_ddrphy_clamp_master_ns 1 1 0 0 0 \${y_dwc_ddrphymaster_top_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 0 \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}-\${y_dwc_ddrphy_endcell_ns} 180 1 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 \${x_dwc_ddrphymaster_top_ns}+2*\${x_dwc_ddrphy_endcell_ns} \${y_dwc_ddrphymaster_top_ns}+\${y_dwc_ddrphy_clamp_master_ns}-\${y_dwc_ddrphy_endcell_ns} 180 1 \
  ]

# PERC_11M_dwc_ddrphy_master_ew
set floorplans(PERC_11M_dwc_ddrphy_master_ew) [list \
  dwc_ddrphymaster_top_ew 1 1 0 0 0 0 0 0 \
  dwc_ddrphy_vaaclamp_master_ew 1 1 0 0 \${x_dwc_ddrphymaster_top_ew} 0 0 0 \
  dwc_ddrphy_clamp_master_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_master_ew} 0 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_master_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_master_ew} \${y_dwc_ddrphymaster_top_ew} 0 0 \
]

# PERC_11M_dwc_ddrphy_ac1r_ns
set floorplans(PERC_11M_dwc_ddrphy_ac1r_ns) [concat \
  [place_ac1r_ns 0 0] \
  dwc_ddrphy_clamp_ac1r_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 0 0 180 1 \
  dwc_ddrphy_endcell_ns 1 1 0 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac1r_ns}+\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  ]

# PERC_11M_dwc_ddrphy_ac1r_ew
set floorplans(PERC_11M_dwc_ddrphy_ac1r_ew) [concat \
  [place_ac1r_ew 0 0] \
  dwc_ddrphy_clamp_ac1r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} 0 0 1 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac1r_ew} \${y_dwc_ddrphy_clamp_ac1r_ew}+\${y_dwc_ddrphy_endcell_ew} 0 0 \
  ]

# PERC_11M_dwc_ddrphy_ac2r_ns
set floorplans(PERC_11M_dwc_ddrphy_ac2r_ns) [concat \
  [place_ac2r_ns 0 0] \
  dwc_ddrphy_clamp_ac2r_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 0 0 180 1 \
  dwc_ddrphy_endcell_ns 1 1 0 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_ac2r_ns}+\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  ]

# PERC_11M_dwc_ddrphy_ac2r_ew
set floorplans(PERC_11M_dwc_ddrphy_ac2r_ew) [concat \
  [place_ac2r_ew 0 0] \
  dwc_ddrphy_clamp_ac2r_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 0 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} 0 0 1 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_ac2r_ew} \${y_dwc_ddrphy_clamp_ac2r_ew}+\${y_dwc_ddrphy_endcell_ew} 0 0 \
  ]

# PERC_11M_dwc_ddrphy_dbyte_dmi_ns
set floorplans(PERC_11M_dwc_ddrphy_dbyte_dmi_ns) [concat \
  [place_dbyte_dmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte13_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_rpt2ch_ns 1 1 0 0 0 0 180 1 \
  dwc_ddrphy_endcell_ns 1 1 0 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_rpt1ch_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_dbyte13_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 1 1 0 0 \${x_dwc_ddrphy_clamp_dbyte13_ns}+\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  ]

# PERC_11M_dwc_ddrphy_dbyte_dmi_ew
set floorplans(PERC_11M_dwc_ddrphy_dbyte_dmi_ew) [concat \
  [place_dbyte_dmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte13_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 0 \
  dwc_ddrphy_rpt2ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} 0 0 1 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_rpt1ch_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} \${y_dwc_ddrphy_clamp_dbyte13_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte13_ew} \${y_dwc_ddrphy_clamp_dbyte13_ew}+\${y_dwc_ddrphy_endcell_ew} 0 0 \
  ]

# PERC_11M_dwc_ddrphy_dbyte_nodmi_ns
set floorplans(PERC_11M_dwc_ddrphy_dbyte_nodmi_ns) [concat \
  [place_dbyte_nodmi_ns 0 0] \
  dwc_ddrphy_clamp_dbyte12_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 \${x_dwc_ddrphy_clamp_dbyte12_ns} 0 0 0 \
  ]

# PERC_11M_dwc_ddrphy_dbyte_nodmi_ew
set floorplans(PERC_11M_dwc_ddrphy_dbyte_nodmi_ew) [concat \
  [place_dbyte_nodmi_ew 0 0] \
  dwc_ddrphy_clamp_dbyte12_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte12_ew} 0 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte12_ew} \${y_dwc_ddrphy_clamp_dbyte12_ew} 0 0 \
  ]
  
# PERC_11M_dwc_ddrphy_dbyte_dmilp4_ns
set floorplans(PERC_11M_dwc_ddrphy_dbyte_dmilp4_ns) [concat \
  [place_dbyte_dmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte11_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 \${x_dwc_ddrphy_clamp_dbyte11_ns} 0 0 0 \
  ]  
  
# PERC_11M_dwc_ddrphy_dbyte_dmilp4_ew
set floorplans(PERC_11M_dwc_ddrphy_dbyte_dmilp4_ew) [concat \
  [place_dbyte_dmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte11_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte11_ew} 0 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte11_ew} \${y_dwc_ddrphy_clamp_dbyte11_ew} 0 0 \
  ]


# PERC_11M_dwc_ddrphy_dbyte_nodmilp4_ns
set floorplans(PERC_11M_dwc_ddrphy_dbyte_nodmilp4_ns) [concat \
  [place_dbyte_nodmilp4_ns 0 0] \
  dwc_ddrphy_clamp_dbyte10_ns 1 1 0 0 0 \${y_dwc_ddrphyse_top_ns} 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 -2*\${x_dwc_ddrphy_endcell_ns} 0 0 0 \
  dwc_ddrphy_endcell_ns 2 1 \${x_dwc_ddrphy_endcell_ns} 0 \${x_dwc_ddrphy_clamp_dbyte10_ns} 0 0 0 \
  ]

# PERC_11M_dwc_ddrphy_dbyte_nodmilp4_ew
set floorplans(PERC_11M_dwc_ddrphy_dbyte_nodmilp4_ew) [concat \
  [place_dbyte_nodmilp4_ew 0 0] \
  dwc_ddrphy_clamp_dbyte10_ew 1 1 0 0 -\${x_dwc_ddrphy_clamp_dbyte10_ew} 0 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew} -2*\${y_dwc_ddrphy_endcell_ew} 0 0 \
  dwc_ddrphy_endcell_ew 1 2 0 \${y_dwc_ddrphy_endcell_ew} -\${x_dwc_ddrphy_clamp_dbyte10_ew} \${y_dwc_ddrphy_clamp_dbyte10_ew} 0 0 \
  ]

# LPDDR5X testcases

# lpddr5x_abutment_ac_ac_ew
set floorplans(lpddr5x_abutment_ac_ac_ew) [list \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_ac_ck_ew
set floorplans(lpddr5x_abutment_ac_ck_ew) [list \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 4*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 4*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_ac_cmos_ew
set floorplans(lpddr5x_abutment_ac_cmos_ew) [list \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_ac_cs_ew
set floorplans(lpddr5x_abutment_ac_cs_ew) [list \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 0 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_vdd2hclamp_x6_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_x6_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_x6_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_x6_ew} 3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 4*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_x6_ew} 4*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 4*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 5*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 6*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_vdd2hclamp_x6_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_x6_ew} 4*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_x6_ew} 5*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_x6_ew} 6*\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 8*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 8*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_x6_ew} 8*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_ac_pclk_snapcap_ns
set floorplans(lpddr5x_abutment_ac_pclk_snapcap_ns) [list \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 180 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 180 1 \
  dwc_lpddr5xphy_pclk_routing_ac_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_pclk_routing_decapvddq_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_pclk_routing_decapvdd_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_pclk_routing_decapvdd_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew} 180 1 \
  dwc_lpddr5xphy_pclk_routing_decapvddq_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 0 \
  dwc_lpddr5xphy_pclk_routing_decapvddq_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew} 180 1 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 180 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyacx2_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 180 1 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_ac_ew} 0 0 \
  ]

# lpddr5x_abutment_ac_zcal_ew
set floorplans(lpddr5x_abutment_ac_zcal_ew) [list \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  ]

# lpddr5x_abutment_ck_cmos_ew
set floorplans(lpddr5x_abutment_ck_cmos_ew) [list \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 0 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_ck_snapcap_ns
set floorplans(lpddr5x_abutment_ck_snapcap_ns) [list \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyckx2_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyckx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyckx2_top_ew}+2*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 0 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyckx2_top_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyckx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyckx2_top_ew}+2*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_ck_zcal_ew
set floorplans(lpddr5x_abutment_ck_zcal_ew) [list \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  ]

# lpddr5x_abutment_cmos_snapcap_ns
set floorplans(lpddr5x_abutment_cmos_snapcap_ns) [list \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew}+2*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 0 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew}+2*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 0 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 0 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew}  0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew}  0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycmosx2_top_ew}+2*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycmosx2_top_ew}  0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 0 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 7*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_cmos_zcal_ew
set floorplans(lpddr5x_abutment_cmos_zcal_ew) [list \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  ]

# lpddr5x_abutment_cs_ck_ew
set floorplans(lpddr5x_abutment_cs_ck_ew) [list \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 4*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphyckx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_cs_cmos_ew
set floorplans(lpddr5x_abutment_cs_cmos_ew) [list \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_vdd2hclamp_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_ew} 0 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_vdd2hclamp_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_vdd2hclamp_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_ew} 3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_vdd2hclamp_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_vdd2hclamp_ew} 4*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_cs_snapcap_ns
set floorplans(lpddr5x_abutment_cs_snapcap_ns) [list \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew}+2*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 0 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew}+2*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 0 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 0 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew}  0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew}  0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphycsx2_top_ew}+2*\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+2*\${y_dwc_lpddr5xphycsx2_top_ew}  0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 0 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 7*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 0 \
  ]

# lpddr5x_abutment_cs_zcal_ew
set floorplans(lpddr5x_abutment_cs_zcal_ew) [list \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  ]

# lpddr5x_abutment_dx_pclk_snapcap_ns
set floorplans(lpddr5x_abutment_dx_pclk_snapcap_ns) [list \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 5*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 5*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 180 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 180 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 180 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 180 0 \
  dwc_lpddr5xphy_pclk_routing_dx_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_pclk_routing_decapvddq_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_pclk_routing_decapvdd_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_pclk_routing_decapvdd_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 180 1 \
  dwc_lpddr5xphy_pclk_routing_decapvddq_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_pclk_routing_decapvddq_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew} 180 1 \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew} 180 1 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew} 180 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 180 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 180 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 180 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+3*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphydx4_top_ew}+5*\${x_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 180 1 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 5*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 5*\${x_dwc_lpddr5xphy_decapvdd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_x2_cell_ns}+\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_pclk_routing_dx_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  ]

# lpddr5x_abutment_dx4_ac_ew
set floorplans(lpddr5x_abutment_dx4_ac_ew) [list \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx4_ck_ew
set floorplans(lpddr5x_abutment_dx4_ck_ew) [list \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx4_cmos_ew
set floorplans(lpddr5x_abutment_dx4_cmos_ew) [list \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} \${y_dwc_lpddr5xphydx4_top_ew}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx4_cs_ew
set floorplans(lpddr5x_abutment_dx4_cs_ew) [list \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphydx4_top_ew}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx4_zcal_ew
set floorplans(lpddr5x_abutment_dx4_zcal_ew) [list \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx5_ac_ew
set floorplans(lpddr5x_abutment_dx5_ac_ew) [list \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyacx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx5_ck_ew
set floorplans(lpddr5x_abutment_dx5_ck_ew) [list \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyckx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx5_cmos_ew
set floorplans(lpddr5x_abutment_dx5_cmos_ew) [list \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphycmosx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx5_cs_ew
set floorplans(lpddr5x_abutment_dx5_cs_ew) [list \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphycsx2_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx5_dx4_ew
set floorplans(lpddr5x_abutment_dx5_dx4_ew) [list \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 1 \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphydx5_top_ew} 0 1 \
  ]

# lpddr5x_abutment_dx5_zcal_ew
set floorplans(lpddr5x_abutment_dx5_zcal_ew) [list \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} \${y_dwc_lpddr5xphydx5_top_ew}+3*\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 1 \
  ]

# lpddr5x_abutment_pac_ac_ew
set floorplans(lpddr5x_abutment_pac_ac_ew) [list \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} \${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_hd_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} \${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 3*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 4*\${y_dwc_lpddr5xphyacx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphyacx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyacx2_top_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyacx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyacx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  ]

# lpddr5x_abutment_pac_ck_ew
set floorplans(lpddr5x_abutment_pac_ck_ew) [list \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} \${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} \${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 3*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 4*\${y_dwc_lpddr5xphyckx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphyckx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyckx2_top_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyckx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyckx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  ]

# lpddr5x_abutment_pac_cmos_ew
set floorplans(lpddr5x_abutment_pac_cmos_ew) [list \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 0 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} \${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd2h_ld_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} \${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} \${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} \${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} \${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew}  3*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x3_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 4*\${y_dwc_lpddr5xphycmosx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphycmosx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycmosx2_top_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycmosx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 2*\${y_dwc_lpddr5xphycmosx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  ]

# lpddr5x_abutment_pac_cs_ew
set floorplans(lpddr5x_abutment_pac_cs_ew) [list \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 0 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} \${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd2h_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} \${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 2*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} \${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} \${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} \${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} 2*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 2*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 3*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x3_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 4*\${y_dwc_lpddr5xphycsx2_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphycsx2_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphycsx2_top_ew} 2*\${y_dwc_lpddr5xphycsx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphycsx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_ld_x2_ew} 2*\${y_dwc_lpddr5xphycsx2_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  ]

# lpddr5x_abutment_pac_dx4_ew
set floorplans(lpddr5x_abutment_pac_dx4_ew) [list \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphy_decapvdd2h_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_ew} 0 0 \
  dwc_lpddr5xphydx4_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx4_top_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} \${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_x3_ew} 2*\${y_dwc_lpddr5xphydx4_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  ]
  
# lpddr5x_abutment_pac_dx5_ew
set floorplans(lpddr5x_abutment_pac_dx5_ew) [list \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphydx5_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphydx5_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_x2_ew} 0 0 \
  dwc_lpddr5xphydx5_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphydx5_top_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} \${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 2*\${y_dwc_lpddr5xphydx5_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  ]
  
# lpddr5x_abutment_pac_snapcap_ns
set floorplans(lpddr5x_abutment_pac_snapcap_ns) [list \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 0 3*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+\${y_dwc_lpddr5xphymaster_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 0 5*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 0 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphymaster_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+2*\${y_dwc_lpddr5xphymaster_top_ew}+2*\${y_dwc_lpddr5xphy_decapvddq_ld_x2_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 0 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 6*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 7*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns} 7*\${y_dwc_lpddr5xphy_decapvdd2h_x2_cell_ns}+3*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  ]

# lpddr5x_abutment_pac_zcal_ew
set floorplans(lpddr5x_abutment_pac_zcal_ew) [list \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 0 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} \${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x3_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphy_decapvddq_ld_x3_ew} 0 1 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphy_decapvdd_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 1 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} \${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 0 \${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} \${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphymaster_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphymaster_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_x2_ew 1 1 0 0 0 3*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 3*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd2h_ld_x3_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x3_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 4*\${y_dwc_lpddr5xphyzcal_top_ew}+\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 -\${x_dwc_lpddr5xphyzcal_top_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphyzcal_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphy_decapvddq_hd_x2_ew} 2*\${y_dwc_lpddr5xphyzcal_top_ew}+2*\${y_dwc_lpddr5xphymaster_top_ew} 0 0 \
  ]

# lpddr5x_abutment_zcal_snapcap_ns
set floorplans(lpddr5x_abutment_zcal_snapcap_ns) [list \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 \${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} \${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyzcal_top_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyzcal_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 2*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 0 2*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 2*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 0 3*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 3*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphyzcal_top_ew 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyzcal_top_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_ew 1 1 0 0 \${x_dwc_lpddr5xphyzcal_top_ew}+\${x_dwc_lpddr5xphy_decapvddq_x2_ew} 4*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 0 4*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvdd_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 4*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 0 5*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_x2_cell_ns 1 1 0 0 \${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 2*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_hd_x2_cell_ns 1 1 0 0 3*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  dwc_lpddr5xphy_decapvddq_ld_x2_cell_ns 1 1 0 0 4*\${x_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns} 5*\${y_dwc_lpddr5xphy_decapvdd_hd_x2_cell_ns}+2*\${y_dwc_lpddr5xphyzcal_top_ew} 0 0 \
  ]

# LPDDR5xm hard macro testcases

# lpddr5xmphy_abutment1
set floorplans(lpddr5xmphy_abutment1) [list \
  dwc_lpddr5xmphyzcal_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphydx4_top_ew 1 1 0 0 0 \$y_dwc_lpddr5xmphyzcal_top_ew 0 0 \
  dwc_lpddr5xmphydx5_top_ew 1 1 0 0 0 \${y_dwc_lpddr5xmphyzcal_top_ew}+\${y_dwc_lpddr5xmphydx4_top_ew}+\$y_dwc_lpddr5xmphydx5_top_ew 0 1 \
  dwc_lpddr5xmphydx4_top_ew 1 1 0 0 0 \${y_dwc_lpddr5xmphyzcal_top_ew}+\${y_dwc_lpddr5xmphydx4_top_ew}+\$y_dwc_lpddr5xmphydx5_top_ew 0 0 \
  ]

# lpddr5xmphy_abutment2
set floorplans(lpddr5xmphy_abutment2) [list \
  dwc_lpddr5xmphycmosx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphyacx2_top_ew 1 1 0 0 0 \$y_dwc_lpddr5xmphycmosx2_top_ew 0 0 \
  dwc_lpddr5xmphyacx2_top_ew 1 1 0 0 0 \${y_dwc_lpddr5xmphycmosx2_top_ew}+\$y_dwc_lpddr5xmphyacx2_top_ew 0 0 \
  dwc_lpddr5xmphyckx2_top_ew 1 1 0 0 0 \${y_dwc_lpddr5xmphycmosx2_top_ew}+2*\$y_dwc_lpddr5xmphyacx2_top_ew 0 0 \
  dwc_lpddr5xmphyckx2_top_ew 1 1 0 0 0 \${y_dwc_lpddr5xmphycmosx2_top_ew}+2*\${y_dwc_lpddr5xmphyacx2_top_ew}+\$y_dwc_lpddr5xmphyckx2_top_ew 0 0 \
  dwc_lpddr5xmphyacx2_top_ew 1 1 0 0 0 \${y_dwc_lpddr5xmphycmosx2_top_ew}+2*\${y_dwc_lpddr5xmphyacx2_top_ew}+2*\$y_dwc_lpddr5xmphyckx2_top_ew 0 0 \
  ]
  
# lpddr5xmphy_abutment3
set floorplans(lpddr5xmphy_abutment3) [list \
  dwc_lpddr5xmphy_vaaclamp_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphymaster_top_ew 1 1 0 0 \$x_dwc_lpddr5xmphy_vaaclamp_ew 0 0 0 \
  dwc_lpddr5xmphymaster_top_ew 1 1 0 0 0 \$y_dwc_lpddr5xmphymaster_top_ew 180 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 5 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 -\$x_dwc_lpddr5xmphymaster_top_ew \$y_dwc_lpddr5xmphymaster_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 5 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 -\$x_dwc_lpddr5xmphymaster_top_ew -\$y_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \
  ]

# lpddr5xmphy_boundary_acx2_decapvddq_acx2_ew
set floorplans(lpddr5xmphy_boundary_acx2_decapvddq_acx2_ew) [list \
  dwc_lpddr5xmphyacx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_acx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_acx2_ew 0 \$x_dwc_lpddr5xmphyacx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphyacx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_acx2_decapvddq_ld_acx2_ew
set floorplans(lpddr5xmphy_boundary_acx2_decapvddq_ld_acx2_ew) [list \
  dwc_lpddr5xmphyacx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_acx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_acx2_ew 0 \$x_dwc_lpddr5xmphyacx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphyacx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]
# lpddr5xmphy_boundary_acx2_decapvsh_acx2_ew
set floorplans(lpddr5xmphy_boundary_acx2_decapvsh_acx2_ew) [list \
  dwc_lpddr5xmphyacx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_acx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_acx2_ew 0 \$x_dwc_lpddr5xmphyacx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphyacx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_acx2_decapvsh_ld_acx2_ew
set floorplans(lpddr5xmphy_boundary_acx2_decapvsh_ld_acx2_ew) [list \
  dwc_lpddr5xmphyacx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_ld_acx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_ld_acx2_ew 0 \$x_dwc_lpddr5xmphyacx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphyacx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_ckx2_decapvddq_acx2_ew
set floorplans(lpddr5xmphy_boundary_ckx2_decapvddq_acx2_ew) [list \
  dwc_lpddr5xmphyckx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_acx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_acx2_ew 0 \$x_dwc_lpddr5xmphyckx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphyckx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_ckx2_decapvddq_ld_acx2_ew
set floorplans(lpddr5xmphy_boundary_ckx2_decapvddq_ld_acx2_ew) [list \
  dwc_lpddr5xmphyckx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_acx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_acx2_ew 0 \$x_dwc_lpddr5xmphyckx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphyckx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]

# lpddr5xmphy_boundary_ckx2_decapvsh_acx2_ew
set floorplans(lpddr5xmphy_boundary_ckx2_decapvsh_acx2_ew) [list \
  dwc_lpddr5xmphyckx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_acx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_acx2_ew 0 \$x_dwc_lpddr5xmphyckx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphyckx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_ckx2_decapvsh_ld_acx2_ew
set floorplans(lpddr5xmphy_boundary_ckx2_decapvsh_ld_acx2_ew) [list \
  dwc_lpddr5xmphyckx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_ld_acx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_ld_acx2_ew 0 \$x_dwc_lpddr5xmphyckx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphyckx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_cmosx2_decapvdd2h_cmosx2_ew
set floorplans(lpddr5xmphy_boundary_cmosx2_decapvdd2h_cmosx2_ew) [list \
  dwc_lpddr5xmphycmosx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_cmosx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvdd2h_cmosx2_ew 0 \$x_dwc_lpddr5xmphycmosx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \$y_dwc_lpddr5xmphycmosx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \
  ]

# lpddr5xmphy_boundary_cmosx2_decapvdd2h_ld_cmosx2_ew
set floorplans(lpddr5xmphy_boundary_cmosx2_decapvdd2h_ld_cmosx2_ew) [list \
  dwc_lpddr5xmphycmosx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ld_cmosx2_ew 2 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ld_cmosx2_ew 0 \$x_dwc_lpddr5xmphycmosx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ld_ns 0 0 \$y_dwc_lpddr5xmphycmosx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvdd2h_ld_ns 0 0 \
  ]

# lpddr5xmphy_boundary_cmosx2_vdd2hclamp_ew
set floorplans(lpddr5xmphy_boundary_cmosx2_vdd2hclamp_ew) [list \
  dwc_lpddr5xmphycmosx2_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_vdd2hclamp_ew 2 1 \$x_dwc_lpddr5xmphy_vdd2hclamp_ew 0 \$x_dwc_lpddr5xmphycmosx2_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \$y_dwc_lpddr5xmphycmosx2_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \
  ]

# lpddr5xmphy_boundary_dx4_decapvddq_dx4_ew
set floorplans(lpddr5xmphy_boundary_dx4_decapvddq_dx4_ew) [list \
  dwc_lpddr5xmphydx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_dx4_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_dx4_ew 0 \$x_dwc_lpddr5xmphydx4_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphydx4_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_dx4_decapvddq_ld_dx4_ew
set floorplans(lpddr5xmphy_boundary_dx4_decapvddq_ld_dx4_ew) [list \
  dwc_lpddr5xmphydx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_dx4_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_dx4_ew 0 \$x_dwc_lpddr5xmphydx4_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphydx4_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]

# lpddr5xmphy_boundary_dx4_decapvsh_dx4_ew
set floorplans(lpddr5xmphy_boundary_dx4_decapvsh_dx4_ew) [list \
  dwc_lpddr5xmphydx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_dx4_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_dx4_ew 0 \$x_dwc_lpddr5xmphydx4_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphydx4_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_dx4_decapvsh_ld_dx4_ew
set floorplans(lpddr5xmphy_boundary_dx4_decapvsh_ld_dx4_ew) [list \
  dwc_lpddr5xmphydx4_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_ld_dx4_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_ld_dx4_ew 0 \$x_dwc_lpddr5xmphydx4_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphydx4_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_dx5_decapvddq_dx5_ew
set floorplans(lpddr5xmphy_boundary_dx5_decapvddq_dx5_ew) [list \
  dwc_lpddr5xmphydx5_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_dx5_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_dx5_ew 0 \$x_dwc_lpddr5xmphydx5_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphydx5_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_dx5_decapvddq_ld_dx5_ew
set floorplans(lpddr5xmphy_boundary_dx5_decapvddq_ld_dx5_ew) [list \
  dwc_lpddr5xmphydx5_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_dx5_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_dx5_ew 0 \$x_dwc_lpddr5xmphydx5_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphydx5_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]

# lpddr5xmphy_boundary_dx5_decapvsh_dx5_ew
set floorplans(lpddr5xmphy_boundary_dx5_decapvsh_dx5_ew) [list \
  dwc_lpddr5xmphydx5_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_dx5_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_dx5_ew 0 \$x_dwc_lpddr5xmphydx5_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphydx5_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_dx5_decapvsh_ld_dx5_ew
set floorplans(lpddr5xmphy_boundary_dx5_decapvsh_ld_dx5_ew) [list \
  dwc_lpddr5xmphydx5_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_ld_dx5_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_ld_dx5_ew 0 \$x_dwc_lpddr5xmphydx5_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphydx5_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_master_decapvdd2h_ld_master_ew
set floorplans(lpddr5xmphy_boundary_master_decapvdd2h_ld_master_ew) [list \
  dwc_lpddr5xmphymaster_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ld_master_ew 2 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ld_master_ew 0 \$x_dwc_lpddr5xmphymaster_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ld_ns 0 0 \$y_dwc_lpddr5xmphymaster_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ld_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvdd2h_ld_ns 0 0 \
  ]

# lpddr5xmphy_boundary_master_decapvdd2h_master_ew
set floorplans(lpddr5xmphy_boundary_master_decapvdd2h_master_ew) [list \
  dwc_lpddr5xmphymaster_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_master_ew 2 1 \$x_dwc_lpddr5xmphy_decapvdd2h_master_ew 0 \$x_dwc_lpddr5xmphymaster_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \$y_dwc_lpddr5xmphymaster_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \
  ]

# lpddr5xmphy_boundary_master_vaaclamp_ew
set floorplans(lpddr5xmphy_boundary_master_vaaclamp_ew) [list \
  dwc_lpddr5xmphymaster_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_vaaclamp_ew 2 1 \$x_dwc_lpddr5xmphy_vaaclamp_ew 0 \$x_dwc_lpddr5xmphymaster_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \$y_dwc_lpddr5xmphymaster_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvdd2h_ns 3 1 \$x_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvdd2h_ns 0 0 \
  ]

# lpddr5xmphy_boundary_zcal_decapvddq_ld_zcal_ew
set floorplans(lpddr5xmphy_boundary_zcal_decapvddq_ld_zcal_ew) [list \
  dwc_lpddr5xmphyzcal_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_zcal_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_zcal_ew 0 \$x_dwc_lpddr5xmphyzcal_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphyzcal_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_zcal_decapvddq_zcal_ew
set floorplans(lpddr5xmphy_boundary_zcal_decapvddq_zcal_ew) [list \
  dwc_lpddr5xmphyzcal_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_zcal_ew 2 1 \$x_dwc_lpddr5xmphy_decapvddq_zcal_ew 0 \$x_dwc_lpddr5xmphyzcal_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphyzcal_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
  
# lpddr5xmphy_boundary_zcal_decapvsh_ld_zcal_ew
set floorplans(lpddr5xmphy_boundary_zcal_decapvsh_ld_zcal_ew) [list \
  dwc_lpddr5xmphyzcal_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_ld_zcal_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_ld_zcal_ew 0 \$x_dwc_lpddr5xmphyzcal_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \$y_dwc_lpddr5xmphyzcal_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ld_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ld_ns 0 0 \
  ]

# lpddr5xmphy_boundary_zcal_decapvsh_zcal_ew
set floorplans(lpddr5xmphy_boundary_zcal_decapvsh_zcal_ew) [list \
  dwc_lpddr5xmphyzcal_top_ew 1 1 0 0 0 0 0 0 \
  dwc_lpddr5xmphy_decapvsh_zcal_ew 2 1 \$x_dwc_lpddr5xmphy_decapvsh_zcal_ew 0 \$x_dwc_lpddr5xmphyzcal_top_ew 0 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 \$y_dwc_lpddr5xmphyzcal_top_ew 0 0 \
  dwc_lpddr5xmphy_decapvddq_ns 5 1 \$x_dwc_lpddr5xmphy_decapvddq_ns 0 0 -\$y_dwc_lpddr5xmphy_decapvddq_ns 0 0 \
  ]
