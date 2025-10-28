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
export OSVAS=$PERM/OSVAS/ #SET PATH TO YOUR OSVAS SETUP

cd $OSVAS

FORCING_NOTEBOOK=${OSVAS}/scripts/notebooks/Write_ICOS_forcing.ipynb
#jupyter nbconvert --to notebook --execute --inplace $FORCING_NOTEBOOK


#exit
#### STEP 6: CONFIGURE AND RUN THE SIMULATIONS ###
##################################################

###################################################################################################
# 6.1 Location of SURFEX setup, make useful links, ################################################
###   select validation station, namelists to import, make run & output paths #####################
###################################################################################################
HPCPERM=/ec/res4/hpcperm/sp3c
SURFEX_HOME=$HPCPERM/SURFEX_NWP_NOMPI                  #SET PATH TO YOUR SURFEX SETUP
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
#SURFEXPATH=${SURFEX_HOME}/src/SURFEX/
SURFEXEXE=${SURFEX_HOME}/src/dir_obj-atos-gnu-SFX-V8-1-1-NOMPI-OMP-O2-X0/MASTER/

# Add these to the $PATH
export PATH=${SURFEXEXE}:$PATH

SURFEXPROFILE=${SURFEX_HOME}/conf/profile_surfex-atos-gnu-SFX-V8-1-1-NOMPI-OMP-O2-X0
#source the profile file:
source $SURFEXPROFILE


# After the export, make sure that the correct executables will be used
echo $PATH
which OFFLINE

#It is assumed that there are working namelists in 
#$OSVAS_HOME/namelists/$STATION_NAME
#And forcings in $OSVAS_HOME/forcings/$STATION_NAME
#Loop through the defined EXPNAMES, make experiment directories,
#copy the corresponding namelists, run the offline experiment:
for EXPNAME in MEBREFOL; do

mkdir -p $OSVAS_HOME/RUNS/$STATION_NAME/$EXPNAME/run/
mkdir -p $OSVAS_HOME/RUNS/$STATION_NAME/$EXPNAME/output/

RUNDIR=$OSVAS_HOME/RUNS/$STATION_NAME/$EXPNAME/run/
OUTDIR=$OSVAS_HOME/RUNS/$STATION_NAME/$EXPNAME/output/

#link forcings in netcdf or txt format in execution folder
ln -s $OSVAS_HOME/forcings/$STATION_NAME/FORCING.nc $RUNDIR
ln -s $OSVAS_HOME/forcings/$STATION_NAME/*.txt $RUNDIR
#Copy namelist to execution folder
cp $OSVAS_HOME/namelists/$STATION_NAME/OPTIONS.nam_${EXPNAME} $RUNDIR/OPTIONS.nam
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
ln -s ${SURFEX_HOME}/MY_RUN/ECOCLIMAP/* $RUNDIR
GMTED_PATH=/ec/res4/scratch/sp3c/hm_home/harmonie46h111/climate/DKCOEXP/
SOILGRIDS_PATH=/ec/res4/scratch/sp3c/hm_home/harmonie46h111/climate/DKCOEXP/
ln -s $GMTED_PATH/gmted2010* $RUNDIR
ln -s $SOILGRIDS_PATH/*SOILGRID* $RUNDIR
ln -s $OSVAS_HOME/phisio/ecoclimapII/* $RUNDIR

#Read start_date from the configuration yaml file and update the namelist from the execution folder

#!/bin/bash

yaml_file="$OSVAS_HOME/config_files/Stations/${STATION_NAME}.yml"
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
hour=$(date -d "$run_start + 3600 seconds" +%-H)

# Update OPTIONS.nam
sed -i "s/NYEAR *= *[0-9]\+,/NYEAR  = ${year},/" "$namelist"
sed -i "s/NMONTH *= *[0-9]\+,/NMONTH = ${month},/" "$namelist"
sed -i "s/NDAY *= *[0-9]\+,/NDAY   = ${day},/" "$namelist"
sed -i "s/XTIME *= *[0-9.]\+/XTIME  = ${hour}./" "$namelist"

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
