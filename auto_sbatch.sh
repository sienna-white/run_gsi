#!/bin/bash
#SBATCH --job-name=auto_run_gsi
#SBATCH --partition=savio3
#SBATCH --account=co_aiolos 
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --time=09:00:00

echo "Running script now..."

# Path to the available_wrf_files.txt
AVAILABLE_FILES="/global/home/users/leoal/GSI_runs/run_GSI/testrun/run_GSI/available_wrf_files.txt"

# Directory where the output files are expected
#RUN_FOLDER="/global/scratch/users/leoal/test_convert/convert/WRFINOUT_w_niter50_H"
RUN_FOLDER="/global/scratch/users/rasugrue/GSI/WRF_INOUT_niter50_Hongli_test5"

# Directory where to save the plots and Slurm output files
PLOT_DIR="/global/home/users/rasugrue/testrun/plots"
LOG_DIR="/global/home/users/rasugrue/testrun/log"

# Path to the Python script for creating plots
PLOT_SCRIPT="/global/scratch/users/siennaw/scripts/HRRRpy/create_plots.py"

# Function to process each date
process_date() {
    local date="$1"
    if ! [[ "$date" =~ ^201811(08(0[6-9]|1[0-9]|2[0-3])|09([0-1][0-9]|2[0-3])|10([0-1][0-9]|2[0-3])|11([0-1][0-9]|2[0-3])|12([0-1][0-9]|2[0-3])|13([0-1][0-9]|2[0-3])|14([0-1][0-9]|2[0-3])|15([0-1][0-9]|2[0-3])|16([0-1][0-9]|2[0-3])|17(0[0-9]|1[0-7]|2[0-3])|18([0-1][0-9]|2[0-3])|19([0-1][0-9]|2[0-3])|20([0-1][0-9]|2[0-3])|21(0[0-9]|1[0-9]|2[0-3]))$ ]]; then
        echo "Skipping date: $date, as it does not match the required pattern."
        return
    fi
    echo "Processing date: $date"

    # Submit the job and get its ID
    job_id=$(sbatch --parsable --job-name="run_gsi_${date}" --output="${LOG_DIR}/run_gsi_${date}.%j.out" /global/home/users/rasugrue/testrun/run_GSI/run_gsi.sh "$date")

    echo "Submitted run_gsi.sh for date ${date} with job ID ${job_id}, waiting for completion..."

    # Wait for the job to complete
    while :
    do
        job_status=$(squeue --job ${job_id} --noheader --format=%T)
        if [ -z "$job_status" ]; then
            echo "Job ${job_id} completed, proceeding with plot generation."
            break
        else
            echo "Job ${job_id} is still ${job_status}, waiting..."
            sleep 10 # Wait for 10 seconds before checking again
        fi
    done

    # Check if the output file exists before proceeding
    output_file="${RUN_FOLDER}/wrf_inout_${date}"
    if [ ! -f "${output_file}" ]; then
        echo "Error: Expected output file ${output_file} not found after job completion."
        return
    fi

    # Commented out the plot generation
    # echo "Generating plots for ${date}..."
    # python "${PLOT_SCRIPT}" "${output_file}" "${date}" "${PLOT_DIR}"
    # echo "Plots for ${date} have been created."
}

# Generate the list of dates between 2018111500 and 2018112123
generate_dates() {
    local start_date="2018111900"
    local end_date="2018111923"

    current_date="$start_date"
    while [[ "$current_date" -le "$end_date" ]]; do
        echo "$current_date"
        current_date=$(date -d "${current_date:0:8} ${current_date:8:2} +1 hour" +"%Y%m%d%H")
    done
}

# Generate dates and process each one
generate_dates | while IFS= read -r date; do
    process_date "$date"
done

# >> PARALLELJOB-$SLURM_JOB_ID.txt