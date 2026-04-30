## modeling script for mod 1

library(tidyverse)
library(nlme)
library(mgcv)
library(hms)
library(broom)
library(modelr)

A001_SD001 <- readRDS("A001_SD001.rds") 
A002_SD013 <- readRDS("A002_SD013.rds")
A003_SD005 <- readRDS("A003_SD005.rds")
A004_SD012 <- readRDS("A004_SD012.rds")
A005_SD002 <- readRDS("A005_SD002.rds")
A006_SD006 <- readRDS("A006_SD006.rds")
A007_SD017 <- readRDS("A007_SD017.rds")
A008_SD007 <- readRDS("A008_SD007.rds")
A009_SD009 <- readRDS("A009_SD009.rds")
A010_SD014 <- readRDS("A010_SD014.rds")
A011_SD018 <- readRDS("A011_SD018.rds")
A013_SD016 <- readRDS("A013_SD016.rds")
A014_SD021 <- readRDS("A014_SD021.rds")
A015_SD010 <- readRDS("A015_SD010.rds")
A016_SD022 <- readRDS("A016_SD022.rds")
A017_SD024 <- readRDS("A017_SD024.rds")
A018_SD011 <- readRDS("A018_SD011.rds")
A019_SD008 <- readRDS("A019_SD008.rds")
A021_SD023 <- readRDS("A021_SD023.rds")
A022_SD019 <- readRDS("A022_SD019.rds")

eclipse_start<-hms(00,00,14)
eclipse_end<-hms(00,50,16)

full_audio <- rbind(A001_SD001, A002_SD013, A003_SD005, A004_SD012,
                    A005_SD002, A006_SD006, A007_SD017, A008_SD007,
                    A009_SD009, A010_SD014, A011_SD018, A013_SD016,
                    A014_SD021, A015_SD010, A016_SD022, A017_SD024,
                    A018_SD011, A019_SD008, A021_SD023, A022_SD019)|>
  group_by(folder_name)|>
  mutate(folder_name = as_factor(folder_name)) |>
  mutate(hour_numeric = as.numeric(hour))|>
  filter(hour>= eclipse_start & hour<= eclipse_end) |>
  filter(day %in% c("2024-04-06", "2024-04-07", "2024-04-08",
                    "2024-04-09", "2024-04-11")) |>
  mutate(audiomoth_day = interaction(folder_name, day))

mod1 = gamm(bei ~ s(hour_numeric, by = audiomoth_day, k = 15) +
              audiomoth_day,
            data = full_audio,
            correlation = corARMA(p = 1, q = 0, 
                                  form = ~ 1 | audiomoth_day))

saveRDS(mod1, file = "mod1.rds")