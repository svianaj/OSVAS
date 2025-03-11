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

SURFEX_HOME=$HOME/SURFEX_NWP_MPI                  #SET PATH TO YOUR SURFEX SETUP
OSVAS_HOME=$HOME/OSVAS                            #SET PATH TO YOUR OSVAS SETUP
PHYSIO_HOME=$HOME/SURFEX_NWP_RSL/MY_RUN/ECOCLIMAP #SET PATH TO YOUR PHYSIOGRAPHY FILES

# Define path of SURFEX code and SURFEX executables, add to $PATH
SURFEXPATH=${SURFEX_HOME}/src/SURFEX/
SURFEXEXE=${SURFEX_HOME}/src/dir_obj-LXgfortran-SFX-V8-1-1-NOMPI-OMP-O2-X0/MASTER/
# Add these to the $PATH
export PATH=/home/pn56/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/pn56/pysurfex-master/bin/:${SURFEXEXE}

# After the export, make sure that the correct executables will be used
which OFFLINE
wait 4

#Select name of the Station where to run the simulation, and the experiment name to import the namelist there
STATION='Majadas_south'   # Currently select between Majadas_south (ES), Meteopole(FR), Loobos(NL)

#It is assumed that there are working namelists in 
#$OSVAS_HOME/namelists/$STATION
#And forcings in $OSVAS_HOME/forcings/$STATION
#Loop through the defined EXPNAMES, make experiment directories,
#copy the corresponding namelists, run the offline experiment:
for EXPNAME in DIFMEB_3P_LOCAL_PHYSIO DIFMEB_3P_ECOSG_PHYSIO; do

mkdir -p $OSVAS_HOME/RUNS/$STATION/$EXPNAME/run/
mkdir -p $OSVAS_HOME/RUNS/$STATION/$EXPNAME/output/

#link forcings in execution folder
ln -s $OSVAS_HOME/forcing/$STATION/* $OSVAS_HOME/RUNS/$STATION/$EXPNAME/run/
#Copy namelist to execution folder
cp $OSVAS_HOME/namelists/$STATION/OPTIONS.nam_${EXPNAME} $OSVAS_HOME/RUNS/$STATION/$EXPNAME/run/OPTIONS.nam
#Link physiographic files to execution folder
ln -s $PHYSIO_HOME/* $OSVAS_HOME/RUNS/$STATION/$EXPNAME/run/

#Enter the execution folder and run the offline experiment
cd $OSVAS_HOME/RUNS/$STATION/$EXPNAME/run/

PGD
PREP
OFFLINE

#Move output files to the output folder of the experiment
cp *OUT.nc $OSVAS_HOME/$STATION/$EXPNAME/output/
cp OPTIONS.nam $OSVAS_HOME/$STATION/$EXPNAME/output/
cp LISTI* $OSVAS_HOME/$STATION/$EXPNAME/output/
cp Param* $OSVAS_HOME/$STATION/$EXPNAME/output/

#end loop
done
