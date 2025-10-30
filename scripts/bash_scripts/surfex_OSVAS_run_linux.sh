#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --error=/perm/sp3c/OSVAS/scripts/offline_nompi.1
#SBATCH --mem-per-cpu=10000
#SBATCH --job-name=offnompi
#SBATCH --ntasks=1
#SBATCH --output=/perm/sp3c/OSVAS/scripts/offline_nompi.1
#SBATCH --qos=nf
#SBATCH --time=23:10:00


set -x

###### OSVAS #############################################################
###### (OFFLINE SURFEX VALIDATION SYSTEM) ################################
###### STEPs 0-5: They are done by calling Write_ICOS_forcing.ipynb#######
#Select name of the Station where to run the simulation, and the experiment name to import the namelist there
# Currently select between Majadas_south (ES), Meteopole(FR), Loobos(NL)
export STATION_NAME=Majadas_del_tietar
export OSVAS=/home/pn56/OSVASgh/ #SET PATH TO YOUR OSVAS SETUP

cd $OSVAS

FORCING_NOTEBOOK=${OSVAS}/scripts/notebooks/Write_ICOS_forcing.ipynb
jupyter nbconvert --to notebook --execute --inplace $FORCING_NOTEBOOK

#### STEP 6: Get Validation data ###
##################################################
VALIDATION_NOTEBOOK=${OSVAS}/scripts/notebooks/ICOS_Flux_Downloader.ipynb
jupyter nbconvert --to notebook --execute --inplace $VALIDATION_NOTEBOOK


#exit
#### STEP 6: CONFIGURE AND RUN THE SIMULATIONS ###
##################################################

###################################################################################################
# 6.1 Location of SURFEX setup, make useful links, ################################################
###   select validation station, namelists to import, make run & output paths #####################
###################################################################################################
# Define path of SURFEX code and SURFEX executables, add to $PATH
SURFEX_VER=SURFEX_NWP
#SURFEX_VER=OPEN_SURFEX/open_SURFEX_V8_1
SURFEX_PROFILE=profile_surfex-LXgfortran-SFX-V8-1-1-NOMPI-OMP-O2-X0
export SURFEXPATH=/home/pn56/$SURFEX_VER/src/SURFEX/
export SURFEXEXE=/home/pn56/$SURFEX_VER/src/dir_obj-LXgfortran-SFX-V8-1-1-NOMPI-OMP-O2-X0/MASTER/
#export SURFEXEXE=/home/pn56/$SURFEX_VER/src/dir_obj-LXgfortran-SFX-V8-1-1-MPIAUTO-OMP-O2-X0/MASTER/
export SURFEX_HOME=/home/pn56/$SURFEX_VER                  #SET PATH TO YOUR SURFEX SETUP

# Add these to the $PATH
export PATH=${SURFEXEXE}:$PATH

#Source the profile file:
SURFEXPROFILE=${SURFEX_HOME}/conf/$SURFEX_PROFILE
source $SURFEXPROFILE

# After the export, make sure that the correct executables will be used
echo $PATH
which OFFLINE

#It is assumed that there are working namelists in 
#$OSVAS_HOME/namelists/$STATION_NAME
#And forcings in $OSVAS_HOME/forcings/$STATION_NAME

#Loop through the defined EXPNAMES, make experiment directories,
#make physiography copy the corresponding namelists, run the offline experiment:
for EXPNAME in MEBREFOL; do

mkdir -p $OSVAS/RUNS/$STATION_NAME/$EXPNAME/run/
mkdir -p $OSVAS/RUNS/$STATION_NAME/$EXPNAME/output/

RUNDIR=$OSVAS/RUNS/$STATION_NAME/$EXPNAME/run/
OUTDIR=$OSVAS/RUNS/$STATION_NAME/$EXPNAME/output/

#link forcings in netcdf or txt format in execution folder
ln -s $OSVAS/forcings/$STATION_NAME/FORCING.nc $RUNDIR
#ln -s $OSVAS/forcings/$STATION_NAME/*.txt $RUNDIR
#Copy namelist to execution folder
cp $OSVAS/namelists/$STATION_NAME/OPTIONS.nam_${EXPNAME} $RUNDIR/OPTIONS.nam
#Link physiographic files to execution folder
ln -s ${SURFEX_HOME}/MY_RUN/ECOCLIMAP/* $RUNDIR
ln -s  /home/pn56/Meteopole_BNR/ECOCLIMAP_II_EUROP* $RUNDIR

#Read start_date from the configuration yaml file and update the namelist from the execution folder

#!/bin/bash

yaml_file="$OSVAS/config_files/Stations/${STATION_NAME}.yml"
namelist="$RUNDIR/OPTIONS.nam"

# Extract run_start line (strip comments and spaces)
run_start=$(grep 'run_start:' "$yaml_file" | head -1 | sed -E "s/.*run_start:[[:space:]]*'?([^'\"#]+)'?.*/\1/")

# Check extraction
if [[ -z "$run_start" ]]; then
  echo "Error: could not find run_start in $yaml_file"
  exit 1
fi

# Parse with 'date' to normalize
year=$(date -d "$run_start" +%Y)
month=$(date -d "$run_start" +%-m)
day=$(date -d "$run_start" +%-d)

# normalize and get start epoch
start_epoch=$(date -d "$run_start" +%s)
# add 3600 seconds safely
epoch_plus=$(( start_epoch + 3600 ))
# compute seconds since midnight of that same date
midnight_epoch=$(date -d "$(date -d "$run_start" +%Y-%m-%d) 00:00:00" +%s)
seconds_since_midnight=$(( epoch_plus - midnight_epoch ))
echo "$seconds_since_midnight"


# Update OPTIONS.nam
sed -i "s/NYEAR *= *[0-9]\+,/NYEAR  = ${year},/" "$namelist"
sed -i "s/NMONTH *= *[0-9]\+,/NMONTH = ${month},/" "$namelist"
sed -i "s/NDAY *= *[0-9]\+,/NDAY   = ${day},/" "$namelist"
sed -i "s/XTIME *= *[0-9.]\+/XTIME  = ${seconds_since_midnight}./" "$namelist"

echo "✔ OPTIONS.nam updated from run_start = $run_start"



#Enter the execution folder and run the offline experiment
cd $RUNDIR
sleep 30
PGD 
PREP
OFFLINE

#Move output files to the output folder of the experiment
cp PGD.nc $OUTDIR
cp PREP.nc $OUTDIR
cp SURFOUT*.nc $OUTDIR
cp OPTIONS.nam $OUTDIR
cp *OUT.nc $OUTDIR
cp LISTI* $OUTDIR
cp Param* $OUTDIR

#end loop
done



#### STEP 7: Get Validation data ###
##################################################
VALIDATION_NOTEBOOK=${OSVAS}/scripts/notebooks/ICOS_Flux_Downloader.ipynb
jupyter nbconvert --to notebook --execute --inplace $VALIDATION_NOTEBOOK


