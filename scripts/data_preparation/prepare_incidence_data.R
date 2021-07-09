library(dplyr)
library(stringr)
library(readr)
library(lubridate)
library(here)
library(tidyr)

temp_data_dir <- here::here("data", "temp")
incidence_data_dir <- here::here("data", "incidence")

dir.create(incidence_data_dir, showWarnings = FALSE)

load(file = file.path(temp_data_dir, "latest_linelist.RData"))

# Maximum delay (in days) between symptom onset and reported event
max_delay_confirm <- 30

raw_case_confirmation_data <- linelist %>%
  dplyr::select(manifestation_dt, fall_dt, ktn) %>%
  dplyr::mutate(across(c(manifestation_dt, fall_dt), ymd)) %>%
  dplyr::mutate(across(c(manifestation_dt, fall_dt), ~ if_else(
    between(.x, min_date, max_date - right_truncation[["Confirmed cases"]]),
    .x,
    as.Date(NA)))) %>%
  dplyr::filter(!is.na(fall_dt)) %>%
  dplyr::transmute(report_date = fall_dt,
                   onset_date = manifestation_dt,
                   region = ktn)

# Gather the incidence based on all confirmed cases
case_incidence <- raw_case_confirmation_data %>%
  dplyr::mutate(date = report_date, .keep = "unused") %>%
  dplyr::group_by(date, region) %>%
  dplyr::tally(name = "case_incidence")

# Gather incidence based on dates of onset of symptoms
# for cases for which it is known
onset_incidence <- raw_case_confirmation_data %>%
  dplyr::mutate(date = onset_date, .keep = "unused") %>%
  dplyr::filter(!is.na(.data$date)) %>%
  dplyr::group_by(date, region) %>%
  dplyr::tally(name = "onset_incidence")

# Gather incidence based on dates of case confirmation
# for cases with no known date of onset of symptoms
report_incidence <- raw_case_confirmation_data %>%
  # Only keep report_date when we do not have the onset_date
  dplyr::mutate(date = dplyr::if_else(is.na(.data$onset_date),
                                      .data$report_date,
                                      as.Date(NA))) %>%
  dplyr::filter(!is.na(.data$date)) %>%
  dplyr::group_by(date, region) %>%
  dplyr::tally(name = "report_incidence")

incidence_data <- dplyr::full_join(onset_incidence, report_incidence, by = c('date', 'region')) %>%
  dplyr::full_join(y = case_incidence, by = c('date', 'region')) %>%
  tidyr::replace_na(list(onset_incidence = 0, report_incidence = 0, case_incidence = 0)) %>%
  dplyr::group_by(region) %>%
  tidyr::complete(date = seq.Date(min_date, # add zeroes for dates with no reported case
                                  max_date - right_truncation[["Confirmed cases"]],
                                  by = "days"),
                  fill = list(onset_incidence = 0,
                              report_incidence = 0,
                              case_incidence = 0)) %>%
  dplyr::ungroup() %>%
  dplyr::select(.data$date, .data$region, .data$case_incidence, .data$onset_incidence, .data$report_incidence) %>%
  dplyr::arrange(.data$date, .data$region)

# Calculate the Swiss incidence by aggregating the incidence from all Swiss cantons
swiss_incidence <- incidence_data %>%
  dplyr::filter(region != "FL") %>%
  dplyr::group_by(date) %>%
  dplyr::summarise(case_incidence = sum(case_incidence),
                   onset_incidence = sum(onset_incidence),
                   report_incidence = sum(report_incidence),
                   .groups = "drop") %>%
  dplyr::mutate(region = "CH")

# Build incidence of greater regions by aggregating the incidence of corresponding cantons
greater_regions <- tribble(
  ~greater_region,  ~region,
  "gr_LGR",         c("VD", "VS", "GE"),
  "gr_EM",          c("BE", "FR", "SO", "NE", "JU"),
  "gr_NCH",         c("BS", "BL", "AG"),
  "gr_ZH",          c("ZH"),
  "gr_ECH",         c("GL", "SH", "AR", "AI", "SG", "GR", "TG"),
  "gr_CCH",         c("LU", "UR", "SZ", "OW", "NW", "ZG"),
  "gr_TI",          c("TI"),
) %>% unnest(cols = c(region))

greater_regions_incidence <- incidence_data %>%
  left_join(greater_regions, by = "region") %>%
  ungroup() %>%
  mutate(region = greater_region, .keep = "unused") %>%
  group_by(date, region) %>%
  dplyr::summarise(case_incidence = sum(case_incidence),
                   onset_incidence = sum(onset_incidence),
                   report_incidence = sum(report_incidence),
                   .groups = "drop") %>%
  filter(!is.na(region))

incidence_data <- bind_rows(incidence_data, greater_regions_incidence, swiss_incidence)

regional_incidences <- incidence_data %>%
  dplyr::group_split(region, .keep = FALSE)

names(regional_incidences) <- incidence_data %>%
  dplyr::group_keys(region) %>%
  dplyr::pull(region)

lapply(names(regional_incidences), function(x){
  readr::write_csv(regional_incidences[[x]], file = file.path(incidence_data_dir, paste0(x, "_incidence.csv")))
})



