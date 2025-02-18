# OSVAS
Offline Surfex Validation System
This set of scripts and namelists represents an effort within the ACCORD community
to deploy a systematic way of testing NWP-like SURFEX settings over speciallized Atmospheric & Ecosystem
stations from the ICOS project, as well as validating results with flux data from the same source.
Currently it comprises:
1. A python notebook Write_ICOS_forcing.ipynb where the user can select between different stations, configure
   a start and end date and produce SURFEX forcing in ASCII or NetCDF format to run simulations over the selected station.
   Currenly Majadas_south (ES) and Fyodorovskoye (FI) are available, which belong to Fluxnet and thus data in this common data format
   can be accessed from ICOS's Data Portal.
   In case of ASCII format, forcings are generated for the entire simulation period. A lockfile is included in the forcing dir to prevent re-writing of forcing files
   In case of NetCDF format, daily netcdf files are generated for the station, which can be combined later with a merging function available in the notebook
   A lockfile is also written which will have to be deleted if one wants to re-do netcdf forcing for a period already downloaded.
   
3. A surfex_OSVAS_run.sh bash script to control the run of the simulation over the selected station using the forcing created in step 1

4. A set of SURFEX namelists for each site, to be used for testing our target configuration of SURFEX advanced physics (3 patches, MEB, DIF, 3-L SNOW...). For every station, two versions of every namelist is available: one is self-contained wrt physiographic data, meaning that physiographic parameters was read or derived from the station's metadata and no external physiography is needed; the other one tries to emulate NWP-like conditions, so that the physiographic data is generated from the same phisiographic files as in the NWP run. Currently used versions of ECOCLIMAP (I, II or SG) and other needed files (soil texture, digital elevation models, LAI, etc...) can be large files. This means that often the simulations will need to be run in the HPC where the NWP model is run, or at least the PGD step.
   
5. Installation
   For using the python notebook , a requirements.txt is included with all needed softare packages.
   Install as usually with pip install -r requirements.txt
   For running the simulations, a SURFEX installation is obviously needed and correctly referenced in surfex_OSVAS_run.sh

6. Next steps. These scripts will be completed soon with others dedicated to validation of the model output.
   
