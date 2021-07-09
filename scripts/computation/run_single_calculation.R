#!/usr/bin/env Rscript

### NOTE: THIS SCRIPT SHOULD BE RUN IN A CLEAN ENVIRONMENT
## run 'rm(list=ls())'if it is not the case

library(optparse)
library(readr)
library(stringr)
library(estimateR)
library(fs)

option_list = list(
  make_option(c("-c", "--config"), type="character", default=NULL,
              help="configuration file name", metavar="character"),
  make_option(c("-d", "--incidence_data"), type="character", default=NULL,
              help="incidence data file name", metavar="character"),
  make_option(c("-o", "--out"), type="character", default=NULL,
              help="output file name", metavar="character")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

# Set default values for manual execution and testing
if(interactive()) {
  library(here)
  if(is.null(opt$config)) {
    opt$config <- here::here("data", "configuration", "config.RData")
    cat("Setting config file to default value.\n")
  }
  if(is.null(opt$incidence_data)) {
    opt$incidence_data <- here::here("data", "incidence", "GE_incidence.csv")
    cat("Setting incidence_data file to default value.\n")
  }
  if(is.null(opt$out)) {
    opt$out <- here::here("data", "results", "fragmented", "GE_Re.csv")
    cat("Setting out file to default value.\n")
  }

# If not interactive session, throw error if missing argument.
} else {
  if (any(c(is.null(opt$config), is.null(opt$incidence_data), is.null(opt$out)))){
    print_help(opt_parser)
    stop("Missing argument.
       All three arguments (config, incidence_data, out) must be provided.n", call.=FALSE)
  }
}

dir.create(path_dir(opt$out), showWarnings = FALSE)

incidence_data <- try(read_csv(opt$incidence_data,
                               col_types = list(
                                 date = col_date(format = ""),
                                 case_incidence = col_double(),
                                 onset_incidence = col_double(),
                                 report_incidence = col_double()
                               )))

if ("try-error" %in% class(incidence_data)) {
  stop(str_c("Couldn't read data at ", opt$incidence_data))
}

cat("Starting Re estimation...\n")

attach(opt$config)

Re_estimates <- get_bootstrapped_estimates_from_combined_observations(
  partially_delayed_incidence = incidence_data$onset_incidence,
  fully_delayed_incidence = incidence_data$report_incidence,
  smoothing_method = smoothing_method,
  deconvolution_method = deconvolution_method,
  estimation_method = estimation_method,
  uncertainty_summary_method = uncertainty_summary_method,
  N_bootstrap_replicates = N_bootstrap_replicates,
  delay_until_partial = distribution_incubation,
  delay_from_partial_to_full = delays_reporting,
  partial_observation_requires_full_observation = TRUE,
  combine_bootstrap_and_estimation_uncertainties = TRUE,
  estimation_window = estimation_window,
  minimum_cumul_incidence = minimum_cumul_incidence,
  mean_serial_interval = mean_serial_interval,
  std_serial_interval = std_serial_interval,
  ref_date = min(incidence_data$date),
  output_Re_only = TRUE
)

detach(str_c("file:", opt$config), character.only = TRUE)

cat("Done.\n")

# Write results to the specified location
write_csv(Re_estimates, file = opt$out)

