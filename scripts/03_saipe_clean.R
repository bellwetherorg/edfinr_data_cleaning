# 03_saipe_clean.R

# load --------
library(tidyverse)
library(readxl)

options(scipen = 999)

# load FY12 SAIPE data
saipe_fy12_raw <- read_excel("data/raw/saipe/ussd12.xls",
  skip = 2
) |>
  mutate(year = "2012")

# load FY13 SAIPE data
saipe_fy13_raw <- read_excel("data/raw/saipe/ussd13.xls",
  skip = 2
) |>
  mutate(year = "2013")

# load FY14 SAIPE data
saipe_fy14_raw <- read_excel("data/raw/saipe/ussd14.xls",
  skip = 2
) |>
  mutate(year = "2014")

# load FY15 SAIPE data
saipe_fy15_raw <- read_excel("data/raw/saipe/ussd15.xls",
  skip = 2
) |>
  mutate(year = "2015")

# load FY16 SAIPE data
saipe_fy16_raw <- read_excel("data/raw/saipe/ussd16.xls",
  skip = 2
) |>
  mutate(year = "2016")

# load FY17 SAIPE data
saipe_fy17_raw <- read_excel("data/raw/saipe/ussd17.xls",
  skip = 2
) |>
  mutate(year = "2017")

# load FY18 SAIPE data
saipe_fy18_raw <- read_excel("data/raw/saipe/ussd18.xls",
  skip = 2
) |>
  mutate(year = "2018")

# load FY19 SAIPE data
saipe_fy19_raw <- read_excel("data/raw/saipe/ussd19.xls",
  skip = 2
) |>
  mutate(year = "2019")

# load FY20 SAIPE data
saipe_fy20_raw <- read_excel("data/raw/saipe/ussd20.xls",
  skip = 2
) |>
  mutate(year = "2020")

# load FY21 SAIPE data
saipe_fy21_raw <- read_excel("data/raw/saipe/ussd21.xls",
  skip = 2
) |>
  mutate(year = "2021")

# load FY22 SAIPE data
saipe_fy22_raw <- read_excel("data/raw/saipe/ussd22.xls",
  skip = 2
) |>
  mutate(year = "2022")

# load FY23 SAIPE data
saipe_fy23_raw <- read_excel("data/raw/saipe/ussd23.xls",
  skip = 2
) |>
  mutate(year = "2023")

# join ----

# create long df of raw data
saipe_fy12_fy23_raw <- bind_rows(
  saipe_fy12_raw, saipe_fy13_raw, saipe_fy14_raw,
  saipe_fy15_raw, saipe_fy16_raw, saipe_fy17_raw,
  saipe_fy18_raw, saipe_fy19_raw, saipe_fy20_raw,
  saipe_fy21_raw, saipe_fy22_raw, saipe_fy23_raw
)


# create cleaning function ---------
saipe_fy12_fy23_clean <- saipe_fy12_fy23_raw |>
  rename(
    state = "State Postal Code",
    state_id = "State FIPS Code",
    dist_id = "District ID",
    dist_name = Name,
    total_pop = "Estimated Total Population",
    student_pop = "Estimated Population 5-17",
    stpov_pop = "Estimated number of relevant children 5 to 17 years old in poverty who are related to the householder"
  ) |>
  # clean up district name formatting
  mutate(
    dist_name = str_to_title(dist_name),
    # make sure total and student population, and students in poverty enrollment are numeric
    total_pop = as.numeric(total_pop),
    student_pop = as.numeric(student_pop),
    stpov_pop = as.numeric(stpov_pop)
  ) |>
  mutate(stpov_pct = stpov_pop / student_pop) |>
  # create the ncesid
  mutate(ncesid = paste(state_id, dist_id, sep = "")) |>
  select(
    ncesid, year, state, dist_name, total_pop, student_pop, stpov_pop,
    stpov_pct
  )

# write data -----
write_rds(saipe_fy12_fy23_clean, "data/processed/saipe_fy12_fy23_clean.rds")
