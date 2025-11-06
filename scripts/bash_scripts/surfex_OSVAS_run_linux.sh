#!/bin/bash

set -x

###### OSVAS ######################################################################################
###### (OFFLINE SURFEX VALIDATION SYSTEM) #########################################################
###### STEP 1: Downloading forcing data from ICOS stations ########################################
###### This is done by calling Write_ICOS_forcing.ipynb    ########################################
###################################################################################################
# Select name of the Station where to run the simulation, and the experiment name to import the
# namelist. Currently select between Majadas_del_tietar (ES), Meteopole(FR), Loobos(NL)
# Make sure you have a recent token for the ICOS API stored in $OSVAS/icos_cookie.txt
export STATION_NAME=Majadas_del_tietar
export OSVAS=/home/pn56/OSVASgh/ #SET PATH TO YOUR OSVAS SETUP
cd $OSVAS
FORCING_NOTEBOOK=${OSVAS}/scripts/notebooks/Write_ICOS_forcing.ipynb
# Run the notebook from this bash script using nbconvert 
# The script reads the yaml config in ${OSVAS}/config_files/Stations/{STATION_NAME.yml}
#jupyter nbconvert --to notebook --execute --inplace $FORCING_NOTEBOOK #--stdout


#### STEP 2: Get Validation data from ICOS stations ################################################
###### This is done by calling ICOS_Flux_Downloader.ipynb ##########################################
####################################################################################################
VALIDATION_NOTEBOOK=${OSVAS}/scripts/notebooks/ICOS_Flux_Downloader.ipynb
# Run the notebook from this bash script using nbconvert 
# The script reads the yaml config in ${OSVAS}/config_files/Stations/{STATION_NAME.yml}
#jupyter nbconvert --to notebook --execute --inplace $VALIDATION_NOTEBOOK #--stdout



#### STEP 3: CONFIGURE AND RUN THE SIMULATIONS #####################################################
####################################################################################################

#####################################################################################################
# 3.1 Location of SURFEX setup, make useful links, ##################################################
###   select validation station, experiments/namelists to import, make run & output paths ###########
#####################################################################################################
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

#Source the SURFEX profile file:
SURFEXPROFILE=${SURFEX_HOME}/conf/$SURFEX_PROFILE
source $SURFEXPROFILE

# After the export, make sure that the correct executables will be used
echo $PATH
which OFFLINE

#It is assumed that there are working namelists for a number of EXPs in 
#$OSVAS/namelists/$STATION_NAME/OPTIONS.nam_${EXP}
#And forcings should have been created in $OSVAS_HOME/forcings/$STATION_NAME/ by step 1.

#Loop through the defined EXPNAMES, make experiment directories,
#make physiography copy the corresponding namelists, run the offline experiment:
for EXPNAME in MEBREFOL; do
	mkdir -p $OSVAS/RUNS/$STATION_NAME/$EXPNAME/run/
	mkdir -p $OSVAS/RUNS/$STATION_NAME/$EXPNAME/output/

	RUNDIR=$OSVAS/RUNS/$STATION_NAME/$EXPNAME/run/
	OUTDIR=$OSVAS/RUNS/$STATION_NAME/$EXPNAME/output/

	#link forcings in netcdf or txt format in execution folder
	ln -s $OSVAS/forcings/$STATION_NAME/FORCING.nc $RUNDIR
	ln -s $OSVAS/forcings/$STATION_NAME/*.txt $RUNDIR
	#Copy namelist to execution folder
	cp $OSVAS/namelists/$STATION_NAME/OPTIONS.nam_${EXPNAME} $RUNDIR/OPTIONS.nam
	#Link physiographic files to execution folder
	ln -s ${SURFEX_HOME}/MY_RUN/ECOCLIMAP/* $RUNDIR
	ln -s  /home/pn56/Meteopole_BNR/ECOCLIMAP_II_EUROP* $RUNDIR

	#Read start_date from the configuration yaml file and update the namelist from the execution folder

	#!/bin/bash

	yaml_file="$OSVAS/config_files/Stations/${STATION_NAME}.yml"
	namelist="$RUNDIR/OPTIONS.nam"

	# Extract run_start and forcing_format line (strip comments and spaces)
	run_start=$(grep 'run_start:' "$yaml_file" | head -1 | sed -E "s/.*run_start:[[:space:]]*'?([^'\"#]+)'?.*/\1/")
        forcing_format=$(grep 'forcing_format:' "$yaml_file" | head -1 | sed -E "s/.*forcing_format:[[:space:]]*'?([^'\"#]+)'?.*/\1/")
        forcing_format_uppercase=$(echo "$forcing_format" | tr '[:lower:]' '[:upper:]')

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
	# compute seconds since midnight of that same date
	midnight_epoch=$(date -d "$(date -d "$run_start" +%Y-%m-%d) 00:00:00" +%s)
	seconds_since_midnight=$(( start_epoch - midnight_epoch ))
	echo "$seconds_since_midnight"


	# Update OPTIONS.nam with DATES and FORCING_FORMAT
	sed -i "s/NYEAR *= *[0-9]\+,/NYEAR  = ${year},/" "$namelist"
	sed -i "s/NMONTH *= *[0-9]\+,/NMONTH = ${month},/" "$namelist"
	sed -i "s/NDAY *= *[0-9]\+,/NDAY   = ${day},/" "$namelist"
	sed -i "s/XTIME *= *[0-9.]\+/XTIME  = ${seconds_since_midnight}./" "$namelist"
	# Extract forcing_format from YAML (as before)
        sed -i -E "s|^( *CFORCING_FILETYPE *= *').*(' *,)|\1${forcing_format_uppercase} \2|" "$namelist"

	echo "✔ OPTIONS.nam updated from run_start = $run_start"

	#Enter the execution folder and run the offline experiment
	cd $RUNDIR
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

#####################################################################################################
############ STEP 4: For each experiment, extract aselection of variables   #########################
############ defined in param_list.json to FCTABLES* files in sqlite format #########################
#####################################################################################################
	cd $OSVAS/scripts/nc2sqlite/
	python3 nc2sqlite.py  -p param_list.json -s ../../sqlites/station_list_SURFEX.csv -st 4300000005 -o /home/pn56/OSVASgh/sqlites/model_data/$STATION/ -m $EXPNAME /home/pn56/OSVASgh/RUNS/$STATION_NAME/$EXPNAME/output/

#end loop
done
