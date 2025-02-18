#!/bin/bash
###### OSVAS #####################################
###### (OFFLINE SURFEX VALIDATION SYSTEM) ########
#### STEP 6: CONFIGURE AND RUN THE SIMULATIONS ###
##################################################

set -x

###################################################################################################
# 6.1 Location of SURFEX setup, make useful links, ################################################
###   select validation station, namelists to import, make run & output paths #####################
###################################################################################################

SURFEX_HOME=$HOME/SURFEX_NWP_RSL                  #SET PATH TO YOUR SURFEX SETUP
OSVAS_HOME=$HOME/OSVAS                            #SET PATH TO YOUR OSVAS SETUP
PHYSIO_HOME=$HOME/SURFEX_NWP_RSL/MY_R UN/ECOCLIMAP #SET PATH TO YOUR PHYSIOGRAPHY FILES

# Define path of SURFEX code and SURFEX executables, add to $PATH
SURFEXPATH=${SURFEX_HOME}/src/SURFEX/
SURFEXEXE=${SURFEX_HOME}/src/dir_obj-LXgfortran-SFX-V8-1-1-NOMPI-OMP-O2-X0/MASTER/
# Add these to the $PATH
export PATH=/home/pn56/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/pn56/pysurfex-master/bin/:${SURFEXEXE}

# After the export, make sure that the correct executables will be used
which OFFLINE
wait 4

#Select name of the Station where to run the simulation, and the experiment name to import the namelist there
STATION='Fyodorovskoye'   # Currently select between Majadas_south and Fyodorovskoye
EXPNAME='DIFMEB_3P_LOCAL_PHYSIO'  #This is the end part of the name of the namelists file to import
cd $OSVAS_HOME/$STATION

mkdir $OSVAS_HOME/$STATION/$EXPNAME
mkdir $OSVAS_HOME/$STATION/$EXPNAME/run
mkdir $OSVAS_HOME/$STATION/$EXPNAME/output

cp $OSVAS_HOME/Fyodorovskoye_test_run/forcing_run/* $SURFEX_HOME/$EXPNAME/run/
cp $OSVAS_HOME/Fyodorovskoye_test_run/namelists/OPTIONS.nam_${EXPNAME} $SURFEX_HOME/$EXPNAME/run/OPTIONS.nam
ln -s $PHYSIO_HOME/* $OSVAS_HOME/$EXPNAME/run/

PGD
PREP
OFFLINE
#exit
cp *OUT.nc ./$EXPNAME/run/
cp OPTIONS.nam ./$EXPNAME/run/
cp LISTI* ./$EXPNAME/run/
cp Param* ./$EXPNAME/run/




done
