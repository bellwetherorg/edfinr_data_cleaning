# 04_acs_unified_clean.R

# load --------
library(tidyverse)
library(tidycensus)

options(scipen = 999)

acs_vars <- c(
  mhi = "B19013_001", # median household income
  mpv = "B25077_001", # median property value
  pop_ba = "B15003_022", # adults 25+ w/ bachelors degree
  pop_ma = "B15003_023", # adults 25+ w/ masters degree
  pop_pro = "B15003_024", # adults 25+ w/ professional degree
  pop_phd = "B15003_025", # adults 25+ w/ doctorate
  pop_total = "B15003_001", # total 25+ population
  agg_hhi = "B19025_001", # aggregate household income
  households = "B11001_001", # total households
  gini = "B19083_001", # gini index of income inequality
  occ_total = "B25003_001", # occupied housing units
  occ_owner = "B25003_002", # owner-occupied housing units
  snap_total = "B22003_001", # households (snap universe)
  snap_hh = "B22003_002", # households receiving snap
  lf_civilian = "B23025_003", # civilian labor force
  unemp = "B23025_005" # unemployed civilians
)

state_list <- c(
  "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DC",
  "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA",
  "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN",
  "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM",
  "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI",
  "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", 
  "WV", "WI", "WY"
)

# pull 2012 acs data
acs_fy12_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  state = state_list,
  year = 2012
) |>
  mutate(year = "2012")


# pull 2013 acs data
acs_fy13_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  state = state_list,
  year = 2013
) |>
  mutate(year = "2013")


# pull 2014 acs data
acs_fy14_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  state = state_list,
  year = 2014
) |>
  mutate(year = "2014")

# pull 2015 acs data
acs_fy15_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  state = state_list,
  year = 2015
) |>
  mutate(year = "2015")


# pull 2016 acs data
acs_fy16_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  state = state_list,
  year = 2016
) |>
  mutate(year = "2016")



# pull 2017 acs data
acs_fy17_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  state = state_list,
  year = 2017
) |>
  mutate(year = "2017")



# pull 2018 acs data
acs_fy18_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  state = state_list,
  year = 2018
) |>
  mutate(year = "2018")

# pull the 2019 acs data
acs_fy19_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  state = state_list,
  year = 2019
) |>
  mutate(year = "2019")

# pull the 2020 acs data
acs_fy20_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  year = 2020,
  survey = "acs5"
) |>
  mutate(year = "2020")

# pull 2021 acs data
acs_fy21_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  year = 2021,
  survey = "acs5"
) |>
  mutate(year = "2021")

# pull 2022 acs data
acs_fy22_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  year = 2022,
  survey = "acs5"
) |>
  mutate(year = "2022")

# pull 2023 acs data
acs_fy23_raw <- get_acs(
  variables = acs_vars,
  geography = "school district (unified)",
  year = 2023,
  survey = "acs5"
) |>
  mutate(year = "2023")


# join data ------
acs_fy12_fy23_unified_raw <- bind_rows(
  acs_fy12_raw, acs_fy13_raw,
  acs_fy14_raw, acs_fy15_raw,
  acs_fy16_raw, acs_fy17_raw,
  acs_fy18_raw, acs_fy19_raw,
  acs_fy20_raw, acs_fy21_raw,
  acs_fy22_raw, acs_fy23_raw
)

# clean -------
acs_fy12_fy23_unified <- acs_fy12_fy23_unified_raw |>
  rename(
    ncesid = "GEOID",
    dist_name = NAME
  ) |>
  separate(dist_name, c("dist_name", "state"), sep = ",") |>
  select(-moe) |>
  mutate(
    dist_name = str_to_title(dist_name),
    estimate = as.numeric(estimate)
  ) |>
  pivot_wider(
    names_from = variable,
    values_from = estimate
  ) |> 
  mutate(
    ba_plus_pop = pop_ba + pop_ma + pop_pro + pop_phd,
    ba_plus_pct = ba_plus_pop / pop_total,
    adult_pop = pop_total,
    # acs has no direct mean household income table at the district level,
    # so derive it from aggregate income / households
    mean_hhi = agg_hhi / households,
    owner_pct = occ_owner / occ_total,
    snap_pct = snap_hh / snap_total,
    unemp_rate = unemp / lf_civilian
  ) |>
  select(
    ncesid:year, mhi, mean_hhi, mpv, adult_pop, ba_plus_pop, ba_plus_pct,
    gini, owner_pct, snap_pct, unemp_rate
  )

# export data -----
write_rds(acs_fy12_fy23_unified, "data/processed/acs_fy12_fy23_unified.rds")
