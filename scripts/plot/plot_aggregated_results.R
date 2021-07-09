library(ggplot2)
library(here)
library(readr)
library(dplyr)

results_dir <- here::here("data", "results", "aggregated")
results_file <- "2021-07-08_swiss-estimates.csv"

CH_estimates <- read_csv(file.path(results_dir, results_file))

ggplot(CH_estimates %>% filter(region == "CH"), aes(x = date, y = Re_estimate)) +
  geom_line(lwd=  1.1) +
  geom_ribbon(aes(x = date, ymax = CI_up_Re_estimate, ymin = CI_down_Re_estimate,), alpha = 0.45, colour = NA) +
  scale_x_date(date_breaks = "2 weeks",
               date_labels = '%b-%d\n%Y') +
  ylab("Reproductive number") +
  coord_cartesian(ylim = c(0, 3.5)) +
  xlab("") +
  theme_bw()


cantons_to_look_at <- c("ZG", "TI", "GR", "VD", "SG")
ggplot(CH_estimates %>% filter(region %in% cantons_to_look_at), aes(x = date, y = Re_estimate)) +
  geom_line(aes(colour=region), lwd=  1.1) +
  geom_ribbon(aes(x = date, ymax = CI_up_Re_estimate, ymin = CI_down_Re_estimate,fill=region), alpha = 0.15, colour = NA) +
  scale_x_date(date_breaks = "2 weeks",
               date_labels = '%b-%d\n%Y') +
  ylab("Reproductive number") +
  coord_cartesian(ylim = c(0, 3.5)) +
  xlab("") +
  theme_bw()

