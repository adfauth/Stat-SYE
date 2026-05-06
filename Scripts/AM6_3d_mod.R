## 6 AM and 3 day model

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

# set up df
# 3 day span
day1 <- ymd_hms("2024-04-07 00:00:00")
day3 <- ymd_hms("2024-04-9 23:59:59")

# eclipse time: 15:25:30
time_start <- as_hms("14:55:30")
time_end <- as_hms("15:55:30")

mult_AMs <- c("AM0001", "AM0011", "AM0017", "AM0002", "AM0009", "AM0020")

AM_6_3d <- cleaned |> filter(deployment_num %in% mult_AMs) |> 
  filter(between(time, time_start, time_end)) |>
  filter(day1 <= date_time & date_time <= day3) |>
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
      ungroup()

AM_6_3d <- AM_6_3d |> mutate(day = as_factor(day(date)),
audiomoth_day = interaction(deployment_num, day))

AM_6_3d$time_num <- as.numeric(AM_6_3d$time)

AM_6_3d_mod <- gamm(Presence ~ s(time_num, by = audiomoth_day) + audiomoth_day,
                   family = binomial,
                   data = AM_6_3d,
                   correlation = corAR1(form = ~ 1 | audiomoth_day))

# save model as .rda
save(AM_6_3d_mod, file = "AM_6_3d_mod.rda")

# save model as .rds
saveRDS(AM_6_3d_mod, file = "AM_6_3d_mod.rds")