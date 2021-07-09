library(here)

config_dir <- here::here("data", "configuration")
dir.create(config_dir, showWarnings = FALSE)

## Delay between infection and onset of symptoms (incubation period) in days
# Gamma distribution parameter
shape_incubation <- 3.2
scale_incubation <- 1.3

# Incubation period delay distribution
distribution_incubation <- list(name = "gamma",
                                shape = shape_incubation,
                                scale = scale_incubation)

## Delay between onset of symptoms and case confirmation in days
delay_data_file <- here::here("data", "delay", "case-confirmation_delays.csv")
delays_reporting <- readr::read_csv(delay_data_file)

## Serial interval (for Re estimation) in days
mean_serial_interval <- 4.8
std_serial_interval <- 2.3

## Methods used for calculations
smoothing_method = "LOESS"
deconvolution_method <- "Richardson-Lucy delay distribution"
estimation_method <- "EpiEstim sliding window"
uncertainty_summary_method <- "original estimate - CI from bootstrap estimates"

## Re estimation parameters
minimum_cumul_incidence <- 50
estimation_window <- 3

## Uncertainty estimation parameters
N_bootstrap_replicates <- 100
combine_bootstrap_and_estimation_uncertainties <- TRUE

save(list=c("distribution_incubation",
            "delays_reporting",
            "mean_serial_interval",
            "std_serial_interval",
            "smoothing_method",
            "deconvolution_method",
            "estimation_method",
            "uncertainty_summary_method",
            "minimum_cumul_incidence",
            "estimation_window",
            "N_bootstrap_replicates",
            "combine_bootstrap_and_estimation_uncertainties"),
     file = file.path(config_dir, "config_BAG.RData"))






