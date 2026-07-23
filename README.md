# `edfinr` Data Processing and Notes

Convert raw data into a clean .rds file for the `edfinr` package

## Data Sources

-   [NCES CCD F-33 Data](https://nces.ed.gov/ccd/files.asp)
-   NCES CCD Directory Data via the [Urban Institute's `educationdata`
    package](https://educationdata.urban.org/documentation/#r)
-   [Census Bureau SAIPE
    Estimates](https://www.census.gov/programs-surveys/saipe.html)
-   American Community Survey 5-Year Estimates via [`tidycensus`
    package](https://walker-data.com/tidycensus/)
-   U.S Bureau of Labor Statistics [Consumer Price Index for All Urban
    Consumers (CPI-U)](https://data.bls.gov/toppicks?survey=cu)
-   NCES EDGE [Comparable Wage Index for Teachers
    (CWIFT)](https://nces.ed.gov/programs/edge/Economic/TeacherWage)

## Data Processing Methods

-   Methodology based on process used by
    [`edbuildr`](https://github.com/EdBuild/edbuildr), which is detailed
    on a [methodology page](http://data.edbuild.org/) and in some
    [workshop
    documentation](http://viz.edbuild.org/workshops/edbuildr/).
-   The [EdFund Data
    Dictionary](https://data-dictionary.ed-fund.org/?_gl=1*199anoz*_ga*MTg3MDM3NDg2LjE3MzkzNzAzOTE.*_ga_TGH6XK399M*MTc0NDIyMzY3Ni43LjEuMTc0NDIyMzY4MC4wLjAuMA..)
    informs our handling of F-33 data.
-   Adjustments for payments to other school systems follows the
    approach used by Kristen Blagg, Emily Gutierrez, and Fanny Terrones
    in [Funding Flows: Which Students Receive a Greater Share of School
    Funding?](https://apps.urban.org/features/school-funding-trends/files/202204_K12_funding_technical_appendix.pdf)
-   Inflation adjustments use an average of second half CPI-U of one
    year and first half CPI-U of the following year to align with the
    academic calendar.

## Data Processing Detail

### NCES F-33 Survey Data

Data source: NCES Common Core of Data text files of F-33 data from
2011-12 through 2022-23.

Raw variables selected:

-   Basic information: state, leaid, name, yrdata, v33,

-   Revenue data: totalrev, tlocrev, tstrev, tfedrev

-   Expenditure data, all years: c11, u11, v91, v92, c24, l12, m12, d11,
    q11

-   Current expenditure data: TCURELSC (total current elementary/secondary
    expenditure), all years; the ESSA fund-type split (ce1, ce2, and — from
    2017-18 — ce3), 2015-16 and later where states report it

-   Capital, debt service, and fund-balance data, all years: TCAPOUT, F12,
    G15, K09, K10, K11, I86, and the long/short-term debt and fund-balance
    items (see "Capital, Debt Service, and Fund Balances" below)

Adjustments:

-   Rename variables

-   Convert district names to title case

-   Ensure enrollment is a numeric variable

-   Replace the F-33 missing-value codes (`-1` and `-2`) with `NA` across the
    revenue, expenditure, capital, and debt columns in every year.

-   Convert flagged zero-filled missing values to `NA`. F-33 codes missingness
    two ways: the `-1`/`-2` codes above, and — for some items and states —
    a literal `0` with an `FL_*` companion flag of `M` (missing) or `N` (not
    applicable). The `na_flagged()` step in `01_f33_clean.R` applies the flags
    to the expenditure-detail, COVID (`AE1`-`AE8`), capital-detail, debt,
    fund-balance, and CE fund-type items before the flag columns are dropped.
    The largest effect is on the COVID columns: New York (including NYC) never
    reported them in any year, and California stopped after FY20, so those
    district-years were previously fake zeros. Genuine reported zeros
    (flag `R`) are preserved. **Deliberately excluded** are the
    revenue-adjustment inputs (`c11`, `u11`, `v91`, `v92`, `q11`, `l12`,
    `m12`, `d11`, `c24`): converting their zero-fills to `NA` would propagate
    into the adjusted revenue columns for a large share of districts, so
    unreported values there remain `0` (i.e., no adjustment). One consequence
    is that `exp_pay_private_sch`, `exp_pay_charter_sch`, `exp_pay_other_lea`,
    and `osp_pct` retain zero-filled values where states did not report;
    the widely observed "`osp_pct` exactly zero" pattern is substantially
    this. Summary items (`TOTALREV`, `TCURELSC`, `TCAPOUT`) carry no flags
    and cannot be repaired this way.

-   `exp_cur_total` is the F-33 item TCURELSC (total current expenditure for
    elementary/secondary education), which is reported for nearly all districts
    in every year. The fund-type components `exp_cur_st_loc` (CE1),
    `exp_cur_fed` (CE2), and `exp_cur_resa` (CE3, from 2017-18) are the ESSA
    Part XI breakdown, which several states skip entirely (all of Illinois and
    Minnesota through FY23; New York — including NYC — New Jersey,
    Massachusetts, Oregon, and others in earlier years); those district-years
    are `NA` in the component columns but still have `exp_cur_total`. The
    components do **not** sum exactly to `exp_cur_total`: the ESSA items carry
    different object exclusions (payments to private, charter, and other
    school systems), so the CE-sum differs from TCURELSC by more than 2% for
    roughly 40% of reporting districts.

### Capital, Debt Service, and Fund Balances

Beginning with the 2022-23 data update, the F-33 cleaning step also carries 18
capital, debt-service, and fund-balance variables from the district-level F-33
files for users focused on school facilities. All are available for every year
(2011-12 onward).

Variables:

-   **Capital outlay (flows):** `exp_cap_total` (total capital outlay) and its
    five components `exp_cap_construction`, `exp_cap_land`,
    `exp_cap_equip_instr`, `exp_cap_equip_other`, and `exp_cap_equip_nonspec`.
    `exp_cap_total_pp` is total capital outlay per pupil.

-   **Debt service (flow):** `exp_debt_interest` — interest paid on
    school-system debt.

-   **Debt outstanding and activity:** `debt_lt_begin`, `debt_lt_issued`,
    `debt_lt_retired`, `debt_lt_end` (long-term) and `debt_st_begin`,
    `debt_st_end` (short-term).

-   **Fund balances (fiscal year-end):** `fund_bal_debt_svc`, `fund_bal_bond`,
    and `fund_bal_other`.

-   **Capital/debt-service state revenue:** `rev_state_cap_debt` (F-33 item
    C11) — state revenue restricted to capital outlay and debt service. This is
    the amount netted out of the adjusted `rev_state` (see "Adjustments"
    below). As a revenue-adjustment input it is deliberately excluded from the
    flagged-zero-to-`NA` conversion, so unreported values are `0`, not `NA`.

`exp_cap_total`, `exp_cap_total_pp`, and `rev_state_cap_debt` are included in
both the full and skinny datasets; the remaining 15 variables are in the full
dataset only.

**Cautions:**

-   **Capital outlay is excluded from current spending by definition.**
    `exp_cap_total` is *not* part of `exp_cur_total`; current spending covers
    operating costs only. Do not sum them expecting "total spending" without
    understanding the distinction.

-   **Capital spending is lumpy.** A district's capital outlay swings widely
    year to year — a new building appears as a one-year spike. Single-year
    `exp_cap_total_pp` rankings are misleading; use 3-5 year averages for
    cross-district comparison.

-   **Distinguish bond-funded from pay-as-you-go capital.** A high
    `exp_cap_total` may be financed by debt rather than current resources. Read
    `debt_lt_issued` and `fund_bal_bond` alongside the capital flows to see how
    construction was paid for.

-   **`exp_debt_interest` is interest only.** Principal retirement
    (`debt_lt_retired`) is a balance-sheet transaction, not an expenditure, and
    is not counted as spending.

-   **Interplay with the state-revenue adjustment.** The adjusted `rev_state`
    nets out one-time state capital and debt-service aid (the `c11`
    adjustment); `rev_state_unadj` restores it. When analyzing capital, compare
    against `rev_state_unadj` / `rev_state_unadj_pp`, and watch `c11_spike_flag`
    for district-years dominated by one-time state capital grants.

-   **`NA` conflates "missing" and "not applicable."** A district with no debt
    and a district that failed to report both appear as `NA` (from the `-1` /
    `-2` source codes). `NA` is not zero.

-   **Debt and fund-balance columns are balance-sheet stocks, not flows.** They
    are carried in nominal dollars and should *not* be deflated with the CPI-U
    flow index used for spending; the `edfinr` package leaves them nominal under
    `cpi_adj` for this reason. (A labor-cost index such as CWIFT likewise does
    not deflate construction costs.)

### CCD Directory Data

Data source: NCES CCD Directory data obtained via the
[educationdata](https://educationdata.urban.org/documentation/#r)
package.

Year convention: the pipeline labels every row by fiscal year, the last
year of the school year (year 2012 = SY 2011-12), matching the F-33
survey. The Urban Institute API labels directory years by the fall of
the school year (2011 = SY 2011-12), so `02_ccd_clean.R` requests Urban
year `fy - 1` and re-labels it to `fy` at download time (see the
`get_dir_fy()` helper). This keeps directory attributes (district name,
county, urbanicity, LEA type) aligned with the finance data for the same
school year.

Raw variables selected:

-   Core district identifiers and location: state, ncesid (lea id),
    county, dist_name, state_leaid

-   Institutional details: lea_type, lea_type_id, urbanicity,
    urbanicity_raw, urbanicity_raw_cat, congressional_dist

-   Staffing and enrollment: total_teachers_fte, school_count, enroll,
    sped_enroll, ell_enroll

Adjustments:

-   Rename variables to more intuitive names

-   Standardize district names to title case

-   Ensure numeric fields such as enrollment and teacher counts are
    correctly converted

-   Derive urbanicity fields from the NCES urban-centric locale code:
    `urbanicity_raw` (the raw 12-category code as an integer),
    `urbanicity_raw_cat` (a labeled 12-category factor, e.g. "City, Large"),
    and `urbanicity` (collapsed to City / Suburb / Town / Rural)

-   Remove extraneous columns (e.g. those not needed for subsequent
    joins)

### SAIPE Poverty Estimates

Data source: Census Bureau SAIPE Estimates

Raw variables selected:

-   Basic geographic and demographic fields: State Postal Code, State
    FIPS Code, District ID, Name

-   Population estimates: Estimated Total Population, Estimated
    Population 5-17, and the estimated number of relevant children 5 to
    17 years old in poverty

Adjustments:

-   Convert district names to title case

-   Convert population fields to numeric

-   Construct a combined NCES district identifier by concatenating state
    FIPS and District ID

### ACS 5-Year Estimates

Data source: American Community Survey 5-Year Estimates accessed via the
[`tidycensus`](https://walker-data.com/tidycensus/) package

Raw variables selected:

-   Core economic indicators: median household income (B19013_001 → `mhi`)
    and median property value (B25077_001 → `mpv`)

-   Added in the 2022-23 update: aggregate household income (B19025_001) and
    total households (B11001_001), from which mean household income
    (`mean_hhi`) is derived; the Gini index of income inequality
    (B19083_001 → `gini`); housing tenure (B25003 → `owner_pct`); SNAP receipt
    (B22003 → `snap_pct`); and civilian labor force / unemployment
    (B23025 → `unemp_rate`)

-   Educational attainment (B15003 series) → `adult_pop`, `ba_plus_pop`,
    `ba_plus_pct`

-   Data are pulled for different geographic breakdowns (unified,
    elementary, and secondary school districts)

Adjustments:

-   Data for multiple fiscal years are combined using `bind_rows`

-   Pivot the data to widen variables for clarity

-   Rename “GEOID” to a standard `ncesid` and ensure proper formatting
    of district identifiers

-   Derive rate variables from the raw counts: `mean_hhi` (aggregate income /
    households), `owner_pct` (owner-occupied / occupied units), `snap_pct`
    (SNAP households / all households), and `unemp_rate` (unemployed / civilian
    labor force)

-   Convert estimates to numeric as needed

### CPI

Data source: U.S. Bureau of Labor Statistics, specifically the Consumer
Price Index for All Urban Consumers (CPI-U)

Raw variables selected:

-   CPI time series data (specific variable names as provided in the raw
    file)

Adjustments:

-   Calculate an averaged CPI value using the second half of one year
    and the first half of the following year to align with the academic
    calendar

-   Clean and reformat CPI data for consistency across processing
    scripts

### CWIFT (Comparable Wage Index for Teachers)

Data source: NCES EDGE Comparable Wage Index for Teachers (CWIFT), cleaned by
`scripts/07_cwift_clean.R` and documented in `data/raw/cwift/SOURCES.md`. CWIFT
measures regional variation in the wages of comparable (non-teacher) college
graduates; a value near 1.0 is the national average, above 1.0 a higher-cost
labor market, below 1.0 lower-cost.

`CWIFT<yyyy>` maps to edfinr fiscal year `yyyy`. Four columns are added to the
full dataset — `cwift_est` (the index), `cwift_se` (its standard error),
`cwift_imputed` (logical), and `cwift_impute_method` — of which `cwift_est` and
`cwift_imputed` are also included in the skinny dataset.

Coverage and imputation (`cwift_impute_method`):

-   **FY2012–FY2014** (`NA`): no CWIFT release exists; these district-years have
    no index.
-   **FY2015–FY2019, FY2021, FY2022** (`observed`): direct NCES releases.
-   **FY2020** (`interpolated_2019_2021`): NCES published no CWIFT2020 (the ACS
    2020 1-year estimates were withheld for COVID-19 data-quality reasons), so
    FY2020 is the mean of FY2019 and FY2021 for LEAs present in both. Its
    `cwift_se` is an approximation (mean of the two neighbor SEs), **not** an
    NCES-published value.
-   **FY2023** (`carried_forward_2022`): as of the 2026-07-20 live-check the most
    recent release is CWIFT2022, so FY2023 carries FY2022 forward, flagged.

**Cautions:**

-   **CWIFT is a labor-cost index, not a general price deflator.** Use it to
    compare the cost of employing teachers across places — not to deflate
    non-labor costs such as construction or capital outlay.

-   **Do not double-count with CPI.** CWIFT adjusts for cross-sectional
    (place-to-place) labor-cost differences; the CPI-U factor (`cpi_sy12`)
    adjusts for across-time inflation. They serve different purposes — apply at
    most one of each.

-   **`cwift_imputed` flags non-observed values.** Treat interpolated (FY2020)
    and carried-forward (FY2023) values with appropriate caution, and note the
    partial LEA coverage (`NA` where a district is outside the CWIFT universe).

## Joining Data

-   The joining process is implemented in the
    `08_edfinr_join_and_exclude.R` script.
-   Data from the F-33 survey, CCD Directory, ACS (unified, elementary,
    and secondary), SAIPE, and CWIFT sources are merged using left joins on
    shared district identifiers (ncesid) and fiscal year.
-   The procedure ensures that each district record is enriched with
    revenue, expenditure, demographic, and economic data.

## Adjustments

-   Additional transformations are applied after the join:
    -   Recalculating key metrics such as total expenditures by summing
        federal, state, and local amounts.
    -   Reconciling differences in naming conventions and missing data
        between sources.
    -   Standardizing variable formats across the merged dataset.

-   Revenue adjustments (see the methodology references above) produce adjusted
    `rev_state`, `rev_local`, `rev_fed`, and `rev_total` (with per-pupil `_pp`
    versions) that net out capital and debt service (`c11`), property sales
    (`u11`), and — proportionally — payments to other school systems. The
    original values are retained as `rev_*_unadj`; `rev_state_unadj_pp` and
    `rev_local_unadj_pp` were added in the 2022-23 update for direct
    adjusted-vs-unadjusted comparison. The `c11` amount itself is shipped as
    `rev_state_cap_debt` (full and skinny) so users can see the size of the
    state-revenue adjustment directly.

-   Two anomaly indicators were added in the 2022-23 update:
    -   `osp_pct`: the share of unadjusted total revenue paid to other systems
        (private schools, charters, other LEAs), which makes the size of the
        proportional adjustment visible.
    -   `c11_spike_flag`: `TRUE` for district-years where the `c11` state-revenue
        adjustment removed more than 50% of unadjusted state revenue *and*
        exceeded the district's own historical median by more than 25 percentage
        points. These typically reflect one-time state capital grants (e.g. MA
        MSBA, CO BEST) rather than changes in operating aid, so `rev_state_pp`
        should be interpreted with care in flagged rows.

## Exclusions

-   Districts with enrollment less than or equal to 0 are removed.
-   Districts with total revenue less than or equal to 0 are removed.
-   Districts with invalid LEA type (i.e. where lea_type_id is not one
    of 1, 2, 3, or 7) are excluded — but only when the following directory
    vintage agrees. The directory occasionally miscodes a real district's
    agency type for a vintage (all MA regional districts were coded
    "service agency" through SY 2015-16; several AL city districts are
    miscoded around their formation years), so a district-year whose
    following vintage codes it as a regular district, supervisory union,
    or charter is retained. District-years with no same-year directory
    row at all are excluded. Because the MA regional-district miscode
    spans five consecutive vintages (SY 2011-12 through SY 2015-16), the
    following-vintage check cannot recover FY2012-FY2015 for those
    districts; an explicit vetted list of 60 MA regional districts
    (`ma_regional_rescue` in `scripts/08_edfinr_join_and_exclude.R`)
    restores them. See `MA_REGIONAL_RESCUE.md` for the vetting.
-   Districts with invalid school level type (i.e. where schlev is not
    one of "01", "02", or "03", except for specified CA exceptions) are
    excluded.
-   Districts where revenue per pupil (rev_total_pp) is above the
    year-specific high threshold (as defined in the cpi_exclusions_sy12
    data) are excluded.
-   Districts where revenue per pupil (rev_total_pp) is below the
    year-specific low threshold (as defined in the cpi_exclusions_sy12
    data) are excluded.
-   Semi-private Connecticut schools (with NCES IDs "0905371",
    "0905372", and "0905373") are removed.

## Data Notes and Cautions

Users should note the following when working with the `edfinr` datasets:

-   Some variables were originally coded with `-1` or `-2` to indicate missing
    or not-applicable values; these have been replaced with `NA` during
    processing. Missing values propagate through derived totals rather than
    being treated as zero. `exp_cur_total` is sourced directly from the F-33
    TCURELSC item and is available for nearly all districts in all years
    (FY12-FY23); the ESSA fund-type components (`exp_cur_st_loc`,
    `exp_cur_fed`, `exp_cur_resa`) are `NA` wherever a state skipped that
    reporting, and they do not sum exactly to `exp_cur_total` because the
    ESSA items exclude payments to private, charter, and other school
    systems.
-   The COVID expenditure columns (`exp_covid_*`) are `NA` — not zero — where
    districts did not report them: all of New York in every year FY20-FY23,
    and roughly a third to half of California districts from FY21 onward,
    among others. A `0` in these columns is a genuine reported zero (common
    in FY20, when most ESSER funds were not yet spent). National sums are
    unaffected, but per-state COVID spending comparisons must account for
    the non-reporting districts. The same flag-aware handling applies to the
    capital-detail, debt, and fund-balance columns. Only zero-filled
    flagged cells become `NA`: a handful of state-years carry genuine
    reported values under a missing/not-applicable flag (e.g. all NJ FY12
    expenditure detail, ID FY13-14 debt stocks), and those values are
    retained.
-   During data processing, we identified a sharp rise in the number of
    California districts appearing only from 2019 onward in the data.
    This reflects the fact that many charter schools became separate
    LEAs in those years. Beginning in 2018–19, a wave of California
    charter schools switched to independent CALPADS/CBEDS reporting and
    thus were assigned their own NCES LEA IDs for the first time. Once
    in the NCES LEA universe, those new charter‐LEAs automatically show
    up in the F-33 finance survey (with blanks or flags if they report
    no finance data), and Census’s SAIPE and ACS school‐district
    products (which mirror NCES LEA boundaries).
-   The `state` column is sourced from the F-33 survey only; state fields
    from the other sources (CCD Directory, SAIPE, ACS) are dropped before
    the join. Earlier releases carried manual corrections for a handful of
    districts whose sources disagreed on state; those are no longer needed,
    and each NCES ID maps to a single state in the published data.
-   The joined dataset represents a synthesis of data from multiple
    sources; discrepancies in source data formats may lead to minor
    variations.
-   Inflation and adjustment factors (e.g., CPI adjustments) are based
    on averages and may not perfectly reflect local cost variations.
-   **Caution is advised when comparing data across fiscal years due to
    potential differences in data collection and processing methods.**

## Authors

- **Alex Spurrier** ([alex.spurrier@bellwether.org](mailto:alex.spurrier@bellwether.org))  - Lead developer and package maintainer
- **Krista Kaput** - Core development and feature implementation
- **Michael Chrzan** - Data processing functions and testing

