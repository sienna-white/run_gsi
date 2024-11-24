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
echo "running plot script"
#################### USER INPUT #######################
# Path to the Python script for creating plots
PLOT_SCRIPT="/global/scratch/users/siennaw/scripts/HRRRpy/create_plots.py"

cd /global/scratch/users/siennaw/gsi_2024/output/108/


date=2018111902
fn=/global/scratch/users/siennaw/gsi_2024/output/108/wrf_inout_${date}
~/.conda/envs/smoke_env/bin/python "${PLOT_SCRIPT}" ${fn} ${date} 

date=2018111704
fn=/global/scratch/users/siennaw/gsi_2024/output/108/wrf_inout_${date}
~/.conda/envs/smoke_env/bin/python "${PLOT_SCRIPT}" ${fn} ${date} 

date=2018110914
fn=/global/scratch/users/siennaw/gsi_2024/output/108/wrf_inout_${date}
~/.conda/envs/smoke_env/bin/python "${PLOT_SCRIPT}" ${fn} ${date} 

date=
fn=/global/scratch/users/siennaw/gsi_2024/output/108/wrf_inout_${date}
~/.conda/envs/smoke_env/bin/python "${PLOT_SCRIPT}" ${fn} ${date} 

date=2018111216
fn=/global/scratch/users/siennaw/gsi_2024/output/108/wrf_inout_${date}
~/.conda/envs/smoke_env/bin/python "${PLOT_SCRIPT}" ${fn} ${date} 