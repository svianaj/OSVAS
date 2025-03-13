# OSVAS
## Offline Surfex Validation System

OSVAS is a set of scripts and namelists developed within the ACCORD community to provide a systematic approach for testing NWP-like SURFEX settings over specialized Atmospheric & Ecosystem stations from the ICOS project. It also facilitates validation of results using flux data from the same source.

## Features

### 1. Forcing Data Preparation
- A Python notebook (`Write_ICOS_forcing.ipynb`) allows users to:
  - Select different ICOS stations.
  - Configure a start and end date.
  - Generate SURFEX forcing files in ASCII or NetCDF format for simulations.
- Supported stations: **Majadas_South (ES), Meteopole (FR), and Loobos (NL)** (Fluxnet data format, accessible via ICOS Data Portal).
- Available formats:
  - **ASCII format**: Forcings are generated for the entire simulation period.
  - **NetCDF format**: Daily NetCDF files are created, with a merging function available in the notebook.
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

## Next Steps
- Additional scripts for **model output validation** will be included soon.


