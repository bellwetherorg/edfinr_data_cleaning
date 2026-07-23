# ccd_clean.R

# load --------
library(tidyverse)
library(educationdata)

options(scipen = 999)

# download ccd directory data ----
# Download one fiscal year of CCD directory data. Urban educationdata labels
# directory years by the FALL of the school year (2011 = SY 2011-12), while
# this pipeline labels years by the fiscal year, i.e. the LAST year of the
# school year (2012 = SY 2011-12). Request Urban year fy - 1, then re-label
# so the year column joins correctly against F-33.
get_dir_fy <- function(fy) {
  get_education_data(
    level = "school-districts",
    source = "ccd",
    topic = "directory",
    filters = list(year = as.character(fy - 1))
  ) |>
    mutate(year = fy)
}

dir_sy12_sy23_raw <- map(2012:2023, get_dir_fy) |> list_rbind()

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
