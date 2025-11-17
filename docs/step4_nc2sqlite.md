### Step 4: Sqlite extraction of model data
#### The nc2sqlite tool
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
#### Usage of nc2sqlite.py in OSVAS's workflow
For each experiment, it extract a selection of variables defined in $OSVAS/scripts/nc2sqlite/param_list.json to FCTABLES* files in sqlite format. Make sure that your ICOS Station is included in $OSVAS/sqlites/station_list_SURFEX.csv with the same metadata as in the Station_metadata block of the yml file:
``` 
Station_metadata:
  Station_name: Majadas_del_tietar
  SID: 4300000005
  elev: 265.0
  lat: 39.94033
  lon: -5.77465
  vegtype: 19
``` 
