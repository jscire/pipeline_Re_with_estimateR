library(dplyr)
library(stringr)
library(readr)
library(lubridate)
library(here)

bag_data_dir <- here::here("data", "raw", "BAG")
temp_data_dir <- here::here("data", "temp")

dir.create(temp_data_dir, showWarnings = FALSE)

### Find latest BAG data file
bag_files <- list.files(bag_data_dir,
             pattern = "*FOPH_COVID19_data_extract.csv",
             full.names = TRUE,
             recursive = TRUE)

bag_files <- bag_files[!stringr::str_detect(bag_files, "_old")]

bag_files_dates <- strptime(
  stringr::str_match(bag_files, ".*\\/(\\d*-\\d*-\\d*_\\d*-\\d*-\\d*)")[, 2],
  format = "%Y-%m-%d_%H-%M-%S")

maximum_file_date <- max(bag_files_dates)
newest_file <- bag_files[which(bag_files_dates == maximum_file_date)[1]]

### Load file data
cat("reading file", newest_file, "...\n")
linelist <- readr::read_delim(
  newest_file,
  col_types = cols(
      .default = col_double(),
      eingang_dt = col_date(format = ""),
      fall_dt = col_date(format = ""),
      ktn = col_character(),
      sex = col_character(),
      manifestation_dt = col_date(format = ""),
      hospdatin = col_date(format = ""),
      pttoddat = col_date(format = ""),
      grunderkr_adipos = col_logical(),
      em_hospit_icu_in_dt = col_date(format = ""),
      em_hospit_icu_out_dt = col_date(format = ""),
      exp_land = col_character(),
      exp_von = col_date(format = ""),
      exp_bis = col_date(format = ""),
      exp_dt = col_date(format = ""),
      exp_ausland_von = col_date(format = ""),
      exp_ausland_bis = col_date(format = ""),
      lab_grund_txt = col_character(),
      form_version = col_character(),
      variant_of_concern = col_character(),
      typ = col_character()
    ),
  delim = ";")

max_date <- lubridate::date(maximum_file_date)
min_date <- as.Date("2020-02-01")

# This additional truncation is optional. We will provide details somewhere else.
additional_truncation <- dplyr::case_when(
  lubridate::wday(max_date) == 3 ~ 1, # 3 = Tue, exclude Sat,
  lubridate::wday(max_date) == 4 ~ 2, # 4 = Wed, exclude Sun and Sat,
  lubridate::wday(max_date) == 5 ~ 3, # 5 = Thu, exclude Mon, Sun and Sat,
  TRUE ~ 0                                # otherwise don't exclude more days
)

# Here we remove the last x days of data as they are not consolidated.
right_truncation <- list()
right_truncation[["Confirmed cases"]] <- 3 + additional_truncation

save(list = c("right_truncation", "max_date", "min_date", "linelist"), file = file.path(temp_data_dir, "latest_linelist.RData"))
