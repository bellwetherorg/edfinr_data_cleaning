# MA Regional District Rescue (FY2012-FY2015)

**Status:** implemented in `scripts/08_edfinr_join_and_exclude.R` (`ma_regional_rescue`)
**Vintage of analysis:** July 2026, against CCD directory vintages SY 2011-12
through SY 2023-24 (Urban Institute `educationdata` API) and F-33 FY2012-FY2023.

## Problem

Every Massachusetts regional school district was miscoded `agency_type = 4`
("service agency") in the CCD directory for five consecutive vintages,
SY 2011-12 through SY 2015-16, and corrected to `1` (regular district) from
SY 2016-17 onward. The LEA-type exclusion screen keeps only types
{1, 2, 3, 7}, with a district-year retained when the *following* directory
vintage carries a passing type. That following-vintage check recovers FY2016
(its next vintage, SY 2016-17, is corrected) but not FY2012-FY2015, where the
same-year and following vintages both carry the miscode. Result: all MA
regional districts were absent from the published data for FY2012-FY2015 --
236 district-years, roughly 107,000-110,000 students per year -- even though
they file F-33 with positive enrollment and revenue in every year 2012-2023.

These are genuine operating school districts organized under MGL c.71
(regional academic districts) and MGL c.74/c.71 s.16 (county agricultural
districts), not service agencies.

## Fix

An explicit vetted list of 60 NCES LEA IDs (`ma_regional_rescue`) exempts
those districts from the LEA-type exclusion. All other screens (school level,
revenue outliers, enrollment/revenue positivity) still apply; every restored
row passes them.

### Why an explicit list instead of a panel-modal type rule

A rule that rescues any district whose modal (or any-later-vintage) agency
type is in {1, 2, 3, 7} was considered and rejected:

1. **It would pull in the 56 CA county offices of education for FY2012.**
   The COEs' directory pattern (`444111111111`: type 4 through vintage
   SY 2013-14, type 1 after) gives them a passing modal type. They are kept
   out of the panel in FY2013+ by the school-level screen (F-33 `schlev` =
   05), but F-33 miscoded their `schlev` as 03 in FY2012 only, so a modal
   rescue would admit 56 single-year COE rows (median revenue per pupil
   roughly $50k) in FY2012 and 58 in FY2013.
2. **It would pull in the 26 MA regional vocational-technical districts for
   FY2012 only** (see below), creating the same one-year-blip artifact.
3. A frozen list of historical IDs cannot drift if Urban revises past
   directory vintages; a rule-based rescue could silently change membership.

## Vetting

All 88 MA districts excluded as "LEA Type" in FY2012-FY2015 were reviewed
individually. Every one is a genuine operating district; the split below is
about panel consistency, not legitimacy.

### Rescued: 60 districts, 236 district-years

Criteria, each checked per district:

- Directory agency type corrected to 1 from vintage SY 2016-17 onward
  (pattern `444441111111`, or type 1 in the formation-year vintage for the
  three districts formed 2011-2013: Somerset Berkley, Ayer Shirley, Monomoy).
- Present in the published panel in at least 7 of the 8 years FY2016-FY2023.
- F-33 `schlev` in {01, 02, 03} in every restored year, so the school-level
  screen agrees with the district's treatment in FY2016+.
- Enrollment continuity across the restored/published boundary: FY2016
  published enrollment is 0.92x-1.07x FY2015 restored enrollment for all 60.
- Revenue plausibility: restored `rev_total_pp` runs roughly $11.7k-$30.5k,
  spanning the MA state median (about $14.9k-$15.5k in those years); no
  restored row crosses the CPI-adjusted Over/Under thresholds. The high end
  is Up-Island Regional (Martha's Vineyard elementary district, about $30k
  per pupil), consistent with its published FY2016+ values.

Restored rows by year: FY2012 = 57, FY2013 = 59, FY2014 = 60, FY2015 = 60
(the three newly formed districts phase in). Two county agricultural
districts (Bristol County Agricultural, Norfolk County Agricultural) are
included: their `schlev` is 02 throughout and they appear in the published
panel every year FY2016+.

The 60 IDs, with names, are listed inline in
`scripts/08_edfinr_join_and_exclude.R`.

### Reviewed and left excluded: 28 districts

| Group | n | Reason left out |
|---|---|---|
| Regional vocational-technical districts (Assabet Valley, Blackstone Valley, Blue Hills, Bristol-Plymouth, Cape Cod, Franklin County, Greater Fall River, Greater Lawrence, Greater Lowell, Greater New Bedford, Minuteman, Montachusett, Nashoba Valley, Northeast Metropolitan, Northern Berkshire, Old Colony, Pathfinder, Shawsheen Valley, South Middlesex, South Shore, Southeastern, Southern Worcester County, Tri County, Upper Cape Cod, Whittier, plus Northampton-Smith Vocational Agricultural) | 26 | F-33 `schlev` is 05 from FY2013 onward, so the school-level screen excludes them in every year FY2013-FY2023; they appear in the published panel in zero years. F-33 coded them 02 in FY2012 only, so a rescue would produce a single FY2012 row per district with no panel continuation -- the same artifact pattern as the CA COEs. |
| Essex Agricultural Technical (2504750) | 1 | Merged into Essex North Shore Agricultural and Technical (2500554) in July 2014; no corrected vintage ever exists and no FY2016+ presence. Restoring FY2012-FY2014 would add a three-year fragment for a district whose successor is itself excluded by the school-level screen in most years. |
| North Shore Regional Vocational Technical (2508830) | 1 | Same merger; also `schlev` 05 from FY2013. |

If the package ever widens scope to include vocational districts (dropping or
extending the `schlev` screen), the 26 voc-tech districts should be revisited
as a group; their exclusion here is a scope decision, not a data-quality
judgment.

## Verification

After rebuilding via `scripts/08_edfinr_join_and_exclude.R`:

- Exactly 236 rows added relative to the pre-rescue build, all MA,
  FY2012-FY2015, all with `lea_type_id = 4` sourced from the miscoded
  vintages; no other state or year changes.
- CA county offices of education remain excluded in all years.
- `scripts/verify_ccd_year_fix.R` passes (its row-delta section reflects
  the year-alignment fix plus these 236 rows).
