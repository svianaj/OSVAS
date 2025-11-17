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
