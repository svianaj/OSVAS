## Step 6: Display HARP verification results
In this step, the script launches the visualization scripts available in oper-harp-verif to be able to visualize the HARP output:
- launch_dynamicapp_atos.R : For dynamic inspection of HARP's output .rds data files
- launch_visapp.R : For inspection of HARP's collection of png files with extra scores & visualizations.
  
These scripts launch the corresponding shiny apps using ports 9999 and 9998. To keep the terminal free, the output is redirected to $OSVAS/dynamicapp.log and $OSVAS/visapp.log.

- In a linux machine, the shiny apps will be available at http://127.0.0.1:9999 and http://127.0.0.1:9998 by default
- Often these ports are used by other instances of shiny apps (e.g. if they were not properly freed) or by other local services. If that's the case, the logs will inform about this. 
- In order to free a port in this situation, use this command:  ``kill -9 $(lsof -t -i :9999)``
- Alternativelly, change the ports in the corresponding step of the bash script.

- When accessing ATOS with the VMWare Desktop tool, the shiny app runs in the hpc platform while the browser tipically runs in the virtual desktop login node (e.g. sp3c@lfcm-078). To visualize the shiny apps in the browser, an extra step is required. It is available in the dynamicapp.log and visapp.log files , and for completeness also here:
```
[1] "To display the Shiny app in a Firefox window at ATOS:"
[1] "1: Open a new terminal."
[1] "2: Execute this command: ssh -L 9999:localhost:9999 "
[1] "3: Open a Firefox window and go to http://127.0.0.1:9999/"
