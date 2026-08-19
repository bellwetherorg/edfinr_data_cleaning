# 08_sparsity_clean.R
# Clean the Census Bureau Gazetteer school-district files into a tidy
# (ncesid, year) panel of district land area, the input for the sparsity
# (students per square mile) measure built in script 09.
#
# Gazetteer vintage Y maps to edfinr fiscal year Y: vintage boundaries are
# those in operation as of Jan 1 of calendar year Y, the middle of
# SY (Y-1)-Y -- the same school year the fiscal-year label denotes, so no
# year stagger is needed (unlike the CCD directory pull, where fy - 1 only
# translates Urban's fall-year labels). Each vintage ships three national
# files (unsd, elsd, scsd); a district appears in exactly one. GEOID is the
# 7-char NCES LEAID. ALAND_SQMI is used as published (land area only, water
# excluded); do not recompute from ALAND. See data/raw/gazetteer/SOURCES.md.

# load --------
library(tidyverse)
options(scipen = 999)

sparsity_years <- 2012:2023
sparsity_types <- c("unsd", "elsd", "scsd")

# GEOID read as character to preserve leading zeros. Early vintages are CRLF
# and space-pad the final column; read_tsv's default trim_ws handles both.
read_sparsity <- function(year, type) {
  path <- sprintf("data/raw/gazetteer/%d_Gaz_%s_national.txt", year, type)
  read_tsv(path, col_types = cols(.default = col_character())) |>
    transmute(
      ncesid = GEOID,
      year = as.integer(year),
      land_area_sq_mi = as.numeric(ALAND_SQMI)
    )
}

sparsity_fy12_fy23_clean <- expand_grid(
  year = sparsity_years,
  type = sparsity_types
) |>
  pmap(read_sparsity) |>
  list_rbind() |>
  # census "remainder of state" pseudo-districts; no F-33 district carries
  # these ids (same filter as scripts 04-06)
  filter(!str_detect(ncesid, "99999$")) |>
  arrange(ncesid, year)

# a duplicate (ncesid, year) means a district appeared in more than one of
# the three type files within a vintage -- stop, do not silently dedupe.
# zero land area is kept here (a true value for a handful of districts);
# script 09 turns it into NA sparsity rather than dividing by zero
stopifnot(
  anyDuplicated(sparsity_fy12_fy23_clean[c("ncesid", "year")]) == 0,
  all(is.finite(sparsity_fy12_fy23_clean$land_area_sq_mi)),
  all(sparsity_fy12_fy23_clean$land_area_sq_mi >= 0)
)

# write -----
write_rds(sparsity_fy12_fy23_clean, "data/processed/sparsity_fy12_fy23_clean.rds")
