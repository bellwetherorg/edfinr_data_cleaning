# Census Gazetteer Data Sources

U.S. Census Bureau **Gazetteer Files** (school-district series) used by
`scripts/08_sparsity_clean.R` to build district land area and sparsity
(students per square mile).

- Program page: <https://www.census.gov/geographies/reference-files/time-series/geo/gazetteer-files.html>
- Record layouts: <https://www.census.gov/programs-surveys/geography/technical-documentation/records-layout/gaz-record-layouts.html>
- Download index: <https://www2.census.gov/geo/docs/maps-data/data/gazetteer/>

Gazetteer vintage `yyyy` maps to edfinr fiscal year `yyyy`: each vintage
reflects district boundaries in operation as of January 1 of calendar year
`yyyy` (sourced from the School District Review Program), which falls in the
middle of SY `yyyy-1`–`yyyy` — the same school year the fiscal-year label
denotes. No year offset is applied.

## Files present

`{yyyy}_Gaz_{type}_national.txt` for `yyyy` = 2012–2023, one file per school
district type:

| Type | Contents |
|---|---|
| `unsd` | Unified school districts (all 50 states + DC + PR) |
| `elsd` | Elementary school districts (dual-district states) |
| `scsd` | Secondary school districts (dual-district states) |

A district appears in exactly one of the three files within a vintage;
`08_sparsity_clean.R` stops on any cross-file duplicate. Files were
downloaded from the index above in August 2026 and are byte-for-byte as
distributed by Census.

## Format

Tab-delimited, one header row, identical columns across years and types:
`USPS`, `GEOID`, `NAME`, `LOGRADE`, `HIGRADE`, `ALAND`, `AWATER`,
`ALAND_SQMI`, `AWATER_SQMI`, `INTPTLAT`, `INTPTLONG`.

- `GEOID` is the 7-character NCES LEAID (state FIPS + 5-digit LEA number);
  it must be read as character to preserve leading zeros.
- `ALAND_SQMI` (land area in square miles, water excluded) is used as
  published; `ALAND`/`AWATER` are square meters and are not used.
- Early vintages (through ~2015) have CRLF line endings and space-pad rows
  to a fixed width, leaving trailing whitespace on the final column;
  `read_tsv()`'s default `trim_ws` handles both.
- Each state's `XX99999` "remainder of state" pseudo-district rows are
  filtered out during cleaning.

## Known coverage gaps

- **Vermont, vintages 2016–2021:** during the Act 46 reorganization era the
  Census universe for VT listed supervisory unions (~61 rows) while F-33
  reported the underlying union/joint districts, so most VT LEAIDs in those
  fiscal years have no boundary row in any of the three files (verified
  against the Census download index — no VT-specific or "administrative"
  file exists for these vintages). VT matches at ~97%+ in 2012–2015 and
  2022–2023, once the Census universe caught up to the post-Act 46 unified
  districts.
- A handful of state-operated entities typed as regular districts in the
  CCD directory (LA Recovery School District, NV Achievement School
  District, DE county vo-tech overlay districts, LA Central Community
  School District) have no Census boundary and resolve to `NA`.
