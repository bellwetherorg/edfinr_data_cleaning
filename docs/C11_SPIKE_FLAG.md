# c11_spike_flag Methodology

Design record for the `c11_spike_flag` indicator computed in
`scripts/09_edfinr_join_and_exclude.R` and shipped in both the full and
skinny datasets. Finalized July 2026 for the 0.2 release.

## Purpose

The adjusted `rev_state` nets out F-33 item C11, state revenue restricted to
capital outlay and debt service (shipped as `rev_state_cap_debt`). In most
district-years C11 is a small share of state revenue, but state
school-construction programs (Massachusetts MSBA, Colorado BEST, and
similar) deliver one-time grants that can briefly dominate a district's
state revenue. In those years the adjusted `rev_state_pp` drops sharply
relative to the unadjusted value for reasons that have nothing to do with
operating aid. The flag marks those district-years so users interpret
`rev_state_pp` with care.

## Definition

For each district-year, the C11 share is

```
c11_adj_pct = rev_state_cap_debt / rev_state_unadj    (NA if rev_state_unadj is 0)
```

`c11_spike_flag` is `TRUE` when both:

1. `c11_adj_pct > 0.5` (C11 exceeds half of unadjusted state revenue), and
2. `c11_adj_pct` exceeds the district's own historical median share by more
   than 25 percentage points.

The district median is taken over the district's years in the cleaned panel
(after exclusions), with `NA` shares dropped. The 50% level catches only
adjustment-dominated years; the 25-point margin over the district's own
median keeps districts with structurally high C11 (some states run ongoing
capital aid through it) from being flagged every year.

## NA semantics

The flag is `NA` where `rev_state_unadj` is zero, because the share is
undefined there. In the FY2012-FY2023 panel that is 873 district-years,
mostly charter LEAs and other districts reporting no state revenue. It can
also be `NA` for a district-year whose share clears 50% but whose district
median is undefined. `NA` means "cannot be assessed," not "no spike."

## Why the share is computed from C11 directly

An earlier implementation measured `(rev_state_unadj - rev_state) /
rev_state_unadj`, the *combined* state-revenue adjustment. Because
`rev_state` also nets out the state share of payments to other school
systems, that version could flag district-years with zero C11 (55 such rows
in the pre-release QC), which contradicted the flag's name and
documentation. The corrected C11-only definition was validated against the
rebuilt panel: 474 flagged district-years FY2012-FY2023, led by Colorado
and Massachusetts, matching the BEST/MSBA pattern the flag was designed
for.

## Guidance for users

- When analyzing capital, compare against `rev_state_unadj` /
  `rev_state_unadj_pp` and read `rev_state_cap_debt` directly; the flag is a
  screen, not a substitute for looking at the amounts.
- The related `osp_pct` column plays the same visibility role for the
  payments-to-other-systems adjustment; the two indicators are deliberately
  separate.
