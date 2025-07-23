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
2011-12 through 2021-22.

Raw variables selected:

-   Basic information: state, leaid, name, yrdata, v33,

-   Revenue data: totalrev, tlocrev, tstrev, tfedrev

-   Expenditure data, all years: c11, u11, v91, v92, c24, l12, m12, d11,
    q11

-   Current expenditure data, 2015-16 and later: ce1, ce2

Adjustments:

-   Rename variables

-   Convert district names to title case

-   Ensure enrollment is a numeric variable

-   For 2015-16 and later years, include current expenditure columns,
    adjusting to replace `-1` codes with `NA`, then calculate total
    expenditures as sum of federal, state, and local expenditures.

### CCD Directory Data

Data source: NCES CCD Directory data obtained via the
[educationdata](https://educationdata.urban.org/documentation/#r)
package.

Raw variables selected:

-   Core district identifiers and location: state, ncesid (lea id),
    county, dist_name, state_leaid

-   Institutional details: lea_type, lea_type_id, urbanicity,
    congressional_dist

-   Staffing and enrollment: total_teachers_fte, school_count, enroll,
    sped_enroll, ell_enroll

Adjustments:

-   Rename variables to more intuitive names

-   Standardize district names to title case

-   Ensure numeric fields such as enrollment and teacher counts are
    correctly converted

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

-   Key economic indicators: median_income (variable code B19013_001)
    and median_property_value (variable code B25077_001)

-   Data are pulled for different geographic breakdowns (unified,
    elementary, and secondary school districts)

Adjustments:

-   Data for multiple fiscal years are combined using `bind_rows`

-   Pivot the data to widen variables for clarity

-   Rename “GEOID” to a standard `ncesid` and ensure proper formatting
    of district identifiers

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

## Joining Data

-   The joining process is implemented in the
    `07_edfinr_join_and_exclude.R` script.
-   Data from the F-33 survey, CCD Directory, ACS (unified, elementary,
    and secondary), and SAIPE sources are merged using left joins on
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

## Exclusions

-   Districts with enrollment less than or equal to 0 are removed.
-   Districts with total revenue less than or equal to 0 are removed.
-   Districts with invalid LEA type (i.e. where lea_type_id is not one
    of 1, 2, 3, or 7) are excluded.
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

-   Some variables were originally coded with `-1` to indicate missing
    values; these have been replaced with `NA` during processing.
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
-   Some district were found to have more than 1 state within the data,
    even post cleaning and exclusions. These districts' state was
    manually changed within the clean data to their most accurate state
    (e.g. we found that a charter LEA was listed as MD but is actually
    in AZ, not MD) or most recent barring finding specific rationale for
    discrepancy. These adjustments - include the affected NCES id's -
    can be found at the end of the `07_edfinr_join_and_exlude.R` script.
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

