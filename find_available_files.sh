#!/bin/sh

wrf_file_folder=/global/scratch/users/leoal/test_convert/convert/output/

dates=$(basename -a ${wrf_file_folder}/*.nc | grep -E -o "[0-9]{10}")

# date=$(basename -a ${BKG_FILE} | grep -E -o "[0-9]{10}")

# Remove file if it already exists
rm available_wrf_files.txt

for date in $dates; do
    echo $date >> available_wrf_files.txt
done 