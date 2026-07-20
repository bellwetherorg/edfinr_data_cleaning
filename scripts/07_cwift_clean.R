# 07_cwift_clean.R
# Clean the NCES EDGE Comparable Wage Index for Teachers (CWIFT) LEA files into
# a tidy (ncesid, year) panel for the edfinr finance data.
#
# CWIFT<yyyy> maps directly to edfinr fiscal year yyyy. Coverage:
#   - FY2012-FY2014: no NCES release -> no rows here (the downstream left join
#     yields NA for all four CWIFT columns)
#   - FY2015-FY2019, FY2021, FY2022: observed NCES releases
#   - FY2020: NCES published no CWIFT2020 (the Census Bureau withheld the ACS
#     2020 1-year estimates for COVID-19 data-quality reasons), so FY2020 is
#     INTERPOLATED as the mean of FY2019 and FY2021 -- for LEAs present in both
#     neighbor years only
#   - FY2023: no CWIFT2023 release exists as of the live-check date below, so
#     FY2022 is CARRIED FORWARD and flagged. When NCES posts a CWIFT2023 release,
#     add it to `cwift_releases` and delete the carry-forward block.
#
# FY2023 release live-check: 2026-07-20 -- the most recent NCES EDGE release is
# CWIFT2022 (https://nces.ed.gov/programs/edge/Economic/TeacherWage). See
# data/raw/cwift/SOURCES.md.

# load --------
library(tidyverse)
options(scipen = 999)

# Explicit release table. Folder/file naming is inconsistent across releases
# (e.g. the 2015 file lacks the EDGE_ACS prefix; the 2017 folder has an extra
# underscore), so map each observed edfinr year to its LEA file path rather than
# relying on a glob.
cwift_releases <- tribble(
  ~year, ~path,
  2015L, "data/raw/cwift/EDGE_ACS_CWIFT2015/CWIFT2015_LEA1314.txt",
  2016L, "data/raw/cwift/EDGE_ACS_CWIFT2016/EDGE_ACS_CWIFT2016_LEA1516.txt",
  2017L, "data/raw/cwift/EDGE_ACS_CWIFT_2017/EDGE_ACS_CWIFT2017_LEA1718.txt",
  2018L, "data/raw/cwift/EDGE_ACS_CWIFT2018/EDGE_ACS_CWIFT2018_LEA1819.txt",
  2019L, "data/raw/cwift/EDGE_ACS_CWIFT2019/EDGE_ACS_CWIFT2019_LEA1920.txt",
  2021L, "data/raw/cwift/EDGE_ACS_CWIFT2021/EDGE_ACS_CWIFT2021_LEA2122.txt",
  2022L, "data/raw/cwift/EDGE_ACS_CWIFT2022/EDGE_ACS_CWIFT2022_LEA2223.txt"
)

# read one release LEA file -> tidy observed rows. LEAID is read as character to
# preserve leading zeros; latin1 handles the occasional non-UTF-8 LEA name.
read_cwift <- function(year, path) {
  read_tsv(path, col_types = cols(.default = col_character()),
           locale = locale(encoding = "latin1")) |>
    transmute(
      ncesid = LEAID,
      year = as.integer(year),
      cwift_est = as.numeric(LEA_CWIFTEST),
      cwift_se = as.numeric(LEA_CWIFTSE)
    ) |>
    # drop rows without a usable estimate (blanks, suppressed values, footers)
    filter(!is.na(ncesid), !is.na(cwift_est))
}

cwift_observed <- pmap(cwift_releases, read_cwift) |>
  list_rbind() |>
  mutate(cwift_imputed = FALSE, cwift_impute_method = "observed")

# FY2020: interpolate as the mean of FY2019 and FY2021, for LEAs present in BOTH
# neighbor years only. The interpolated standard error is a simple approximation
# (the mean of the two neighbor SEs) -- it is NOT an NCES-published quantity and
# is documented as such in SOURCES.md / the README.
cwift_2020 <- cwift_observed |>
  filter(year %in% c(2019L, 2021L)) |>
  select(ncesid, year, cwift_est, cwift_se) |>
  pivot_wider(names_from = year, values_from = c(cwift_est, cwift_se)) |>
  filter(!is.na(cwift_est_2019), !is.na(cwift_est_2021)) |>
  transmute(
    ncesid,
    year = 2020L,
    cwift_est = (cwift_est_2019 + cwift_est_2021) / 2,
    cwift_se = (cwift_se_2019 + cwift_se_2021) / 2,
    cwift_imputed = TRUE,
    cwift_impute_method = "interpolated_2019_2021"
  )

# FY2023: no CWIFT2023 release as of the live-check date -> carry FY2022 forward,
# flagged (only for LEAs present in FY2022).
cwift_2023 <- cwift_observed |>
  filter(year == 2022L) |>
  transmute(
    ncesid,
    year = 2023L,
    cwift_est,
    cwift_se,
    cwift_imputed = TRUE,
    cwift_impute_method = "carried_forward_2022"
  )

cwift_lea_clean <- bind_rows(cwift_observed, cwift_2020, cwift_2023) |>
  arrange(ncesid, year)

# assertions: unique (ncesid, year) key; every retained estimate is finite
stopifnot(
  anyDuplicated(cwift_lea_clean[c("ncesid", "year")]) == 0,
  all(is.finite(cwift_lea_clean$cwift_est))
)

# write -----
write_rds(cwift_lea_clean, "data/processed/cwift_lea_clean.rds")
