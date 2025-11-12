#!/bin/bash

set -x

###### OSVAS ######################################################################################
###### (OFFLINE SURFEX VALIDATION SYSTEM) #########################################################
###### STEP 0: Define Station, relevant paths and which steps to run from the yaml file ###########
###################################################################################################
# Select name of the Station where to run the simulation, and the experiment name to import the yaml
# configuration, namelist, etc Currently select between Majadas_del_tietar (ES), Meteopole(FR),
# Loobos(NL). Make sure you have a recent token for the ICOS API stored in $OSVAS/icos_cookie.txt
export STATION_NAME=Majadas_del_tietar
export OSVAS=/home/pn56/OSVASgh/ #SET PATH TO YOUR OSVAS SETUP
export HARP=/home/pn56/operharpverif/  #SET PATH TO HARP SCRIPTS
yaml_file="$OSVAS/config_files/Stations/${STATION_NAME}.yml"

# --- Read execution control from YAML (case-insensitive booleans) ---
Create_forcing=$(yq -r '.OSVAS_steps.Create_forcing // "false"' "$yaml_file" | tr '[:upper:]' '[:lower:]')
Get_validation=$(yq -r '.OSVAS_steps.Get_validation // "false"' "$yaml_file" | tr '[:upper:]' '[:lower:]')
Run_surfex=$(yq -r '.OSVAS_steps.Run_surfex // "false"' "$yaml_file" | tr '[:upper:]' '[:lower:]')
Extract_model_sqlites=$(yq -r '.OSVAS_steps.Extract_model_sqlites // "false"' "$yaml_file" | tr '[:upper:]' '[:lower:]')
Run_HARP=$(yq -r '.OSVAS_steps.Run_HARP // "false"' "$yaml_file" | tr '[:upper:]' '[:lower:]')
EXPNAMES=$(yq -r '.OSVAS_steps.Expnames[]?' "$yaml_file" | xargs)


###### STEP 1: Downloading forcing data from ICOS stations ########################################
###### This is done by calling Write_ICOS_forcing.ipynb    ########################################
###################################################################################################

cd $OSVAS
FORCING_NOTEBOOK=${OSVAS}/scripts/notebooks/Write_ICOS_forcing.ipynb
# Run the notebook from this bash script using nbconvert 
# The script reads the yaml config in ${OSVAS}/config_files/Stations/{STATION_NAME.yml}
if [[ "$Create_forcing" == true ]]; then
    echo "▶ Running Step 1: Create forcing data"
    jupyter nbconvert --to notebook --execute --inplace "$FORCING_NOTEBOOK"
else
    echo "⏩ Skipping Step 1: Create forcing data"
fi

#### STEP 2: Get Validation data from ICOS stations ################################################
###### This is done by calling ICOS_Flux_Downloader.ipynb ##########################################
####################################################################################################
VALIDATION_NOTEBOOK=${OSVAS}/scripts/notebooks/ICOS_Flux_Downloader.ipynb
# Run the notebook from this bash script using nbconvert 
# The script reads the yaml config in ${OSVAS}/config_files/Stations/{STATION_NAME.yml}
if [[ "$Get_validation" == true ]]; then
    echo "▶ Running Step 2: Get validation data"
    jupyter nbconvert --to notebook --execute --inplace "$VALIDATION_NOTEBOOK"
else
    echo "⏩ Skipping Step 2: Get validation data"
fi



#### STEP 3: CONFIGURE AND RUN THE SIMULATIONS #####################################################
####################################################################################################

#####################################################################################################
# 3.1 Location of SURFEX setup, make useful links, ##################################################
###   select validation station, experiments/namelists to import, make run & output paths ###########
#####################################################################################################
# Define path of SURFEX code and SURFEX executables, add to $PATH
SURFEX_PARENT=$HOME
SURFEX_VER=SURFEX_NWP
#SURFEX_VER=OPEN_SURFEX/open_SURFEX_V8_1
SURFEX_HOME=$SURFEX_PARENT/$SURFEX_VER  #PATH TO THE SURFEX SETUP
SURFEX_PROFILE=profile_surfex-LXgfortran-SFX-V8-1-1-NOMPI-OMP-O2-X0
SURFEXPATH=$SURFEX_HOME/src/SURFEX/   #PATH TO SURFEX CODE
SURFEXEXE=$SURFEX_HOME/src/dir_obj-LXgfortran-SFX-V8-1-1-NOMPI-OMP-O2-X0/MASTER/ #PATH TO THE SURFEX EXECUTABLES
#SURFEXEXE=$SURFEX_HOME/src/dir_obj-LXgfortran-SFX-V8-1-1-MPIAUTO-OMP-O2-X0/MASTER/

#SET PATH TO YOUR PHYSIOGRAPHY FILES
PARAMFILES=${SURFEX_HOME}/MY_RUN/ECOCLIMAP/
DIRFILES=$HOME/PHYSIO/

# Add these to the $PATH
export PATH=${SURFEXEXE}:$PATH

#Source the SURFEX profile file:
SURFEXPROFILE=${SURFEX_HOME}/conf/$SURFEX_PROFILE
source $SURFEXPROFILE

# After the export, make sure that the correct executables will be used
echo $PATH
which OFFLINE

#### It is assumed that there are working OPTIONS.nam namelists for a number of EXPs in 
#### $OSVAS/namelists/$STATION_NAME/OPTIONS.nam_${EXP}
#### And forcings should have been created in $OSVAS_HOME/forcings/$STATION_NAME/ by step 1.

#Loop through the defined EXPNAMES, make experiment directories,
#make physiography copy the corresponding namelists, run the offline experiment:
if [[ "$Run_surfex" == true ]]; then
    echo "▶ Running Step 3: Run SURFEX offline simulations"
    for EXPNAME in $EXPNAMES; do
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
	for p in "$PARAMFILES" "$DIRFILES"; do
	  ln -s "$p"/* "$RUNDIR"
	done

	#Read start_date from the configuration yaml file and update the namelist from the execution folder

	#!/bin/bash

	namelist="$RUNDIR/OPTIONS.nam"

	# Extract key parameters using yq (Go version)
	run_start=$(yq '.Forcing_data.run_start' "$yaml_file" | tr -d "'\"")
	run_end=$(yq '.Forcing_data.run_end' "$yaml_file" | tr -d "'\"")
	forcing_format=$(yq '.Forcing_data.forcing_format' "$yaml_file" | tr -d "'\"")
	forcing_format_uppercase=$(echo "$forcing_format" | tr '[:lower:]' '[:upper:]')

	# Extract boolean common_obstable (default to false if missing)
	common_obstable=$(yq '.Validation_data.common_obstable // "false"' "$yaml_file")

	# Set OBSTABLE_PATH based on common_obstable
	if [[ "$common_obstable" == true || "$common_obstable" == True ]]; then
	    OBSTABLE_PATH="common_obstables"
	else
	    OBSTABLE_PATH="$STATION_NAME"
	fi

	# Check extraction
	if [[ -z "$run_start" ]]; then
	  echo "Error: could not find run_start in $yaml_file"
	  exit 1
	fi

	# Parse with 'date' to normalize
	year_start=$(date -d "$run_start" +%Y)
	month_start=$(date -d "$run_start" +%m)
	day_start=$(date -d "$run_start" +%d)
	
	# Parse with 'date' to normalize
	year_end=$(date -d "$run_end" +%Y)
	month_end=$(date -d "$run_end" +%m)
	day_end=$(date -d "$run_end" +%d)

	# normalize and get start epoch
	start_epoch=$(date -d "$run_start" +%s)
	# compute seconds since midnight of that same date
	midnight_epoch=$(date -d "$(date -d "$run_start" +%Y-%m-%d) 00:00:00" +%s)
	seconds_since_midnight=$(( start_epoch - midnight_epoch ))
	echo "$seconds_since_midnight"


	# Update OPTIONS.nam with DATES and FORCING_FORMAT
	sed -i "s/NYEAR *= *[0-9]\+,/NYEAR  = ${year_start},/" "$namelist"
	sed -i "s/NMONTH *= *[0-9]\+,/NMONTH = ${month_start},/" "$namelist"
	sed -i "s/NDAY *= *[0-9]\+,/NDAY   = ${day_start},/" "$namelist"
	sed -i "s/XTIME *= *[0-9.]\+/XTIME  = ${seconds_since_midnight}./" "$namelist"
	# Extract forcing_format from YAML (as before)
        sed -i -E "s|^( *CFORCING_FILETYPE *= *').*(' *,)|\1${forcing_format_uppercase} \2|" "$namelist"

	echo "✔ OPTIONS.nam updated from run_start = $run_start"
	# Read Surfex steps as a space-separated string
        SURFEX_STEPS=$(yq -r '.OSVAS_steps.Surfex_steps[]?' "$yaml_file" | xargs | tr '[:lower:]' '[:upper:]')
	echo "SURFEX STEPS to run for exp $EXPNAME : $SURFEX_STEPS"
	#Enter the execution folder and run the offline experiment
        cd "$RUNDIR"
        for step in $SURFEX_STEPS; do
            echo "Running $step ..."
            $step || { echo "❌ Error running $step"; exit 1; }
        done
	#Move output files to the output folder of the experiment
	mv PGD.nc $OUTDIR
	mv PREP.nc $OUTDIR
	mv SURFOUT*.nc $OUTDIR
	mv OPTIONS.nam $OUTDIR
	mv *OUT.nc $OUTDIR
	mv LISTI* $OUTDIR
	mv Param* $OUTDIR
    done
else
    echo "⏩ Skipping Step 3: Run SURFEX"
fi


#####################################################################################################
############ STEP 4: For each experiment, extract a selection of variables   ########################
############ defined in param_list.json to FCTABLES* files in sqlite format #########################
#####################################################################################################
if [[ "$Extract_model_sqlites" == true ]]; then
    SID=$(yq -r '.Station_metadata.SID' "$yaml_file")
    for EXPNAME in $EXPNAMES; do
	    echo "▶ Running Step 4: Extract model SQLITEs"
    	    cd $OSVAS/scripts/nc2sqlite/
 	    python3 nc2sqlite.py -p param_list.json -s ../../sqlites/station_list_SURFEX.csv -st $SID \
 	     -o /home/pn56/OSVASgh/sqlites/model_data/$STATION_NAME/ \
 	     -m $EXPNAME /home/pn56/OSVASgh/RUNS/$STATION_NAME/$EXPNAME/output/
    #end loop
    done 	    
else
    echo "⏩ Skipping Step 4: Extract model SQLITEs"
fi

#####################################################################################################
############ STEP 5: Configure a HARP yaml file to be used by oper-harp-verif   #####################
############ to run a HARP point verification for the runs                  #########################
#####################################################################################################
if [[ "$Run_HARP" == true ]]; then
    echo "▶ Running Step 5: HARP verification"
	HARPCONFIG_yml_template=$OSVAS/config_files/HARP/OSVAS_HARP_verif.yml
	HARPCONFIG_yml=$OSVAS/config_files/HARP/OSVAS_HARP_verif_${STATION_NAME}.yml
	cp $HARPCONFIG_yml_template $HARPCONFIG_yml

	# Update with yq
	yq eval -i "
	  .verif.project_name = [\"OSVAS_${STATION_NAME}\"] |
	  .verif.fcst_model = (\"${EXPNAMES}\" | split(\" \")) |
	  .verif.fcst_path = [\"${OSVAS}/sqlites/model_data/\"] |
	  .verif.obs_path = [\"${OSVAS}/sqlites/validation_data/${OBSTABLE_PATH}/\"] |
	  .verif.verif_path = [\"${OSVAS}/RUNS/${STATION_NAME}/HARPVERIF/\"] |
	  .post.plot_output = [\"${OSVAS}/RUNS/${STATION_NAME}/HARPVERIF/\"] 
	" "$HARPCONFIG_yml"
	cd $HARP
	mkdir ${OSVAS}/RUNS/${STATION_NAME}/HARPVERIF/
	Rscript $HARP/verification/point_verif.R -start_date $year_start$month_start$day_start -end_date \
	$year_end$month_end$day_end -config_file  $HARPCONFIG_yml -params_file /home/pn56/OSVASgh/config_files/HARP/set_params.R -params_list=H,LE

else
    echo "⏩ Skipping Step 5: HARP verification"
fi



