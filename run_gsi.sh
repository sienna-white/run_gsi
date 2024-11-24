#!/bin/sh
#SBATCH --job-name=gsi
#SBATCH --partition=savio2_bigmem
#SBATCH --account=co_aiolos 
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --time=00:30:00

#######################################################
##        SCRIPT FOR RUNNING GSI!                    ##
##          siennaw@berkeley.edu                     ##   
##  view documentation at:                           ##
##  https://github.berkeley.edu/siennaw/run_GSI      ##
#######################################################

#################### USER INPUT #######################
date="$1"
#date=2018111421

DEBUG=1 # (0,1): Debug options 1 for True (print extra info), 0 for False (less output)
CLEAN=1 # (0,1): 1 for clean folder/delete interim files, 0 for keep extra files
LINK_BINARY=0 #(0,1) 1=Link binary files (should only have to do once); 0=Don't link 
#######################################################

# Load modules 
echo "Loading modules..."
module purge
module load gcc/13.2.0
module load openmpi/4.1.6
module load hdf5/1.14.3
module load netcdf-c/4.9.2
module load netcdf-fortran/4.6.1
module load openblas/0.3.24
module load netlib-lapack/3.11.0
module load nco/5.1.6
module load intel-oneapi-mkl/2023.2.0
#source /global/home/users/leoal/miniconda3/etc/profile.d/conda.sh
conda activate geo_env

# Define file paths 

OBS_ROOT=/global/scratch/users/tinakc/AQS_bufr_data
#OBS_ROOT=/global/scratch/users/tinakc/PA_bufr_data
BKG_ROOT=/global/scratch/users/leoal/test_convert/convert/output
PREPBUFR=${OBS_ROOT}/HourlyPM_${date}.bufr
#PREPBUFR=${OBS_ROOT}/HourlyPM_${date}.bufr
BKG_FILE=${BKG_ROOT}/wrfinput_d01_${date}.nc
WORKING_DIRECTORY=$(pwd)
#RUN_FOLDER=/global/scratch/users/leoal/test_convert/convert/WRFINOUT7
RUN_FOLDER=/global/scratch/users/rasugrue/GSI/WRF_INOUT_niter50_Hongli_test5


#/global/home/users/tinakc/folder_for_GSI2/comGSIv3.7_EnKFv1.3/build/bin/
#GSI_EXECUTABLE=/global/home/users/tinakc/GSIall/build/src/gsi/gsi.x
GSI_EXECUTABLE=/global/scratch/users/hongli_wang/code/20240927/temp/GSIall/build2/src/gsi/gsi.x

cd $RUN_FOLDER

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

# Check and link observation file
if [ -f "$PREPBUFR" ]; then
  ln -s ${PREPBUFR} ./pm25bufr
  ln -s /global/scratch/users/tinakc/PA_bufr_data_5percentNov/HourlyPM_${date}.bufr ./pm25bufr_pa
else
  echo "Observation file ${PREPBUFR} not found!"
  exit 1
fi

GSI_EXECUTABLE=/global/scratch/users/siennaw/gsi_2024/run_becca/input_files2/gsi.x
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
mv *.png ../plots/
mv wrf_inout wrf_inout_${date}

# Clean up if CLEAN is set to 1.
if [[ "$CLEAN" -eq 1 ]]; then 
    rm -fr fort.*
    rm -fr pe0*
fi
