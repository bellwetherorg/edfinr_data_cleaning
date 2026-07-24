# Pipeline Documentation

Design records and institutional memory for the edfinr data-cleaning
pipeline. Read these before changing the logic they describe.

- **[ANNUAL_UPDATE_RUNBOOK.md](ANNUAL_UPDATE_RUNBOOK.md)**: how to add a new
  fiscal year and release it, including the behaviors that look like bugs
  but are not.
- **[FLAGGED_ZERO_NA_HANDLING.md](FLAGGED_ZERO_NA_HANDLING.md)**: why
  zero-filled flagged F-33 values become NA, which columns are deliberately
  excluded, and the guard rails (NYC canary, adjustment-input coalesce).
- **[CCD_DIRECTORY_YEAR_ALIGNMENT.md](CCD_DIRECTORY_YEAR_ALIGNMENT.md)**:
  the fiscal-year vs Urban-API year convention, the screens that depend on
  it, and the latest-year revision caveat.
- **[MA_REGIONAL_RESCUE.md](MA_REGIONAL_RESCUE.md)**: vetting record for the
  60-district Massachusetts regional rescue list (FY2012-FY2015).
- **[C11_SPIKE_FLAG.md](C11_SPIKE_FLAG.md)**: definition, thresholds, and NA
  semantics of the `c11_spike_flag` indicator.

Dataset-facing documentation (variables, sources, cautions) lives in the
top-level [README](../README.md).
