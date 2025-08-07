# OSVAS
## Offline Surfex Validation System

OSVAS is a set of scripts and namelists developed within the ACCORD community to provide a systematic approach for testing NWP-like SURFEX settings over specialized Atmospheric & Ecosystem stations from the ICOS project. It also facilitates validation of results using flux data from the same source.

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

### Example of yaml config file and syntax (read comments for details)
```
Station_metadata:
  Station_name: Meteopole
  SID: 4300000006
  elev: 158
  lat: 43.572857
  lon: 1.37474
  vegtype: 10
  lai: 1.85,1.50,1.72,2.35,2.15,1.37,1.3,1.25,1.37,1.45,1.3,1.25

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
``
The configuration file above will be treated by Write_ICOS_forcing to generate forcing files in ascci or netcdf format according to the defined datasets and transformations.
It will also be used by ICOS_Flux_downloader to generate a validation dataset from the different ICOS datasets specified in the Validation_data block.
In both cases, if several datasets with different sampling rates are provided, the data will be upsampled to a common (smallest) timedelta.

## Next Steps
- Additional scripts for **model output validation** will be included soon.


