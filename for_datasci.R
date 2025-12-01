library(tidyverse)
library(here)

birdnet_results <- read_csv(here("Output/output_A022_SD019_no_list.csv"), guess_max = 10000)
problems(birdnet_results) |> print(n = Inf)

library(lubridate)
library(hms)

birdnet_long <- birdnet_results |> relocate(file) |>
  pivot_longer(4:ncol(birdnet_results), names_to = "species", values_to = "probability") |>
  mutate(date = str_sub(file, start = 1, end = 8),
          hour = str_sub(file, 10, 11),
          minute = str_sub(file, 12, 13),
          second = str_sub(file, 14, 15)) |>
  unite("date_time", c("date", "hour", "minute", "second"), sep = ":") |>
  mutate(date_time = ymd_hms(date_time),
          time = as_hms(date_time))

write.csv(birdnet_long, 
  "/Users/aidanfauth/Library/CloudStorage/OneDrive-St.LawrenceUniversity/SLU Senior/DataSci/DataSci_Code/data/AM_folder.csv")