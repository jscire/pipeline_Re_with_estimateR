library(here)
library(dplyr)
library(readr)
library(fs)
library(lubridate)

fragmented_results_dir <- here::here("data", "results", "fragmented")
aggregated_results_dir <- here::here("data", "results", "aggregated")

aggregated_results_file_name <- paste0(today(), "_swiss-estimates.csv")

dir.create(aggregated_results_dir, showWarnings = FALSE)

# Names of columns with estimates in the result files
Re_col_name <- "Re_estimate"
CI_down_col_name <- "CI_down_Re_estimate"
CI_up_col_name <- "CI_up_Re_estimate"

# Get the list of files to aggregate
fragmented_results_files <- list.files(fragmented_results_dir,
                                       pattern = "[A-Za-z-]+_[A-Za-z-]+.csv",
                                       full.names = TRUE)

# Define a function that adds metadata columns to the estimates
add_metadata_to_estimates <- function(full_file_name) {
  col_types <- list(date = col_date(format = ""))
  col_types[[Re_col_name]] <- col_double()
  col_types[[CI_down_col_name]] <- col_double()
  col_types[[CI_up_col_name]] <- col_double()

  estimates <- read_csv(full_file_name,
                        col_types = col_types)

  # Get rid of leading NAs and keep three digits
  first_date_of_interest <- min(filter(estimates, !is.na(.data[[Re_col_name]]))$date)
  estimates <- filter(estimates, date >= first_date_of_interest) %>%
    mutate(!!Re_col_name := round(.data[[Re_col_name]], digits = 3),
           !!CI_down_col_name := round(.data[[CI_down_col_name]], digits = 3),
           !!CI_up_col_name := round(.data[[CI_up_col_name]], digits = 3))


  file_name <- path_file(full_file_name)

  # Gather the metadata from the "_"-separated file names
  metadata <- unlist(strsplit(file_name, split = "_"))[1]

  # Region is the first group
  region <- metadata[1]
  # (we could include more metadata in the filenames, but we don't here)

  # Add the metadata to the estimates
  augmented_estimates <- estimates %>%
    mutate(region = region) %>%
    dplyr::select(date, region, everything()) %>%
    dplyr::arrange(date)

  return(augmented_estimates)
}

list_of_augmented_estimates <- lapply(fragmented_results_files, add_metadata_to_estimates)

# Aggregate results
aggregated_results <- bind_rows(list_of_augmented_estimates)

# Save result
write_csv(aggregated_results,
          file = file.path(aggregated_results_dir, aggregated_results_file_name))
