# CCD Directory Year Alignment

Design record for the fiscal-year convention in `scripts/02_ccd_clean.R` and
the directory-dependent screens in `scripts/09_edfinr_join_and_exclude.R`.
The alignment fix landed July 2026 (commit `19e27e9`) for the 0.2 release.

## The convention

The pipeline labels every row by **fiscal year**, the last year of the
school year (year 2012 = SY 2011-12), matching the F-33 survey. The Urban
Institute `educationdata` API labels directory years by the **fall** of the
school year (2011 = SY 2011-12).

`get_dir_fy()` in script 02 therefore requests Urban year `fy - 1` and
relabels it to `fy` at download time. Before the fix, the pull requested
Urban year `fy` directly, which attached each finance year to the directory
attributes (name, county, urbanicity, LEA type, enrollment) of the
*following* school year.

How the bug was confirmed, and how to re-confirm after any change here:
directory enrollment should match F-33 enrollment for the same labeled year
at close to 100%, and should match the year-shifted join at close to 0%.
Under the bug the pattern was reversed.

## Downstream dependencies on this alignment

- **Directory match-rate guard** (script 09): after the join, more than 97%
  of live F-33 district-years (`rev_total > 0, enroll > 0`) must have a
  directory row. A year misalignment shows up here first, because unmatched
  rows get `lea_type_id = NA` and would otherwise be dropped silently as
  "LEA Type" exclusions.
- **Following-vintage LEA-type screen** (script 09): a district-year is
  excluded on LEA type only if the *next* directory vintage agrees. This
  absorbs single-vintage miscodes (several AL city districts around their
  formation years; all MA regionals through SY2015-16, see
  `MA_REGIONAL_RESCUE.md`). The screen's year arithmetic assumes the
  fiscal-year convention above.
- **Latest-year caveat**: the newest year in the panel has no following
  vintage yet, so `lea_type_id_next` is `NA` there and the screen rests on
  the same-year vintage alone. Expect the latest year's LEA-type exclusions
  to revise slightly when the next directory vintage is added. This is by
  design, not a bug.

## Sentinel codes

The Urban API encodes missing/not-applicable/suppressed values as
`-1`/`-2`/`-3`. Script 02 converts these to `NA` in the count columns
(`enroll`, `sped_enroll`, `ell_enroll`, `total_teachers_fte`,
`school_count`) and in the locale field before factor construction, so no
sentinel survives as a negative count or as its own factor level.
`lea_type_id` sentinels are left as-is deliberately: the exclusion logic in
script 09 distinguishes "no directory row" (`NA`) from "directory row with a
non-district type," and NA-ing type sentinels would collapse that
distinction.
