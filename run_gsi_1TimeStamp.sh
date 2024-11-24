#!/bin/sh
#SBATCH --job-name=gsi
#SBATCH --partition=savio3
#SBATCH --account=co_aiolos 
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00

#######################################################
##        SCRIPT FOR RUNNING GSI!                    ##
##          siennaw@berkeley.edu                     ##   
##  view documentation at:                           ##
##  https://github.berkeley.edu/siennaw/run_GSI      ##
#######################################################

#################### USER INPUT #######################
# date="$1"
date=2018111902

DEBUG=0 # (0,1): Debug options 1 for True (print extra info), 0 for False (less output)
CLEAN=1 # (0,1): 1 for clean folder/delete interim files, 0 for keep extra files
LINK_BINARY=0 #(0,1) 1=Link binary files (should only have to do once); 0=Don't link 
#######################################################

path2spack=/global/scratch/users/siennaw/gsi_2024/compiling/spack

# *********************** COMPILE GSI ************************* 
# steps to compile after the packages have been installed
###############################################################

# This sources the environment variables spack needs from the local spack folder
. ${path2spack}/share/spack/setup-env.sh

# ****************** LOAD IN SPACK DIRECTORIES **************** 
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
OBS_ROOT=/global/scratch/users/tinakc/AQS_bufr_data
#OBS_ROOT=/global/scratch/users/tinakc/PA_bufr_data

GSI_EXECUTABLE=/global/scratch/users/siennaw/gsi_2024/compiling/gsi4savio/GSIall/build/src/gsi/gsi.x

# Location of WRF output file 
BKG_ROOT=/global/scratch/users/leoal/test_convert/convert/output

# Where we hope to execute our run
RUN_FOLDER=/global/scratch/users/siennaw/gsi_2024/test_run

# ************************************************
PREPBUFR=${OBS_ROOT}/HourlyPM_${date}.bufr
BKG_FILE=${BKG_ROOT}/wrfinput_d01_${date}.nc
WORKING_DIRECTORY=$(pwd)
cd $RUN_FOLDER
rm std* 
# rm *.png
# ************************************************


# Link binary files (should only need to do this once)
if [[ "$LINK_BINARY" -eq 1 ]]; then 
    cd /global/scratch/users/hongli_wang/gsipm/wrfcam/run/case09-proc2-wrfchem_oneob_new_bg_lv29/
    ln -s *.bin ${RUN_FOLDER} 
    cd ${RUN_FOLDER}
fi 

# Clean up excess files if they exist
rm -f pm25bufr wrf_inout wrf_PRE temp.nc

# Check and copy background file
if [ -f "$BKG_FILE" ]; then
  echo "Copying background field"
  cp ${BKG_FILE} wrf_inout 
else
  echo "Background file ${BKG_FILE} not found!"
  exit 1
fi

# Copy namelist into run folder 
cd ${WORKING_DIRECTORY}/input_files/
cp * ${RUN_FOLDER}
cd ${RUN_FOLDER}

# Check and link observation files
rm pm25bufr
rm pm25bufr_pa
if [ -f "$PREPBUFR" ]; then
  ln -s ${PREPBUFR} ./pm25bufr
  ln -s /global/scratch/users/tinakc/PA_bufr_data_5percentNov/HourlyPM_${date}.bufr ./pm25bufr_pa
  # cp /global/scratch/users/siennaw/data/obs/aqs/bufr/HourlyPM_${date}.bufr pm25bufr
else
  echo "Observation file ${PREPBUFR} not found!"
  exit 1
fi

# Check if GSI executable exists
if [ -f "$GSI_EXECUTABLE" ]; then
  cp $GSI_EXECUTABLE ./gsi.x
else
  echo "GSI executable ${GSI_EXECUTABLE} not found!"
  exit 1
fi

# Save initial PM2.5 Field 
if command -v ncks &> /dev/null; then
  ncks -v PM2_5_DRY wrf_inout temp.nc
  ncrename -v PM2_5_DRY,PM2_5_DRY_INIT temp.nc
else
  echo "ncks command not found. Ensure NCO tools are installed and loaded."
  exit 1
fi

# Debug options
if [[ "$DEBUG" -eq 1 ]]; then 
  module list
  which mpirun
  ldd gsi.x
fi 

# Run gsi, feeding in the namelist file 'gsiparm.anl', direct output to output file 
output=stdout_GSI_${date}
echo -e "\t Running gsi, directing output to: $output"
mpirun ./gsi.x < gsiparm.anl > $output 

# Check if GSI ran successfully 
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: GSI crashed with Exit status=${error}"
  exit ${error}
fi

# GSI ran successfully ! 
echo -e "\t GSI has run successfully!"

# Now that it's finished, add initial PM2.5 to the output 
ncks -A -v PM2_5_DRY_INIT temp.nc wrf_inout
echo -e "\t Initial PM2.5 field added back to output netcdf."

# Move results to appropriate location
# mv *.png ../plots/
output_file=wrf_inout_${date}
mv wrf_inout ${output_file}

# Clean up if CLEAN is set to 1.
if [[ "$CLEAN" -eq 1 ]]; then 
    rm -fr fort.*
    rm -fr pe0*
fi

# Path to the Python script for creating plots
PLOT_SCRIPT="/global/scratch/users/siennaw/scripts/HRRRpy/create_plots.py"
# SMOKE_PYTHON=
~/.conda/envs/smoke_env/bin/python "${PLOT_SCRIPT}" ${output_file} ${date}

mv *.png ../output 
mv *.nc ../output
echo "Done!"

