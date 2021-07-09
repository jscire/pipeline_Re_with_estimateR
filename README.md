# Pipeline for estimating Re in Switzerland

The file scripts/pipe/run_swiss_estimates.sh runs the entire pipeline.
It assumes that the latest linelist data of interest is in the data/raw/BAG folder.
The folder paths can be modified easily in the various R scripts (usually at the very top of the script),
and in the run_swiss_estimates.sh script.

Comments in run_swiss_estimates.sh should help understand what each step does.
The time required to execute all steps can be drastically reduced by parallelizing the Re calculation steps in
that script.
Each step in the for loop corresponds to the Re estimation on a particular region.
Different computing nodes can work in parallel on different regions to execute the code faster,
instead of doing them all in succession on a single CPU.
