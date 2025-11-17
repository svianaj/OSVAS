# OSVAS
## Offline Surfex Validation System

OSVAS is a set of scripts developed within the ACCORD community to provide a systematic approach for testing NWP-like SURFEX settings over specialized Atmospheric & Ecosystem stations from the ICOS project. It also facilitates validation of results using flux data from the same source.

## Installation
### Get the OSVAS code
```
mkdir OSVAS
cd OSVAS
git clone https://github.com/svianaj/OSVAS.git .
``` 
### Conda Environment
  It is advised to install the needed python packages as a conda environment.
  On atos, it is available by loading its module:
```
  module load conda/24.11.3-2
``` 
  If it's not installed in your system, we recommend to use a Miniconda distribution:
```
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh
```
You will be asked if you wish to update your shell profile to automatically initialize conda? The recommendation is "yes". This will modify your profile to have the conda commands available in your terminal on startup. The con is that it automatically activates the "base" environment in every new shell. But this can be easily avoided with this command:
```
    conda config --set auto_activate_base false
```
After intalling or loading conda's module:
```
cd scripts/bash_scripts
./create_conda_environment.sh
```
  - This will create an OSVASENV conda environment and install the dependencies. These include a specific yaml handling library for bash linux (yq, Go version from conda-forge and a number of python packages)
  - For running the verification step, a functional HARP installation must be done & oper-harp-verif scripts downloaded from the repo.
  - Activate the conda environment to start using OSVAS.
```
conda env activate OSVASENV
```
### SURFEX
- A functional **SURFEX installation** is required, and the namelist to run it must of course be compatible with this version: Here are a few suggestions:
    - Opensurfex8.1 https://www.umr-cnrm.fr/surfex/spip.php?article387
    - ACCORD's SURFEX_NWP: https://github.com/ACCORD-NWP/SURFEX-NWP
### ICOS login & token
In order to download ICOS data from their python API, it is necessary to create an account there, login and get an access token which must be stored in $OSVAS/icos_cookie.txt . This cookie must be renewed every 27.8h (10⁵  seconds). Follow instructions in https://cpauth.icos-cp.eu/login/ . After logging in, you'll find your token at the bottom of your user profile info.
## The OSVAS Workfow
### OSVAS's central control script
- Currently, all the steps of the OSVAS system are run from a bash script, with versions available for general linux ( surfex_OSVAS_run_linux.sh ) or for the ATOS HPC (surfex_OSVAS_run_atos.sh). The script reads the file $OSVAS/config_files/Stations/${STATION_NAME}.yml created for every used ICOS station, where one can define what OSVAS steps to run for the station, what ICOS datasets read for forcing and validation, start and end periods for the run and for the validation, what SURFEX steps to run, names of the SURFEX OFFLINE experiments to run, etc.
- This bash script needs to be edited only to specify the name of the ICOS station, locate the OSVAS and HARP paths, and make sure that SURFEX profile and binaries are correctly referenced:
```
export STATION_NAME=Majadas_del_tietar
export OSVAS=$HOME/OSVASgh/ #SET PATH TO YOUR OSVAS SETUP
export HARP=$HOME/operharpverif/  #SET PATH TO HARP SCRIPTS
(....)
# Define path of SURFEX code and SURFEX executables, add to $PATH
SURFEX_PARENT=$HOME
SURFEX_VER=SURFEX_NWP
SURFEX_HOME=$SURFEX_PARENT/$SURFEX_VER  #PATH TO THE SURFEX SETUP
SURFEX_PROFILE=profile_surfex-LXgfortran-SFX-V8-1-1-NOMPI-OMP-O2-X0
SURFEXPATH=$SURFEX_HOME/src/SURFEX/   #PATH TO SURFEX CODE
SURFEXEXE=$SURFEX_HOME/src/dir_obj-LXgfortran-SFX-V8-1-1-NOMPI-OMP-O2-X0/MASTER/ #PATH TO THE SURFEX EXECUTABLES
```
- In order to run PGD, one needs to link into the execution path, the physiographic files referenced in the namelists. For runs in a local linux we assume that the namelists use ecoclimapI or ecoclimapII param files (taken from the SURFEX setup) and the global dir/hdr files :
```
#SET PATH TO YOUR PHYSIOGRAPHY FILES
PARAMFILES=${SURFEX_HOME}/MY_RUN/ECOCLIMAP/
DIRFILES=$HOME/PHYSIO/  # Edit this with the location of e.g. ECOCLIMAP_II_EUROP.{hdr,dir} files
```
For runs on ATOS, there's also the possibility to run more NWP-alike namelists which make use of e.g. ECOCLIMAP-SG files in hlam's user:
```
#SET PATH TO YOUR PHYSIOGRAPHY FILES
HM_CLDATA=/ec/res4/hpcperm/hlam/data/climate
E923_DATA_PATH=$HM_CLDATA/E923_DATA
PGD_DATA_PATH=$HM_CLDATA/PGD
ECOSG_DATA_PATH=$HM_CLDATA/ECOCLIMAP-SG
GMTED2010_DATA_PATH=$HM_CLDATA/GMTED2010
SOILGRID_DATA_PATH=$HM_CLDATA/SOILGRID
ECOSG_COVERS=$ECOSG_DATA_PATH/COVER
#The following 2 physiography sources must come from a harmonie setup:
GMTED_PATH=/ec/res4/scratch/sp3c/hm_home/harmonie46h111/climate/DKCOEXP/
SOILGRIDS_PATH=/ec/res4/scratch/sp3c/hm_home/harmonie46h111/climate/DKCOEXP/
```
### Step 0: Define Station and relevant paths, read which steps to run from the yaml file
- Make sure that you have the yaml file in the correct location (yaml_file="$OSVAS/config_files/Stations/${STATION_NAME}.yml")
- Read the yaml configuration file, find out which OSVAS & SURFEX steps to need to be run, and the names of the experiments assigned to each namelist to test
- Make sure that you have the namelist file in the correct location (yaml_file="$OSVAS/namelists/Stations/{STATION_NAME}/OPTIONS.nam_{EXPNAME}")
```
OSVAS_steps:
 Create_forcing: true
 Get_validation: true
 Run_surfex: True
 Surfex_steps: #Don't forget a space before each item
  - pgd
  - PREP
  - OFFLINE
 Expnames: #Don't forget a space before each EXPNAME
  - MEBREFOL
 Extract_model_sqlites: true
 Run_HARP: true
 Display_HARP: true
```
### Step 1. Preparation of forcing data 
- A Python notebook (`Write_ICOS_forcing.ipynb`) is run from inside the bash script, making use of "jupyter nbconvert --to notebook" utility. It generates SURFEX forcing files in ASCII or NetCDF format for running the offline SURFEX simulations.
- Section Forcing_data in the yml config file is used to specify from what ICOS datasets to extract the forcing, what variables to read, unit transformations, simulation periods, etc:
``` 
Forcing_data:
  height_T: 2                       # Height of the temperature measurement
  height_V: 10                      # Height of the windspeed   measurement
  run_start: '2021-5-01 00:00:00'    # Timestamp for the forcing start
  run_end: '2021-7-1 23:30:00'      # Timestamp for the forcing end
  forcing_format: 'ascii'          # Choose between netcdf or ascii
  dataset1:
    doi: https://meta.icos-cp.eu/objects/fPAqntOb1uiTQ2KI1NS1CHlB
    timedelta: 30  # in minutes
    variables:
      Forc_CO2: -, 0.00062
      Forc_PS: PA, *1000
      Forc_RAIN: P, /(timedelta*60)
      Forc_SNOW:
      Forc_WIND: WS
      Forc_DIR: WD
      Forc_DIR_SW: SW_IN
      Forc_LW: LW_IN
      Forc_QA:
      Forc_SCA_SW:
      Forc_TA: TA, +273.15
      Forc_RH: RH
``` 
- Example config files currently available for stations: **Majadas_del_tietar (ES), Meteopole (FR), and Loobos (NL)** (Fluxnet data format, accessible via ICOS Data Portal).
- Available formats:
  - **ASCII format**: Forcings are generated for the entire simulation period.
  - **NetCDF format**: Daily NetCDF files are created, then a merging function in the notebook is used to join daily files in a single FORCING.nc file
- **Sampling rate**: If several datasets with different sampling rates are provided, the data will be upsampled to a common (smallest) timedelta.
- **Lockfile mechanism**: Prevents overwriting of forcing files unless manually deleted.

### Step 2. Download validation data from ICOS specialized stations.
The jupyter notebook `ICOS_Flux_downloader.ipynb`, also  run from inside the bash script, retrieves the validation data and saves it as OBSTABLE sqlite files, which can be used by HARP, custom-made verification scripts or other validation tools. Info about the ICOS dataset(s) from where to extract the validation variables must be included in the "Validation_data" section of the yaml files. The sampling frequency, how to rename the ICOS variables in the sqlite file and the validation period must also be specified. Stations are identified with a Station ID (SID), making possible to write the validation data to a common obstable for all stations. This is controlled by common_obstable key in the yaml file (see example below)
```
Validation_data:
  validation_start: '2021-5-01 00:00:00'
  validation_end: '2021-7-1 23:30:00'
  common_obstable: FALSE  # Write obs to a common obstable or to a single-station one
  dataset1:
    doi: https://meta.icos-cp.eu/objects/fPAqntOb1uiTQ2KI1NS1CHlB
    timedelta: 30
    variables:
      SW_OUT: SW_OUT
      LW_OUT: LW_OUT
      SW_IN: SW_IN
      LW_IN: LW_IN
      TS_1: TS_1
      TS_2: TS_2
      SWC_1: SWC_1
      SWC_2: SWC_2
    units:  # These should be similar to units attribute in output netcdf files
      SW_OUT: W/m2
      LW_OUT: W/m2
      LW_IN: W/m2
      SW_IN: W/m2
      TS_1: K
      TS_2: K
      SWC_1: m3/m3
      SWC_2: m3/m3
  dataset2:
    doi: https://meta.icos-cp.eu/objects/tONKGY9pOYqVInayCYac-4LI
    timedelta: 30
    variables:
      H: H
      LE: LE
    units:
      H: W/m2
      LE: W/m2
```
- The configuration file above will be treated by `Write_ICOS_forcing.ipynb` to generate forcing files in ascci or netcdf format according to the defined datasets and transformations, and by `ICOS_Flux_downloader.ipynb` to generate a validation dataset from the different ICOS datasets specified in the Validation_data block. 
- **Sampling rate**: If several datasets with different sampling rates are provided, the data will be upsampled to a common (smallest) timedelta.


### 3. Simulation Execution
- `surfex_OSVAS_run.sh`: A bash script to manage simulation runs over the selected station using the generated forcing files, organize model output in different folders, etc. 

### 3. SURFEX Namelists
- A set of SURFEX namelists tailored for each site, testing advanced SURFEX physics configurations:
  - **3 patches, MEB, DIF, 3-layer snow model**.
- Two versions of each namelist:
  1. **Self-contained**: Uses physiographic data derived from station metadata, without external dependencies.
  2. **NWP-like conditions**: Uses the same physiographic datasets as operational NWP runs. This can be achieved by running PGD for every site on ATOS, BELENOS, etc (where all phisiographic files are available) and extracting the PGD values to the namelist, or simply run all simulations (PGD-PREP-OFFLINE) under those HPCs.




### 5. Define the station and experiments (namelists) to test and run the SURFEX OFFLINE steps
This is controlled by 

### 6. Convert SURFEX OFFLINE output data from ncfile to sqlite FCTABLES, for use in HARP.

Similarly to [grib2sqlite](https://github.com/destination-earth-digital-twins/grib2sqlite) utility, a new python tool has been created here to help extract SURFEX output variables from single-point OFFLINE SURFEX RUNS into FCTABLES suitable for use with HarPoint / [oper-harp-verif](https://github.com/harphub/oper-harp-verif) , or with other custom made verification software capable to read observations & simulation data from sqlite files. This tool needs a dictionary of SURFEX variable names to observation variable names (i.e. variable names present in the OBSTABLES files to be used for the validation). In order to use oper-harp-verif, these observation variable names should also be properly defined in file set_params.R from this set of scripts. In the future, nc2sqlite tool could be extended to allow data extraction from 2-D SURFEX offline runs, i.e. through interpolation from the NetCDF grid.

```
usage: nc2sqlite.py [-h] -p PARAM_LIST -s STATION_LIST -st STATION -o OUTPUT -m EXPERIMENT_NAME ncdir

Convert point NetCDF SURFEX output to SQLite.
The script will create a EXPERIMENT_NAME folder in the OUTPUT path,
which will be populated with monthly FCTABLES for every variable
in the PARAM_LIST, stored in YYYY/MM subfolders

positional arguments:
  ncdir                 Directory containing NetCDF files

options:
  -h, --help            show this help message and exit
  -p PARAM_LIST, --param_list PARAM_LIST
                        Path to param_dict.json
  -s STATION_LIST, --station_list STATION_LIST
                        Path to station_list_default.csv
  -st STATION, --station STATION
                        Station ID
  -o OUTPUT PATH, --output OUTPUT PATH
                        Output base directory
  -m EXPERIMENT_NAME, --experiment_name EXPERIMENT_NAME
                        Experiment name
```

## Next Steps
- Additional instructions for **model output validation** will be included soon.


