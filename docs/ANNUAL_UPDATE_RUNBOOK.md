# Annual Update Runbook

How to add a new fiscal year to the edfinr panel and release it. Written
July 2026 against the FY2012-FY2023 (0.2) pipeline; the FY2024 update is the
first consumer. Fiscal year notation: FY2024 = SY 2023-24. F-33 lags roughly
two years, so expect the FY2024 files in the 2026 release cycle.

## Prerequisites

- Raw F-33 district file in `data/raw/ccd/` (pattern: `sdf24_1a.txt`) plus
  its documentation PDF in `data/raw/ccd_documentation/`.
- SAIPE workbook `ussd24.xls` in `data/raw/saipe/`, downloaded from the
  Census SAIPE school district page.
- BLS CPI-U extract covering the new year's HALF1/HALF2 values. The current
  extract runs through 2024, which covers FY2024; FY2025 will need a fresh
  pull from the BLS series `CUUR0000SA0`.
- New NCES EDGE CWIFT release folder in `data/raw/cwift/` if one exists
  (record it in `data/raw/cwift/SOURCES.md`).
- Network access and a `CENSUS_API_KEY` for the tidycensus (ACS) pulls; the
  CCD directory pull uses the Urban `educationdata` API.

## Script changes, in pipeline order

1. **`01_f33_clean.R`**: add a per-year cleaning function for the new file.
   Start from the most recent year's function and diff the new raw file's
   header first; item availability has changed over time (CE3 from SY18,
   AE1-AE8 expanding FY20-FY21). Do not add the nine revenue-adjustment
   inputs to `f33_flag_aware_items` (see `FLAGGED_ZERO_NA_HANDLING.md`).
2. **`02_ccd_clean.R`**: extend `map(2012:2023, get_dir_fy)` to the new
   year. The function requests Urban year `fy - 1`; do not "fix" that
   offset (see `CCD_DIRECTORY_YEAR_ALIGNMENT.md`).
3. **`03_saipe_clean.R`**: add a load block for the new workbook and add it
   to the `bind_rows`.
4. **`04/05/06_acs_*_clean.R`**: add a pull block per script. Recent-year
   pulls omit the `state` argument (nationwide, includes Puerto Rico; inert
   under the F-33 left join).
5. **`07_cwift_clean.R`**: if NCES published a new CWIFT, add it as
   observed and remove or roll forward the carry-forward block at the end
   of the script (its own header documents this). If not, extend the
   carry-forward and keep `cwift_imputed` flagging it.
6. **`08_edfinr_join_and_exclude.R`**: no year edits needed. The CPI
   exclusion thresholds join by year, the per-year export loop adapts, and
   the MA rescue is frozen to FY2012-FY2015.

## Behaviors to expect on every update

- **The previous latest year revises.** The following-vintage LEA-type
  screen is inert for the newest year (no next vintage exists yet), so
  adding FY2025's directory will slightly change FY2024's LEA-type
  exclusions. Small row-count changes in the prior latest year are
  expected, not a defect.
- **Built-in assertions in script 08** will stop the run on: a stale or
  truncated F-33 input (NYC canary), duplicate `(ncesid, year)` keys in the
  F-33 or ACS inputs, a directory match rate at or below 97% (the classic
  symptom of a year-alignment mistake), or the MA rescue invariant (238
  rows) drifting. If the MA assertion fails, NCES has revised historical
  files; re-vet against `MA_REGIONAL_RESCUE.md` before touching the
  expected count.
- **F-33 documentation drift.** Skim the new year's release notes for
  item-definition changes before trusting the copy-paste mapping; the CE
  and AE items have changed availability more than once.

## Run and verify

```bash
Rscript -e 'source("scripts/run_all.R")'
```

Run from the project root. `data/processed/` is gitignored; `run_all.R`
creates the output tree.

Verification beyond the built-in assertions, before anything ships:

- Compare row counts by year against the previously published S3 files
  (`https://edfinr-tidy-data.s3.us-east-2.amazonaws.com/`); the new year
  should add roughly 18-19k rows and earlier years should move only where a
  known fix explains it (latest-year revision above).
- Spot-check a handful of large districts (NYC, LA Unified, Chicago) for
  revenue continuity into the new year; a unit or alignment error shows up
  there immediately.
- Check the new year's `NA` shares in the COVID/capital/debt columns
  against the prior year; a collapse to all-zero or all-NA in a column
  usually means a flag-mapping miss in script 01.

## Release

1. Upload the regenerated `edfinr_data_fy12_fy23_full.parquet` and
   `_skinny.parquet` (names will roll forward with the year range) and the
   `by_year/` slices to the `edfinr-tidy-data` S3 bucket.
2. Update the edfinr package side: the package reconstructs factor columns
   on read and downloads per-year slices, so year-range constants and
   documentation there need the new year.
3. Update the README here: year ranges, any new columns, and the data notes
   if reporting patterns changed.
4. State the vintage plainly in any announcement: F-33 lags about two
   years; never present the newest fiscal year as current-year finance.
