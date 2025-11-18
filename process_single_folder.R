library(tidyverse)
library(here)

birdnet_results <- read_csv(here("Output/output_A022_SD019_no_list.csv"), guess_max = 10000)
problems(birdnet_results) |> print(n = Inf)

species_list <- read_delim(here("Species_lists/species_list.txt"), delim = "\n", col_names = FALSE)

View(birdnet_results)


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

birdnet_sightings <- birdnet_long |> filter(!is.na(probability))

birdnet_most_prob <- birdnet_sightings |> group_by(file, start, end) |>
  ## filter(probability == max(probability)) |>
  filter(probability >= 0.75) |> 
  ungroup() |> ## minimum probability to show in plot
  mutate(species = fct_infreq(species)) |>
  mutate(species = fct_rev(species))

birdnet_most_prob

ggplot(data = birdnet_most_prob, aes(x = time, y = species)) +
  geom_jitter(aes(colour = probability), alpha = 0.5, height = 0.25) +
  theme_minimal() +
  scale_colour_viridis_c()


anti_join(distinct(birdnet_sightings, species), 
species_list, join_by(species == X1)) |> print(n = 75)

