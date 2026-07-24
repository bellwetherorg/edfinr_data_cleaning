# Massachusetts Regional District Rescue (FY2012-FY2015)

Vetting record for the `ma_regional_rescue` list in
`scripts/08_edfinr_join_and_exclude.R`. Vetted July 2026 during the 0.2
update, against CCD Directory vintages SY2011-12 through SY2016-17 obtained
via the Urban Institute `educationdata` API and the F-33 files in
`data/raw/ccd/`.

## The miscode

The CCD Directory coded every Massachusetts regional school district as
`agency_type` 4 ("service agency") in vintages SY2011-12 through SY2015-16,
and corrected them to type 1 ("regular district") from SY2016-17 onward.
These are genuine operating districts organized under MGL c.71: they file
F-33 with enrollment and revenue every year and appear in the published
panel from FY2016 on.

The pipeline's general defense against single-vintage miscodes is the
following-vintage check: a district-year is excluded on LEA type only when
the next directory vintage agrees. That check recovers FY2016 (its
following vintage, SY2016-17, carries the correction) but cannot recover
FY2012-FY2015, where both the same-year and following vintages carry the
miscode. Those four years are restored by the explicit list documented
here.

## Why an explicit list rather than a rule

Two rule-based alternatives were evaluated and rejected:

- **Panel-modal type** (classify by the district's most common type across
  the panel): this would also rescue the 56 California county offices of
  education, which share the type-4-then-type-1 pattern. Their F-33
  `schlev` was 03 in FY2012 only (05 thereafter), so the school-level
  screen would miss them for exactly that one year, producing a one-year
  FY2012 blip of COEs in the panel.
- **Any-later-vintage-good**: same failure mode, same CA COE trap.

When a directory miscode spans multiple consecutive vintages, a frozen,
vetted ID list is safer than a clever rule.

## Inclusion criteria

A district made the list only if all of the following held:

1. Coded `agency_type` 4 in the SY2011-12 through SY2015-16 directory
   vintages and corrected to type 1 from SY2016-17.
2. A genuine operating regional district under MGL c.71, not a
   collaborative or service entity.
3. Files F-33 with positive enrollment and revenue in the affected years.
4. Present in the published edfinr panel from FY2016 on (i.e., the
   following-vintage check already accepts it there), with continuous
   enrollment across the FY2015/FY2016 boundary.

## Deliberate omissions

- **The 26 MA regional vocational-technical districts**: their F-33
  `schlev` is 05 from FY2013 on, so the school-level screen excludes them
  in every other year. Rescuing them would create a one-year FY2012 blip,
  the same defect that disqualified the rule-based approaches.
- **2 districts that merged away in 2014**: same schlev pattern, same
  one-year-blip problem.

## The list

60 NCES IDs, kept in `ma_regional_rescue` in
`scripts/08_edfinr_join_and_exclude.R` (the code list, with one commented
district name per ID, is the canonical copy; this document mirrors it).
All 60 are unique. The restored rows deliberately ship the source-reported
`lea_type_id` of 4: the FY2016 rows recovered by the following-vintage
check also carry their source-reported type, and the rescue follows that
precedent rather than editing source data.

## Expected effect on the panel

Restored rows by fiscal year, relative to exclusion without the rescue:

| Fiscal year | Restored | Already present | Listed district-years in panel |
|---|---|---|---|
| FY2012 | 57 | 2 | 59 |
| FY2013 | 59 | 0 | 59 |
| FY2014 | 60 | 0 | 60 |
| FY2015 | 60 | 0 | 60 |
| **Total** | **236** | **2** | **238** |

The two already-present FY2012 rows are Somerset Berkley (2500541) and
Ayer Shirley (2500542), both newly formed around 2011-12 and coded
correctly in the directory from the start. Not every listed district has a
row in every year (one district-year is absent from F-33 in FY2013), which
is why the totals are 59/59/60/60 rather than 60 across the board.

Script 08 asserts this invariant after exclusions: the list is unique and
exactly 238 listed district-years for FY2012-FY2015 survive to the shipped
panel.

## Maintenance

- The rescue touches only FY2012-FY2015, a frozen historical window. New
  data vintages (FY2024 and later) do not interact with it; nothing needs
  updating on a routine year-add.
- If NCES revises the historical F-33 or directory files, the 238-row
  assertion in script 08 will fail; re-vet against this document before
  changing the expected count.
- If a similar multi-vintage miscode appears elsewhere, prefer another
  frozen vetted list over a rule, and vet candidates on published-panel
  presence and enrollment continuity in the corrected years, not on name
  plausibility.
