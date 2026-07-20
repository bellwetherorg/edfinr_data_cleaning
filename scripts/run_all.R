# run_all.R
# Run the full edfinr data-prep pipeline (00-08) in order, writing all
# processed .rds outputs to data/processed/. Currently covers FY2012-FY2023.
#
# Prerequisites:
#   - Raw F-33 CCD SDF files in data/raw/ccd/ (latest: sdf23_1a.txt)
#   - Raw SAIPE files in data/raw/saipe/ (latest: ussd23.xls) -- downloaded
#     manually from the Census SAIPE school district datasets page
#   - BLS CPI-U extract in data/raw/cpi/ (already spans the needed years)
#   - NCES EDGE CWIFT release folders in data/raw/cwift/ (see SOURCES.md)
#   - Network access for the CCD directory (educationdata) and ACS
#     (tidycensus) pulls; tidycensus needs a CENSUS_API_KEY
#
# Run from the project root so the relative data/ paths resolve.

scripts <- c(
  "scripts/00_cpi_clean.R",
  "scripts/01_f33_clean.R",
  "scripts/02_ccd_clean.R",
  "scripts/03_saipe_clean.R",
  "scripts/04_acs_unified_clean.R",
  "scripts/05_acs_elementary_clean.R",
  "scripts/06_acs_secondary_clean.R",
  "scripts/07_cwift_clean.R",
  "scripts/08_edfinr_join_and_exclude.R"
)

for (script in scripts) {
  message("\n=== Running ", script, " ===")
  source(script, echo = FALSE)
}

message("\n=== Pipeline complete ===")
