#!/bin/usr/csh -xf

         ###############################################
         # Setup env variables that you can immediately#
         # Clean the data you have to get useful data..#
         # Set next steps..............................#
         # Take action.................................#
         # Make a new script to use data results.......#
         ###############################################



# Get full_path to the encrypt file in IcvRunDRC 
# What is in the env file of certain metal slack 
# what we can find from the name given to add in 
# the Map tech file.


# START HERE

set MSIP_PROJ_ROOT = "/remote/cad-rep/projects" # Root Directory
# set MSIP_PROJ_NAME = "" 
set MSIP_CAD_PROJ_TECH = "$1" # CAD Project
set METAL_SLACK_NAME = "$2" # Metal slack chosen

set METAL_SLACK_ENV_NAME = "env.tcl"
set CAD_PROJ_ENV_NAME = "project.env"

set MSIP_CAD_PROJ_ROOT = `find ${MSIP_PROJ_ROOT} -maxdepth 2 -mindepth 2 -name \*-${TECH_NAME}\[0-9-\]\*`
set MSIP_CAD_REL_ENV_NAME = `ls ${MSIP_PROJ_ROOT}/${MSIP_PROJ_NAME}/${MSIP_CAD_PROJ_NAME}/ -t1 | head -n 1`
set CAD_PROJ_ENV_PATH = "${MSIP_PROJ_ROOT}/${MSIP_PROJ_NAME}/${MSIP_CAD_PROJ_NAME}/${MSIP_CAD_REL_ENV_NAME}/cad/${CAD_PROJ_ENV_NAME}"

# After opening project.env 
# Get first lines and from them get the third element separated by spaces.
set MSIP_CAD_PROJ_NAME = `cat ${CAD_PROJ_ENV_PATH} | head -1 | cut -d' ' -f3` # Get in first line of project.env
set MSIP_CAD_REL_NAME =  `cat ${CAD_PROJ_ENV_PATH} | head -2 | tail -1 | cut -d' ' -f3` # Get in second line of project.env

#Get values separating the MSIP_CAD_PROJ_NAME by dashes (-) 
set MSIP_CAD_PROJ_TECH = `echo ${MSIP_CAD_PROJ_NAME} | cut -d'-' -f2`
set MSIP_CAD_PROJ_V = `echo ${MSIP_CAD_PROJ_NAME} | cut -d'-' -f3 | sed -i "s/.//" | sed -i "s/v//"` # Get a way to clean value

set PCS_PROJ_ROOT = "/remote/cad-rep/proj"
set METAL_SLACK_ROOT = "${PCS_PROJ_ROOT}/${MSIP_CAD_PROJ_NAME}/${MSIP_CAD_REL_NAME}/cad/${METAL_SLACK_NAME}"
set METAL_SLACK_ENV_PATH = "${METAL_SLACK_ROOT}/${METAL_SLACK_ENV_NAME}"

# Open env.tcl METAL_SLACK_ENV_PATH
# Get value of IcvRunDRC without quotes
set ICVRUNDRC_DECK = `find -name ${METAL_SLACK_ENV_PATH} | xargs grep IcvRunDRC | cut -d'"' -f2`

#Get var name
set PROJ_TECH_METAL_SLACK_NAME = "${MSIP_CAD_PROJ_TECH}-${MSIP_CAD_PROJ_V}_${METAL_SLACK_NAME}"


set OUT_LINE = "${PROJ_TECH_METAL_SLACK_NAME}      ${ICVRUNDRC_DECK}"




# END HERE


## Get list of product paths where the tech was found.
# START HERE

set PRODUCTS = `find ${MSIP_PROJ_ROOT} -maxdepth 2 -mindepth 2 -name \*-${TECH_NAME}\[0-9-\]\*`

echo ${PRODUCTS}

# END HERE


##  
# START HERE



# END HERE



##  
# START HERE




# END HERE



