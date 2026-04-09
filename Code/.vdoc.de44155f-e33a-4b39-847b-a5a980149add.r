#
#
#
#
#
#
#
#
#| warning: false
#| output: false
rm(list = ls())
library(tidyverse)
library(here)
library(nlme)
library(mgcv)
library(forecast)
library(hms) 
merged_df <- read_csv(here("Data/merged_output_deployment.csv"))
#
#
#
#
#
merged_df <- merged_df |> 
    mutate(date_time = date_time + seconds(start),
    time = as_hms(time + start))
#
#
#
#
#
#
#
#
#
#
#
#
#
# eclipse time: 15:25:30
time_start <- as_hms("14:55:30")
time_end <- as_hms("15:55:30")

AM0011_all_sp <- merged_df |> filter(as_date(date_time) == "2024-04-08" & deployment_num == "AM0011") |>   
    filter(between(time, time_start, time_end)) |>
  complete(time = as_hms(seq(as.numeric(time_start), as.numeric(time_end), by = 3)), 
  fill = list(value = NA)) |> 
    ungroup() |> 
    mutate(Presence = if_else(!is.na(probability),
    true = 1,
    false = 0)) |> 
      relocate(Presence, probability) |> 
      filter(seconds(time) != 57)
#
#
#
#
#
#
#
ts_AM0011 <- ts(AM0011_all_sp$Presence, start = 53730, end = 57330, deltat = 3)
Acf(ts_AM0011)
Pacf(ts_AM0011)
#
#
#
#
#
#
#
# some timestamps have multiple species (need to get rid of duplicates)
AM0011_all_sp <- AM0011_all_sp |> distinct(time, .keep_all = TRUE)

# need time variable to be numeric:
AM0011_all_sp$time_num <- as.numeric(AM0011_all_sp$time)

AM0011_mod <- gamm(Presence ~ s(time_num), data = AM0011_all_sp, family = binomial, correlation = corAR1(form = ~ time_num))
summary(AM0011_mod$gam)
plot(AM0011_mod$gam)
#
#
#
#
#
resids_AM0011 <- residuals(AM0011_mod$lme)
Acf(resids_AM0011)
#
#
#
#
#
#
#
#
#
#
# eclipse time: 15:25:30
time_start <- as_hms("14:55:30")
time_end <- as_hms("15:55:30")

all_sites <- merged_df |> filter(as_date(date_time) == "2024-04-08") |> 
    filter(between(time, time_start, time_end)) |>
    group_by(deployment_num) |> # want to complete the gaps for each site/AM
    complete(time = as_hms(seq(as.numeric(time_start), as.numeric(time_end), by = 3)), 
    fill = list(value = NA)) |> 
    ungroup() |> 
    mutate(Presence = if_else(!is.na(probability),
    true = 1,
    false = 0)) |> 
      relocate(Presence, probability) |> 
      filter(seconds(time) != 57) |> 
    distinct(time, .keep_all = TRUE) # get rid of any species at the same timestamp
#
#
#
#
#
# 1. Ensure site is a factor and data is sorted
all_sites$deployment_num <- as.factor(all_sites$deployment_num)

# 2. Create the within-site observation order to avoid duplicate timestamp errors
all_sites <- all_sites |> 
  group_by(deployment_num) |> 
  mutate(obs_order = row_number()) |> 
  ungroup()

all_sites$time_num <- as.numeric(all_sites$time)

# 3. Fit the model
all_sites_mod <- gamm(Presence ~ s(time_num, by = deployment_num) + deployment_num,
                   family = binomial,
                   data = all_sites,
                   correlation = corAR1(form = ~ obs_order | deployment_num))
summary(all_sites_mod$gam)
plot(all_sites_mod$gam)
#
#
#
#
#
#
#
#
#
#
#
#
#
grid <- expand_grid(deployment_num = unique(all_sites$deployment_num),
                     time_num = unique(all_sites$time_num))

library(broom)

predictions_df <- augment(all_sites_mod$gam, newdata = grid) |>
  mutate(.fitted_prob = exp(.fitted) / (1 + exp(.fitted)))

ggplot(data = predictions_df, aes(x = time_num, y = .fitted)) +
  geom_line() +
  facet_wrap(~deployment_num)

ggplot(data = predictions_df, aes(x = time_num, y = .fitted_prob)) +
  geom_line() +
  facet_wrap(~deployment_num)
#
#
#
#
#
#
#
# 5 day span
day1 <- ymd_hms("2024-04-06 00:00:00")
day5 <- ymd_hms("2024-04-10 23:59:59")

# eclipse time: 15:25:30
time_start <- as_hms("14:55:30")
time_end <- as_hms("15:55:30")

five_day <- merged_df |> 
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
      group_by(deployment_num)
      distinct(date_time, .keep_all = TRUE) |> # get rid of any species at the same timestamp
      ungroup()
#
#
#
#
#
#
five_day <- five_day |> mutate(day = as_factor(day(date)),
audiomoth_day = interaction(deployment_num, day))

five_day$time_num <- as.numeric(five_day$time)

five_day <- five_day|> 
  group_by(deployment_num) |> 
  mutate(obs_order = row_number()) |> 
  ungroup()

five_d_mod <- gamm(Presence ~ s(time_num, by = audiomoth_day) + audiomoth_day,
                   family = binomial,
                   data = five_day,
                   correlation = corAR1(form = ~ 1 | audiomoth_day))
summary(_mod$gam)
plot(five_d_mod$gam)
#
#
#
#
#
