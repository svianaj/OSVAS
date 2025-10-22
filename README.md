# OSVAS
## Offline Surfex Validation System

OSVAS is a set of scripts and namelists developed within the ACCORD community to provide a systematic approach for testing NWP-like SURFEX settings over specialized Atmospheric & Ecosystem stations from the ICOS project. It also facilitates validation of results using flux data from the same source.

## Installation
### Python Environment
- The required Python packages are listed in `requirements.txt`.
- Install using:
  ```sh
  pip install -r requirements.txt
  ```

### Running Simulations
- A functional **SURFEX installation** is required.
- Ensure SURFEX is correctly referenced in `surfex_OSVAS_run.sh`.
  
## Features

### 1. Forcing Data Preparation
- A Python notebook (`Write_ICOS_forcing.ipynb`) allows users to:
  - Select different ICOS stations.
  - Generate SURFEX forcing files in ASCII or NetCDF format for simulations.
- Yaml config files by station are used to specify the ICOS datasets to extract the forcing, variables to read, unit transformations, simulation periods, etc.
- Example config files currently available for stations: **Majadas_del_tietar (ES), Meteopole (FR), and Loobos (NL)** (Fluxnet data format, accessible via ICOS Data Portal).
- Available formats:
  - **ASCII format**: Forcings are generated for the entire simulation period.
  - **NetCDF format**: Daily NetCDF files are created, with a merging function available in the notebook to join daily files in a single FORCING.nc file
- **Lockfile mechanism**: Prevents overwriting of forcing files unless manually deleted.

### 2. Simulation Execution
- `surfex_OSVAS_run.sh`: A bash script to manage simulation runs over the selected station using the generated forcing files, organize model output in different folders, etc. 

### 3. SURFEX Namelists
- A set of SURFEX namelists tailored for each site, testing advanced SURFEX physics configurations:
  - **3 patches, MEB, DIF, 3-layer snow model**.
- Two versions of each namelist:
  1. **Self-contained**: Uses physiographic data derived from station metadata, without external dependencies.
  2. **NWP-like conditions**: Uses the same physiographic datasets as operational NWP runs. This can be achieved by running PGD for every site on ATOS, BELENOS, etc (where all phisiographic files are available) and extracting the PGD values to the namelist, or simply run all simulations (PGD-PREP-OFFLINE) under those HPCs.

### 4. Download of Validation data from ICOS specialized stations.
The jupyter notebook `ICOS_Flux_downloader.ipynb` retrieves the data and saves it as OBSTABLE sqlite files, which can be used by HARP, custom-made verification scripts or other validation tools. Info about the ICOS dataset(s) from where to extract the validation variables must be included in the "Validation_data" section of the yaml files. The sampling frequency, how to rename the ICOS variables in the sqlite file and the validation period must also be specified. Stations are identified with a Station ID (SID), making possible to write the validation data to a common obstable for all stations. This is controlled by common_obstable key in the yaml file (see example below)

### Example of yaml config file for "Meteopole" station and syntax (read comments for details)
```
Station_metadata:
  Station_name: Meteopole
  SID: 4300000006
  elev: 158
  lat: 43.572857
  lon: 1.37474
  vegtype: 10
  lai: 1.85,1.50,1.72,2.35,2.15,1.37,1.3,1.25,1.37,1.45,1.3,1.25
  closure_type: 1 # 1 for instantaneous BR closure, 2 for daily BR closure, 3 & 4 for inclusion of canopy storage
                  # (more details in ICOS_Flux_downloader jupyter notebook

Forcing_data:
  height_T: 2                       # Height of the temperature measurement
  height_V: 10                      # Height of the windspeed   measurement
  run_start: '2021-4-30 23:00:00'    # Timestamp for the forcing start
  run_end: '2022-7-1 00:00:00'      # Timestamp for the forcing end
  forcing_format: 'netcdf'          # Choose between netcdf or ascii
  dataset1:  # Define as many datasets as needed if a single dataset doesn't contain all the forcing variables
    doi: https://meta.icos-cp.eu/objects/VIoR-cJnMUUjbaEkuNHMKgSv
    timedelta: 30  # Sampling frequency of the dataset (in minutes)
    variables:
      Forc_CO2: -, 0.00062 # Define pairs {variable,transformation}. This will lead to constant CO2.
      Forc_PS: PA, *1000   # This will multiply PA by 1000 to get Forc_PS in Pa
      Forc_RAIN: P, /(timedelta*60)   # This will transform from precipitation to precipitation rate.
      Forc_SNOW:    # Any non-filled variable will result in a forcing variable full of zeroes.
      Forc_WIND: WS
      Forc_DIR: WD      
      Forc_DIR_SW: SW_IN
      Forc_LW: LW_IN
      Forc_QA: # If no variable for Forc_QA is available, the script will try to get it from Forc_RH or VPD.
      Forc_SCA_SW: 
      Forc_TA: TA, +273.15   # Transform to Kelvin
      Forc_RH: RH
Validation_data:
  validation_start: '2021-4-30 23:00:00'
  validation_end: '2022-7-1 00:00:00'
  common_obstable: TRUE  # Write obs to a common obstable or to a single-station one
  dataset1: 
    doi: https://meta.icos-cp.eu/objects/VIoR-cJnMUUjbaEkuNHMKgSv
    timedelta: 30
    variables:
      SW_OUT: SW_OUT
      LW_OUT: LW_OUT
      TS_1: TS_1
      TS_2: TS_2
      TS_3: TS_3
      TS_4: TS_4
      TS_5: TS_5
      SWC_1: SWC_1
      SWC_2: SWC_2
      SWC_3: SWC_3
      SWC_4: SWC_4
      SWC_5: SWC_5
      G: G
  dataset2: 
    doi: https://meta.icos-cp.eu/objects/No7s1uuHhY2frqKUg6CSIRV-
    timedelta: 30
    variables:
     H: H_F_MDS
     LE: LE_F_MDS
     VPD: VPD_F
     NEE: NEE_VUT_REF
```
The configuration file above will be treated by `Write_ICOS_forcing.ipynb` to generate forcing files in ascci or netcdf format according to the defined datasets and transformations, and by `ICOS_Flux_downloader.ipynb` to generate a validation dataset from the different ICOS datasets specified in the Validation_data block. In both cases, if several datasets with different sampling rates are provided, the data will be upsampled to a common (smallest) timedelta.

### 5. Convert SURFEX OFFLINE output data from ncfile to sqlite FCTABLES, for use in HARP.

Similarly to grib2sqlite[https://github.com/destination-earth-digital-twins/grib2sqlite] utility, a new python tool has been created here to help extract SURFEX output variables from single-point OFFLINE SURFEX RUNS into FCTABLES suitable for use with HarPoint / oper-harp-verif[https://github.com/harphub/oper-harp-verif] , or with other custom made verification software capable to read observations & simulation data from sqlite files. This tool needs a dictionary of SURFEX variable names to observation variable names (i.e. variable names in the OBSTABLES). In order to use oper-harp-verif, they should also be defined in set_params.R from this set of scripts. In the future, nc2sqlite tool could be extended to allow data extraction from 2-D SURFEX offline runs, i.e. through interpolation from the NetCDF grid.

usage: nc2sqlite.py [-h] -p PARAM_LIST -s STATION_LIST -st STATION -o OUTPUT -m EXPERIMENT_NAME ncdir

Convert point NetCDF SURFEX output to SQLite.

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
  -o OUTPUT, --output OUTPUT
                        Output base directory
  -m EXPERIMENT_NAME, --experiment_name EXPERIMENT_NAME
                        Experiment name


## Next Steps
- Additional instructions for **model output validation** will be included soon.


