# 00_cpi_clean.R

# load ---------------------------------
library(tidyverse)
library(readxl)
library(janitor)

# raw excel file sourced from https://data.bls.gov/toppicks?survey=cu
# selected "U.S. city average, All items - CUUR0000SA0" and then "Retrieve Data"
# includes monthly cpi data from 1990-2024
cpi_index_raw <- read_excel("data/raw/cpi/SeriesReport-20250417115228_1de8e6.xlsx",
  skip = 11
)

# Creating school-year CPI multiplier for adjusting to 2021 dollars -----


cpi_index_9024 <- cpi_index_raw |>
  rename(year = Year) |>
  arrange(year) |>
  # Need to move the half lag2 for the previous year into the current year
  # because school years take place during half one one year and first half
  # of the second year
  mutate(HALF2_lagged = lag(HALF2)) |>
  # create average of current year HALF1 and lagged HALF2 from prior year
  mutate(avg_HALF1_HALF2lag = (HALF1 + HALF2_lagged) / 2)

cpi_exclusions_sy12 <- cpi_index_9024 |>
  filter(year >= 2012) |>
  # create 2012 SY dollar index col
  mutate(sy12_index = avg_HALF1_HALF2lag[year == 2012]) |>
  # create cpi adj where 20127 == 1
  mutate(cpi_sy12 = avg_HALF1_HALF2lag / sy12_index) |>
  # create low and high exclusion values: $500 and $50000 in 2012 USD
  mutate(
    exclude_lo = round_half_up(500 * cpi_sy12, digits = 2),
    exclude_hi = round_half_up(70000 * cpi_sy12, digits = 2)
  ) |>
  select(year, cpi_sy12, exclude_lo, exclude_hi) |>
  # convert year to character for joining purposes
  mutate(year = as.character(year))

# write cpi exclusions df -------
write_rds(cpi_exclusions_sy12, "data/processed/cpi_exclusions_sy12.rds")
