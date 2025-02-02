#!/bin/sh
#SBATCH --job-name=run_406
#SBATCH --partition=savio3
#SBATCH --account=co_aiolos #fc_anemos #co_aiolos 
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=2
#SBATCH --time=00:10:00

#######################################################
##        SCRIPT FOR RUNNING GSI!                    ##
##          siennaw@berkeley.edu                     ##   
##  view documentation at:                           ##
##  https://github.berkeley.edu/siennaw/run_GSI      ##
#######################################################
# Loop through each line in the file



#################### USER INPUT #######################
path2spack=/global/scratch/users/siennaw/gsi_2024/compiling/spack

# BKG_ROOT=/global/scratch/users/leoal/test_convert/convert/output
BKG_ROOT=/global/scratch/users/siennaw/gsi_2024/grib2nc/finished

# Where we hope to execute our run[s]
RUN_FOLDER=/global/scratch/users/siennaw/gsi_2024/runs/run_2025_2/

# date="$1"
DEBUG=0 # (0,1): Debug options 1 for True (print extra info), 0 for False (less output)
CLEAN=1 # (0,1): 1 for clean folder/delete interim files, 0 for keep extra files
LINK_BINARY=1 #(0,1) 1=Link binary files (should only have to do once); 0=Don't link 
#######################################################

WORKING_DIRECTORY=$(pwd)
available_wrf_files=${WORKING_DIRECTORY}/available_files_sept2020.txt

# Copy namelist into run folder 
cd ${WORKING_DIRECTORY}/input_files/
cp * ${RUN_FOLDER} & 

cd ${RUN_FOLDER}
echo "Copied files into the run folder" 

# ****************** LOAD IN SPACK DIRECTORIES **************** 
# This sources the environment variables spack needs from the local spack folder
. ${path2spack}/share/spack/setup-env.sh 

spack load bufr
spack load ip
spack load sp
spack load bacio
spack load w3emc
spack load sigio
spack load sfcio
spack load nemsio
spack load ncio
spack load gsi-ncdiag
spack load wrf-io
spack load crtm
spack load blas                 #not sure if these are needed too
spack load netcdf-fortran       #not sure if these are needed too
spack load netcdf-c             #not sure if these are needed too
spack load nco 

# Load modules 
echo "Loaded spack modules..."

# ************** USER INPUT ********************
# AQS_OBS_ROOT=/global/scratch/users/tinakc/AQS_bufr_data
AQS_OBS_ROOT=/global/scratch/users/rasugrue/convert2bufr/bufr_AQS

GSI_EXECUTABLE=/global/scratch/users/siennaw/gsi_2024/compiling/gsi4savio/GSIall/build/src/gsi/gsi.x

# Location of WRF output file 
# BKG_ROOT=/global/scratch/users/leoal/test_convert/convert/output
BKG_ROOT=/global/scratch/users/siennaw/gsi_2024/grib2nc/finished

PA_OBS_ROOT=/global/scratch/users/rasugrue/convert2bufr/bufr_vNov2024/

# Link binary files (should only need to do this once)
if [[ "$LINK_BINARY" -eq 1 ]]; then 
    echo "Linking binary files..."
    cd /global/scratch/users/hongli_wang/gsipm/wrfcam/run/case09-proc2-wrfchem_oneob_new_bg_lv29/
    ln -s *.bin ${RUN_FOLDER} &
    cd ${RUN_FOLDER}
fi 

cd ${RUN_FOLDER}

rm *.png

# Clean up excess files if they exist
rm pm25bufr
rm pm25bufr_pa
rm temp.nc
# rm wrf_inout*
# rm stdout_*



# Check if GSI executable exists
if [ -f "$GSI_EXECUTABLE" ]; then
  echo "copying GSI executable ...!"
  cp $GSI_EXECUTABLE ./gsi.x &
else
  echo "GSI executable ${GSI_EXECUTABLE} not found!"
  exit 1
fi


while IFS= read -r line; do
    echo -e "\n\n Running GSI for ${line}"
    cd $RUN_FOLDER   # Make sure we're in the run folder
    date=$line       # Each line is a timestamp to process 

    # ************************************************
    AQS_OBS_BUFR=${AQS_OBS_ROOT}/HourlyPM_${date}.bufr
    PA_OBS_BUFR=${PA_OBS_ROOT}/HourlyPM_${date}.bufr
    BKG_FILE=${BKG_ROOT}/wrfinput_d01_${date}.nc
    # ************************************************

    # ************************************************
    # Check that it exists & and copy background WRF file
    if [ -f "$BKG_FILE" ]; then
        echo "Copying background field ${BKG_FILE}"
        cp ${BKG_FILE} smoke_at_date 
    else
        echo "Background file ${BKG_FILE} not found!"
        exit 1
    fi
    # ************************************************

    # ************************************************
    # Check that it exists & and symlink the PM2.5 BUFR file 
    if [ -f "$AQS_OBS_BUFR" ]; then
        ln -s ${AQS_OBS_BUFR} ./pm25bufr 
        echo "Copied AQS observation file ${AQS_OBS_BUFR}"
        # /global/scratch/users/rasugrue/convert2bufr/validation_vNov2024 >>this is the 5% that was left out for validation 
    else
        echo "Observation file ${AQS_OBS_BUFR} not found!"
        # exit 1
    fi
    # ************************************************

    # Link Purple Air Data
    if [ -f "$PA_OBS_BUFR" ]; then
        # Link Becca's purple air data (Updated to have the PM2.5 corrected)
        ln -s ${PA_OBS_BUFR} ./pm25bufr_pa 
        echo "Copied PA observation file ${PA_OBS_BUFR}"  
    else
        echo "Observation file ${PA_OBS_BUFR} not found!"
        # exit 1
    fi    
    # ************************************************

    # Name of output 
    output_file=wrf_inout_${date}
    if [ -f "$output_file" ]; then
        rm $output_file     # delete if it exists (aka you've already run this date w/ GSI)
    fi 

    # ~/.conda/envs/smoke_env/bin/python prep_nc_files.py smoke_at_date 
    # cp wrfinput4run wrf_inout

    # ncl replace_pm.ncl

    # smoke_at_date

    # /global/scratch/users/siennaw/GSI_OLD/tmp/data/bkg/grib2wrf/2018110818/wrfinput_d01_2018-11-08_21:00:00


    # Save initial PM2.5 Field 
    # ncks -v PM2_5_DRY smoke_at_date $output_file 
    # ncrename -v PM2_5_DRY,PM2_5_DRY_INIT $output_file 
    # echo "Started output file $output_file ..."

    # ncks -v PM2_5_DRY -d bottom_top,0,0 smoke_at_date $output_file 
    # ncks -m $output_file 
    # ncks -x -v PM2_5_DRY wrfinput4run wrf_inout
    # Add initial PM2.5 field to wrfinput4run
    # -v PM2_5_DRY 
    # ncks -A smoke_at_date wrf_inout
   

    # Debug options
    if [[ "$DEBUG" -eq 1 ]]; then 
        module list
        which mpirun
        ldd gsi.x
    fi 

    wait

    # echo "plot script 1" 
    # PLOT_SCRIPT="/global/scratch/users/siennaw/scripts/HRRRpy/create_plots.py"
    # ~/.conda/envs/smoke_env/bin/python "${PLOT_SCRIPT}" wrf_inout ${date}

    # Run gsi, feeding in the namelist file 'gsiparm.anl', direct output to output file 
    output=stdout_GSI_${date}
    echo -e "\t Running gsi, directing output to: $output"
    mpirun ./gsi.x < gsiparm.anl > $output 
    wait 

    # Check if GSI ran successfully 
    error=$?
    if [ ${error} -ne 0 ]; then
        echo "ERROR: GSI crashed with Exit status=${error}"
        exit ${error}
    fi

    # GSI ran successfully ! 
    echo -e "\t GSI has run successfully!"

    # echo "after assimilation:" 
    # ncks -v PM2_5_DRY -d bottom_top,0,0 wrf_inout 

    # echo "wrfinput4run"
    # ncks -m wrf_inout

    # ncks -A -v PM2_5_DRY -d bottom_top,0,0 wrf_inout $output_file

    # ncks -v PM2_5_DRY wrf_inout $output_file

    # ncks -A -v PM2_5_DRY_INIT temp.nc wrf_inout
    # mv wrf_inout $output_file

    # Save initial PM2.5 Field 
    # ncks -v PM2_5_DRY wrf_inout temp.nc
    # ncrename -v PM2_5_DRY,PM2_5_DRY_INIT temp.nc
    mv wrf_inout $output_file 

    # echo -e "\t Initial PM2.5 field added to output netcdf."

    # ncdump $output_file
    # Now that it's finished, add initial PM2.5 to the output 
    # ncks -A -v PM2_5_DRY_INIT temp.nc wrf_inout
    # echo -e "\t Initial PM2.5 field added back to output netcdf."


    # Extract just the smoke fields 
    # ncks -v PM2_5_DRY,PM2_5_DRY_INIT wrf_inout $output_file

    # Path to the Python script for creating plots
    echo "plot script 2" 
    PLOT_SCRIPT="/global/scratch/users/siennaw/scripts/HRRRpy/create_plots.py"
    ~/.conda/envs/smoke_env/bin/python "${PLOT_SCRIPT}" ${output_file} ${date}

    # mv *.png ../output 
    # mv *.nc ../output
    # mv wrf* ../output

    echo "Done!"
    echo $(date)

    # Delete extra files
    # rm -fr fort.*
    # rm -fr pe0*
    rm pm25bufr 
    # rm wrf_inout smoke_at_date
    # rm temp.nc 
    rm pm25bufr_pa
    # rm stdout_*

done < ${available_wrf_files}


# rm pm25bufr 
# rm wrf_inout 
# rm temp.nc 
# rm pm25bufr_pa

echo "Finished all"
# mv wrf_inout_* ../output




