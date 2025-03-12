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
HPCPERM=/ec/res4/hpcperm/sp3c
SURFEX_HOME=$HPCPERM/SURFEX_NWP_MPI                  #SET PATH TO YOUR SURFEX SETUP
OSVAS_HOME=$HOME/OSVAS                            #SET PATH TO YOUR OSVAS SETUP


#SET PATH TO YOUR PHYSIOGRAPHY FILES
HM_CLDATA=/ec/res4/hpcperm/hlam/data/climate
E923_DATA_PATH=$HM_CLDATA/E923_DATA
PGD_DATA_PATH=$HM_CLDATA/PGD
ECOSG_DATA_PATH=$HM_CLDATA/ECOCLIMAP-SG
GMTED2010_DATA_PATH=$HM_CLDATA/GMTED2010
SOILGRID_DATA_PATH=$HM_CLDATA/SOILGRID
ECOSG_COVERS=$ECOSG_DATA_PATH/COVER


# Define path of SURFEX code and SURFEX executables, add to $PATH
SURFEXPATH=${SURFEX_HOME}/src/SURFEX/
SURFEXEXE=${SURFEX_HOME}/dir_obj-atos-gnu-SFX-V8-1-1-MPIAUTO-OMP-O2-X0/MASTER/

# Add these to the $PATH
export PATH=${SURFEXEXE}:$PATH

SURFEXPROFILE=${SURFEX_HOME}/conf/profile_surfex-atos-gnu-SFX-V8-1-1-MPIAUTO-OMP-O2-X0
#source the profile file:
source $SURFEXPROFILE


# After the export, make sure that the correct executables will be used
which OFFLINE

#Select name of the Station where to run the simulation, and the experiment name to import the namelist there
STATION='Majadas_south'   # Currently select between Majadas_south (ES), Meteopole(FR), Loobos(NL)

#It is assumed that there are working namelists in 
#$OSVAS_HOME/namelists/$STATION
#And forcings in $OSVAS_HOME/forcings/$STATION
#Loop through the defined EXPNAMES, make experiment directories,
#copy the corresponding namelists, run the offline experiment:
for EXPNAME in 3pDIFMEB_NWPlike; do

mkdir -p $OSVAS_HOME/RUNS/$STATION/$EXPNAME/run/
mkdir -p $OSVAS_HOME/RUNS/$STATION/$EXPNAME/output/

RUNDIR=$OSVAS_HOME/RUNS/$STATION/$EXPNAME/run/
OUTDIR=$OSVAS_HOME/RUNS/$STATION/$EXPNAME/output/

#link forcings in netcdf or txt format in execution folder
ln -s $OSVAS_HOME/forcings/$STATION/FORCING.nc $RUNDIR
ln -s $OSVAS_HOME/forcings/$STATION/*.txt $RUNDIR
#Copy namelist to execution folder
cp $OSVAS_HOME/namelists/$STATION/OPTIONS.nam_${EXPNAME} $RUNDIR/OPTIONS.nam
#Link physiographic files to execution folder
ln -s $PHYSIO_HOME/* $RUNDIR
ln -s $HM_CLDATA/* $RUNDIR
ln -s $E923_DATA_PATH/* $RUNDIR
ln -s $PGD_DATA_PATH/* $RUNDIR
ln -s $ECOSG_DATA_PATH/* $RUNDIR
ln -s $GMTED2010_DATA_PATH/* $RUNDIR
ln -s $SOILGRID_DATA_PATH/* $RUNDIR
ln -s $ECOSG_DATA_PATH/LAI_SAT/* $RUNDIR
ln -s $ECOSG_DATA_PATH/ALB_SAT/* $RUNDIR
ln -s $ECOSG_DATA_PATH/COVER/* $RUNDIR
ln -s $ECOSG_DATA_PATH/HT/* $RUNDIR
ln -s /ec/res4/scratch/sp3c/hm_home/dev_CY46h1_difmeb_py/climate/IBERIAxl_2.5/gmted2010* $RUNDIR
ln -s /ec/res4/scratch/sp3c/hm_home/dev_CY46h1_difmeb_py/climate/IBERIAxl_2.5/*SOILGRID* $RUNDIR



#Enter the execution folder and run the offline experiment
cd $RUNDIR

#PGD 
#PREP
OFFLINE

#Move output files to the output folder of the experiment
cp PGD.nc $OUTDIR
cp PREP.nc $OUTDIR
cp *OUT.nc $OUTDIR
cp OPTIONS.nam $OUTDIR
cp LISTI* $OUTDIR
cp Param* $OUTDIR

#end loop
done
