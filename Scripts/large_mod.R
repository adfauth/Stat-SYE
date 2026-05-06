## Modeling All Days and AMs

rm(list = ls())
library(tidyverse)
library(here)
library(nlme)
library(mgcv)
library(hms) 
merged_df <- read_csv("merged_output_deployment_filtered.csv")

# filter out anthroprogenic noise
anthro <- c("Fireworks_Fireworks", "Siren_Siren", "Engine_Engine", "Gun_Gun", 
  "Human vocal_Human vocal", "Human non-vocal_Human non-vocal", "Dog_Dog")

cleaned <- merged_df |> filter(!(species %in% anthro)) 

# 5 day span
day1 <- ymd_hms("2024-04-06 00:00:00")
day5 <- ymd_hms("2024-04-10 23:59:59")

# eclipse time: 15:25:30
time_start <- as_hms("14:55:30")
time_end <- as_hms("15:55:30")

# set up df for all days and all AMs
full_df <- cleaned |> 
  filter(between(time, time_start, time_end)) |>
  filter(day1 <= date_time & date_time <= day5) |>
  mutate(date = as_date(date_time)) |> 
  group_by(deployment_num, date) |> # want to complete the gaps for each site/AM
  complete(time = as_hms(seq(as.numeric(time_start), as.numeric(time_end), by = 3)), 
  fill = list(value = NA)) |> 
    ungroup() |> 
    mutate(Presence = if_else(!is.na(probability),
    true = 1,
    false = 0)) |> 
      relocate(Presence, probability) |> 
      filter(seconds(time) != 57) |> 
      group_by(deployment_num, date) |> 
      distinct(time, .keep_all = TRUE) |> # get rid of any species at the same timestamp
      ungroup() |> 
  mutate(day = as_factor(day(date)),
    audiomoth_day = interaction(deployment_num, day))

full_df$time_num <- as.numeric(full_df$time)

full_mod <- gamm(Presence ~ s(time_num, by = audiomoth_day) + audiomoth_day,
                   family = binomial,
                   data = full_df,
                   correlation = corAR1(form = ~ 1 | audiomoth_day))

# save model as .rda
save(full_mod, file = "full_mod.rda")

# save model as .rds
saveRDS(full_mod, file = "full_mod.rds")

