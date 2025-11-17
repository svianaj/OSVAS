## Step 3: Configure and run the simulations
In this part, for every EXPNAME defined in Expnames:
-  A directory for running the experiment is created in $OSVAS/RUNS/$STATION_NAME/$EXPNAME/run/
-  Forcing and physiographic files are linked in the execution directory
-  A copy of $OSVAS/namelists/Stations/{STATION_NAME}/OPTIONS.nam_{EXPNAME} is made as OPTIONS.nam in the execution directory
-  NYEAR, NMONTH, NDAY, XTIME and CFORCING_FILETYPE namelists from OPTIONS.nam are modified according to the content in the yml file
-  The SURFEX steps defined in OSVAS_steps.Surfex_steps are run
-  The output netcdf files, OPTIONS.nam and *.txt logs are moved to $OSVAS/RUNS/$STATION_NAME/$EXPNAME/output/
