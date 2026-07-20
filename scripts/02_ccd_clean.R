# ccd_clean.R

# load --------
library(tidyverse)
library(educationdata)

options(scipen = 999)

# download ccd directory data ----
# 2012 education data
dir_sy12_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2012")
)

# 2013 directory data
dir_sy13_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2013")
)

# 2014 directory data
dir_sy14_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2014")
)

# 2015 directory data
dir_sy15_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2015")
)

# 2016 directory data
dir_sy16_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2016")
)

# 2017 directory data
dir_sy17_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2017")
)

# 2018 directory data
dir_sy18_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2018")
)

# 2019 directory data
dir_sy19_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2019")
)

# 2020 directory data
dir_sy20_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2020")
)

# 2021 directory data
dir_sy21_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2021")
)

# 2022 directory data
dir_sy22_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2022")
)

# 2023 directory data
dir_sy23_raw <- get_education_data(
  level = "school-districts",
  source = "ccd",
  topic = "directory",
  filters = list(year = "2023")
)

# join data ----
dir_sy12_sy23_raw <- bind_rows(
  dir_sy12_raw, dir_sy13_raw,
  dir_sy14_raw, dir_sy15_raw,
  dir_sy16_raw, dir_sy17_raw,
  dir_sy18_raw, dir_sy19_raw,
  dir_sy20_raw, dir_sy21_raw,
  dir_sy22_raw, dir_sy23_raw
)

# write raw file for cleaning later ----
# write_rds(dir_sy12_sy23_raw, "data/raw/dir_sy12_sy23_raw.rds")

# clean ---------
dir_sy12_sy23 <- dir_sy12_sy23_raw |>
  rename(
    state = state_mailing,
    ncesid = leaid,
    dist_name = lea_name,
    urbanicity_id = urban_centric_locale,
    cong_dist = congress_district_id,
    county = county_name,
    school_count = number_of_schools,
    enroll = enrollment,
    sped_enroll = spec_ed_students,
    ell_enroll = english_language_learners,
    total_teachers_fte = teachers_total_fte,
    lea_type_id = agency_type,
    charter_id = agency_charter_indicator
  ) |>
  # clean up district name formatting
  mutate(
    dist_name = str_to_title(dist_name),
    county = str_to_title(county),
    # make sure total enrollment, sped enrollment, and
    # ell enrollment is a numeric variable
    enroll = as.numeric(enroll),
    sped_enroll = as.numeric(sped_enroll),
    ell_enroll = as.numeric(ell_enroll)
  ) |>
  # keep raw 12-code nces locale and its subcategory label
  mutate(
    urbanicity_raw = as.integer(urbanicity_id),
    urbanicity_raw_cat = fct_collapse(as.factor(urbanicity_id),
      "City, Large" = "11",
      "City, Midsize" = "12",
      "City, Small" = "13",
      "Suburb, Large" = "21",
      "Suburb, Midsize" = "22",
      "Suburb, Small" = "23",
      "Town, Fringe" = "31",
      "Town, Distant" = "32",
      "Town, Remote" = "33",
      "Rural, Fringe" = "41",
      "Rural, Distant" = "42",
      "Rural, Remote" = "43"
    )
  ) |>
  # create simple urbanicity categories
  mutate(urbanicity = fct_collapse(as.factor(urbanicity_id),
    City = c(
      "11",
      "12",
      "13"
    ),
    Suburb = c(
      "21",
      "22",
      "23"
    ),
    Town = c(
      "31",
      "32",
      "33"
    ),
    Rural = c(
      "41",
      "42",
      "43"
    )
  )) |>
  # Create the label for district type
  mutate(lea_type = fct_collapse(as.factor(lea_type_id),
    "Regular public school district that is not a component of a supervisory union" = "1",
    "Regular public school district that is a component of a supervisory union" = "2",
    "Supervisory union" = "3",
    "Service agency" = "4",
    "State-operated agency" = "5",
    "Federally-operated agency" = "6",
    "Independent charter district" = "7",
    "Other local education agency" = "8",
    "Specialized public school district" = "9"
  )) |>
  # create label for charter status
  mutate(
    charter_status = fct_collapse(as.factor(charter_id),
      "All associated schools are charter schools" = "1",
      "Some but not all associated schools are charters schools" = "2",
      "No associated schools are charter schools" = "3"
    ),
    charter_status = fct_na_level_to_value(charter_status, "-2")
  ) |>
  select(
    year, ncesid, state, county, dist_name, state_leaid,
    lea_type, lea_type_id, charter_status, charter_id,
    urbanicity_raw, urbanicity_raw_cat, urbanicity, cong_dist,
    total_teachers_fte, school_count,
    enroll, sped_enroll, ell_enroll
  )


# write -----
write_rds(dir_sy12_sy23, "data/processed/dir_sy12_sy23.rds")
