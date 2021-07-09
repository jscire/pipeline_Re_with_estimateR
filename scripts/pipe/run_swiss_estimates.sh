#!/bin/sh

# NOTE: in this showcase script, there is no management of error messages
# nor logging of messages from the code execution

# TODO: change to the coorect dir (folder that contains the ./scripts and ./data)
pipeline_dir="/Users/scirej/Documents/nCov19/Incidence_analysis/Git_repo/pipeline_FOPH"
cd $pipeline_dir

# Load the data from the latest file
# in the folder specified in 'load_latest_data.R'
Rscript ./scripts/data_preparation/load_latest_data.R

# Process the linelist to extract data on delays and on incidence.
# The two scripts can be run in any order.
Rscript ./scripts/data_preparation/prepare_delay_file.R
Rscript ./scripts/data_preparation/prepare_incidence_data.R

# Specify all the parameters for the analysis.
# This script must be run after 'prepare_delay_file.R'
Rscript ./scripts/configuration_preparation/make_config.R

# Run the Re estimation calculations for each region.
incidence_dir="data/incidence"
config_file="data/configuration/config_BAG.RData"
temp_result_dir="data/results/fragmented"
calc_script="./scripts/computation/run_single_calculation.R"

# This for loop can be parallelized:
# Iterations are indenpendent from one another
for file in ${incidence_dir}/*; do
    if [ -f "$file" ]; then
        echo "$file"
        filename=$(basename $file)
        region=${filename%_*}

        echo "Running calculation on ${region}"

        Rscript ${calc_script} \
        --config ${config_file} \
        --incidence_data "${incidence_dir}/${region}_incidence.csv" \
        --out "${temp_result_dir}/${region}_Re.csv"
    fi
done

# Aggregate the results into a single file.
Rscript ./scripts/output_processing/aggregate_results.R
