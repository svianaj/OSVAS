#!/bin/bash

HARP_DEV_VERSION="yes"
while [ $# -gt 0 ]; do
    case "$1" in
        -d|--develop)
            HARP_DEV_VERSION="yes"
            shift
            ;;
    esac
done
export HARP_DEV_VERSION

cd "$(dirname "$0")" || exit


echo "Creating renv in $PWD"
module load R 
module load proj
module load netcdf4

#export R_LIBS_USER=/etc/ecmwf/nfs/dh1_home_b/sp3c/R/x86_64-pc-linux-gnu-library/4.4/

./renv_setup.R
