# CWIFT Data Sources

NCES EDGE **Comparable Wage Index for Teachers (CWIFT)** LEA-level releases used
by `scripts/07_cwift_clean.R`.

- Program page: <https://nces.ed.gov/programs/edge/Economic/TeacherWage>
- File documentation: `EDGE_ACS_CWIFT_FILEDOC.pdf` (in this folder)

`CWIFT<yyyy>` maps to edfinr fiscal year `yyyy`. Each release's LEA file has the
same columns: `LEAID`, `LEA_NAME`, `ST_NAME`, `LEA_CWIFTEST`, `LEA_CWIFTSE`.

## Releases present

| edfinr year | Release | LEA file | Source |
|---|---|---|---|
| 2015 | CWIFT2015 | `EDGE_ACS_CWIFT2015/CWIFT2015_LEA1314.txt` | NCES EDGE |
| 2016 | CWIFT2016 | `EDGE_ACS_CWIFT2016/EDGE_ACS_CWIFT2016_LEA1516.txt` | NCES EDGE |
| 2017 | CWIFT2017 | `EDGE_ACS_CWIFT_2017/EDGE_ACS_CWIFT2017_LEA1718.txt` | NCES EDGE |
| 2018 | CWIFT2018 | `EDGE_ACS_CWIFT2018/EDGE_ACS_CWIFT2018_LEA1819.txt` | NCES EDGE |
| 2019 | CWIFT2019 | `EDGE_ACS_CWIFT2019/EDGE_ACS_CWIFT2019_LEA1920.txt` | NCES EDGE |
| 2021 | CWIFT2021 | `EDGE_ACS_CWIFT2021/EDGE_ACS_CWIFT2021_LEA2122.txt` | NCES EDGE |
| 2022 | CWIFT2022 | `EDGE_ACS_CWIFT2022/EDGE_ACS_CWIFT2022_LEA2223.txt` | NCES EDGE |

These release folders were already present in the repository (downloaded from the
NCES EDGE program page above); exact original download dates were not recorded.
All files are byte-for-byte as distributed by NCES.

## Imputed / non-observed years

- **FY2012–FY2014:** no NCES CWIFT release exists (the series begins with
  CWIFT2015). These years have no rows in the cleaned file and resolve to `NA`
  on the downstream join.
- **FY2020:** NCES published no CWIFT2020 — the Census Bureau withheld the ACS
  2020 1-year estimates due to COVID-19 data-collection/quality concerns.
  `07_cwift_clean.R` interpolates FY2020 as the mean of FY2019 and FY2021 for
  LEAs present in both neighbor years. The interpolated `cwift_se` is a simple
  approximation (mean of the two neighbor SEs) and is **not** an NCES-published
  standard error.
- **FY2023:** **live-checked 2026-07-20** — the most recent NCES EDGE release is
  CWIFT2022; no CWIFT2023 edition is available. FY2023 is therefore carried
  forward from FY2022 and flagged (`cwift_impute_method = "carried_forward_2022"`).
  When NCES posts a CWIFT2023 release, add it to the `cwift_releases` table in
  `07_cwift_clean.R` and remove the carry-forward block.
