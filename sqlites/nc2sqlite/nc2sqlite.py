import argparse
import os
import json
import sqlite3
import netCDF4
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from pathlib import Path
from datetime import timezone,datetime
import csv
import sys

def parse_args():
    parser = argparse.ArgumentParser(description="Convert point NetCDF SURFEX output to SQLite.")
    parser.add_argument("-d", "--date", required=True, help="Run start date in YYYYMMDDHH format")
    parser.add_argument("-p", "--param_list", required=True, help="Path to param_list.json")
    parser.add_argument("-s", "--station_list", required=True, help="Path to station_list_default.csv")
    parser.add_argument("-st", "--station", required=True, type=int, help="Station ID")
    parser.add_argument("-o", "--output", required=True, help="Output base directory")
    parser.add_argument("-m", "--experiment_name", required=True, help="Experiment name")
    parser.add_argument("ncdir", help="Directory containing NetCDF files")
    return parser.parse_args()

def load_station_info(station_list_path):
    station_info = {}
    with open(station_list_path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            print(row)
            sid = int(row['SID'])
            lat = float(row['lat'])
            lon = float(row['lon'])
            z = float(row['elev'])
            station_info[int(row['SID'])] = {
                'SID': sid,
                'lat': lat,
                'lon': lon,
                'z': z
            }
    return station_info


def create_fc_table(conn, param_name):
    cursor = conn.cursor()
    cursor.execute("DROP TABLE IF EXISTS FC")
    cursor.execute(f"""
        CREATE TABLE FC (
            fcst_dttm DOUBLE,
            lead_time DOUBLE,
            SID INT,
            z INT,
            lat DOUBLE,
            lon DOUBLE,
            valid_dttm INT,
            parameter TEXT,
            units TEXT,
            {param_name}_det DOUBLE
        )
    """)
    conn.commit()

def process_netcdf_file(ncfile, variables, start_datetime, SID, z, lat, lon, experiment_name, output_base):
    with netCDF4.Dataset(ncfile) as ds:
        time_var = ds.variables["time"]
        times = netCDF4.num2date(time_var[:], time_var.units)

        for var_name in variables:
            if var_name not in ds.variables:
                continue

            var = ds.variables[var_name]
            units = getattr(var, "units", "-")
            values = var[:, 0, 0]  # Assuming (time, lat, lon) with single point

            param_name = var_name
            year, month = start_datetime.year, start_datetime.month
            out_dir = Path(output_base) / experiment_name / f"{year:04d}" / f"{month:02d}"
            out_dir.mkdir(parents=True, exist_ok=True)
            out_path = out_dir / f"FC_{param_name}_{start_datetime.strftime('%Y%m')}.sqlite"

            conn = sqlite3.connect(out_path)
            create_fc_table(conn, param_name)

            cursor = conn.cursor()
            fcst_time = int(start_datetime.timestamp())  # define once, before the loop

            for i, val in enumerate(values):
                if val >= 1e20:  # skip _FillValue
                    continue
                     
                valid_datetime = datetime(times[i].year, times[i].month, times[i].day,
                       times[i].hour, times[i].minute, times[i].second)
                valid_time = int(valid_datetime.timestamp())
                lead_time = (valid_datetime - start_datetime).total_seconds() / 3600.0

                cursor.execute(f"""
                    INSERT INTO FC VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    fcst_time,
                    lead_time,
                    SID,
                    z,
                    lat,
                    lon,
                    valid_time,
                    param_name,
                    units,
                    float(val)
                ))

            conn.commit()
            conn.close()

def main():
    args = parse_args()
    start_datetime = datetime.strptime(args.date, "%Y%m%d%H")
    station_info = load_station_info(args.station_list)
    station_id=int(args.station)
    if station_id not in station_info:
      print(f"Error: Station {station_id} not found in station list.")
      sys.exit(1)

    station = station_info[args.station]
    SID = station['SID']
    z = station['z']
    lat = station['lat']
    lon = station['lon']

    with open(args.param_list) as f:
        param_list = json.load(f)

    nc_files = list(Path(args.ncdir).glob("*.nc"))
    for ncfile in nc_files:
        print(f"Processing {ncfile}")
        process_netcdf_file(ncfile, param_list, start_datetime, SID,z,lat,lon, args.experiment_name, args.output)

if __name__ == "__main__":
    main()

