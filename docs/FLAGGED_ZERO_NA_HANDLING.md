# Flag-Aware NA Handling for F-33 Zero-Filled Items

Design record for the `na_flagged()` pass in `scripts/01_f33_clean.R` and its
guard rails in `scripts/09_edfinr_join_and_exclude.R`. Implemented July 2026
for the 0.2 release.

## The problem

F-33 encodes missingness two different ways:

1. **Sentinel codes**: `-1` (missing) and `-2` (not applicable) in the value
   itself. These are handled by the `clean_na()` pass in script 01.
2. **Zero-fill plus companion flag**: for many items, a literal `0` with an
   `FL_*` companion column carrying `M` (missing) or `N` (not applicable).
   `R` marks a genuine reported value; `I` marks an imputed one. Before the
   0.2 release these zero-fills passed through as real zeros.

The zero-fill pattern matters most for the COVID expenditure items
(`AE1`-`AE8`): New York, including NYC, never reported them in any year, and
California stopped reporting after FY2020. Those district-years were fake
zeros in earlier releases, which silently corrupted per-state COVID spending
comparisons.

## The design

`na_flagged()` in script 01 converts a value to `NA` only when it is **both**
zero **and** flagged `M` or `N`. Genuine reported values that happen to carry
an `M`/`N` flag are retained (observed cases: all NJ FY2012 expenditure
detail, ID FY2013-14 debt stocks). Genuine reported zeros (flag `R`) are
preserved; FY2020 has thousands of them because most ESSER funds were unspent
by June 2020.

Columns covered: expenditure detail, COVID (`AE1`-`AE8`), capital detail,
debt, fund balances, and the CE fund-type items. The item list is
`f33_flag_aware_items` in script 01; flags are applied before the `FL_*`
columns are dropped.

**Deliberately excluded** are the nine revenue-adjustment inputs (`c11`,
`u11`, `v91`, `v92`, `q11`, `l12`, `m12`, `d11`, `c24`). Converting their
zero-fills to `NA` would propagate into the adjusted revenue columns for a
large share of districts, so unreported values there remain `0`, meaning "no
adjustment." One visible consequence: `exp_pay_private_sch`,
`exp_pay_charter_sch`, `exp_pay_other_lea`, and `osp_pct` retain zero-filled
values where states did not report, which explains most of the
"`osp_pct` exactly zero" pattern.

Summary items (`TOTALREV`, `TCURELSC`, `TCAPOUT`) carry no flags and cannot
be repaired this way. `v33` (enrollment) has a flag but is not in the item
list; a zero-filled flagged enrollment is dropped anyway by script 09's
`enroll > 0` filter, so the outcome is identical.

## Guard rails

- **Canary** (script 09, after the F-33 load): NYC (`3620580`) FY2021
  `exp_covid_total` must exist as exactly one row and be `NA`. A zero there
  means a stale pre-flag rds; a missing row means a truncated input. The
  cardinality assertion matters because `stopifnot()` passes on an empty
  logical vector.
- **Coalesce in script 09**: the `-1`/`-2` sentinel pass in script 01 spans
  `c11:fund_bal_other`, which includes the nine adjustment inputs, so a
  sentinel code there becomes `NA` despite the exclusion above. As of the
  FY2012-FY2023 data no surviving row is affected (the codes occur only on
  rows the `rev_total > 0, enroll > 0` filters drop), but script 09
  coalesces the six inputs it does arithmetic on (`c11`, `u11`, `l12`,
  `v91`, `v92`, `q11`) to 0 so a future vintage cannot leak `NA` through the
  adjusted revenues and past the revenue-outlier screens.

## Interpretation guidance (mirrors the README)

- A `0` in the COVID columns is a genuine reported zero; `NA` means the
  district did not report. National sums are unaffected by the conversion,
  but per-state comparisons must account for non-reporting districts.
- `NA` in the debt and fund-balance columns conflates "missing" and "not
  applicable" (both `-1` and `-2` map to `NA`). `NA` is not zero.
