library(dplyr)
library(stringr)
library(readr)
library(lubridate)
library(here)

temp_data_dir <- here::here("data", "temp")
delay_data_dir <- here::here("data", "delay")

dir.create(delay_data_dir, showWarnings = FALSE)

load(file = file.path(temp_data_dir, "latest_linelist.RData"))

# Maximum delay (in days) between symptom onset and reported event
# (case confirmation, death or hospital admission)
max_delay_hosp <- 30
max_delay_confirm <- 30
max_delay_death <- 100

# Select relevant columns and make first curation step
delay_data <- linelist %>%
  dplyr::select(manifestation_dt, fall_dt, hospdatin, pttoddat) %>%
  dplyr::filter(!is.na(manifestation_dt)) %>%
  dplyr::mutate(across(everything(), lubridate::ymd)) %>%
  dplyr::mutate(across(everything(), ~ if_else(between(.x, min_date, max_date), .x, as.Date(NA)))) # curate entries with unrealistic dates

## Delays from onset of symptoms to case confirmation

case_confirmation_delays <- delay_data %>%
  dplyr::transmute(event_date = manifestation_dt,
            report_date = fall_dt) %>%
  dplyr::filter(!is.na(report_date)) %>%
  dplyr::mutate(report_delay = as.integer(report_date - event_date)) %>%
  dplyr::mutate(report_delay = if_else(report_delay < 0, as.integer(NA), report_delay)) %>%  # curate negative delays
  dplyr::mutate(report_delay = if_else(report_delay > max_delay_confirm, as.integer(NA), report_delay)) %>%  # curate unrealistically high delays
  dplyr::filter(!is.na(report_delay)) %>% # remove NA values
  dplyr::select(-report_date) %>% # rearrange data.frame
  dplyr::arrange(event_date)

### Save delay file
readr::write_csv(case_confirmation_delays, file = file.path(delay_data_dir, "case-confirmation_delays.csv"))
readr::write_csv(case_confirmation_delays, file = file.path(delay_data_dir, "case-confirmation-normalized-by-tests_delays.csv"))


## Delays from onset of symptoms to hospital admission

hospital_admission_delays <- delay_data %>%
  dplyr::transmute(event_date = manifestation_dt,
                   report_date = hospdatin) %>%
  dplyr::filter(!is.na(report_date)) %>%
  dplyr::mutate(report_delay = as.integer(report_date - event_date)) %>%
  dplyr::mutate(report_delay = if_else(report_delay < 0, as.integer(NA), report_delay)) %>%  # curate negative delays
  dplyr::mutate(report_delay = if_else(report_delay > max_delay_hosp, as.integer(NA), report_delay)) %>%  # curate unrealistically high delays
  dplyr::filter(!is.na(report_delay)) %>% # remove NA values
  dplyr::select(-report_date) %>% # rearrange data.frame
  dplyr::arrange(event_date)

### Save delay file
readr::write_csv(hospital_admission_delays, file = file.path(delay_data_dir, "hospital-admission_delays.csv"))


## Delays from onset of symptoms to death

death_delays <- delay_data %>%
  dplyr::transmute(event_date = manifestation_dt,
                   report_date = pttoddat) %>%
  dplyr::filter(!is.na(report_date)) %>%
  dplyr::mutate(report_delay = as.integer(report_date - event_date)) %>%
  dplyr::mutate(report_delay = if_else(report_delay < 0, as.integer(NA), report_delay)) %>%  # curate negative delays
  dplyr::mutate(report_delay = if_else(report_delay > max_delay_death, as.integer(NA), report_delay)) %>%  # curate unrealistically high delays
  dplyr::filter(!is.na(report_delay)) %>% # remove NA values
  dplyr::select(-report_date) %>% # rearrange data.frame
  dplyr::arrange(event_date)

### Save delay file
readr::write_csv(death_delays, file = file.path(delay_data_dir, "death_delays.csv"))
