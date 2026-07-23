# 08_edfinr_join_and_exclude.R

# load --------
library(tidyverse)
library(arrow)

options(scipen = 999)

# load acs elementary data
acs_fy12_fy23_elementary <- read_rds("data/processed/acs_fy12_fy23_elementary.rds")

# load acs secondary data
acs_fy12_fy23_secondary <- read_rds("data/processed/acs_fy12_fy23_secondary.rds")

# load acs unified data
acs_fy12_fy23_unified <- read_rds("data/processed/acs_fy12_fy23_unified.rds")

# load ccd data
dir_sy12_sy23 <- read_rds("data/processed/dir_sy12_sy23.rds") |>
  mutate(year = as.character(year)) |>
  select(-enroll, -state)

# following-vintage lea type, used by the exclusion screen below: the
# directory occasionally miscodes a real district's agency type for a
# vintage (all MA regionals were "service agency" through SY15-16, AL city
# districts are miscoded around their formation years), so a district-year
# is excluded on LEA type only if the following vintage agrees
lea_type_next <- dir_sy12_sy23 |>
  transmute(
    ncesid,
    year = as.character(as.integer(year) - 1),
    lea_type_id_next = lea_type_id
  )

# ma regional rescue list: every MA regional school district was miscoded
# agency_type 4 ("service agency") in directory vintages SY2011-12 through
# SY2015-16 and corrected to 1 from SY2016-17. The following-vintage check
# recovers FY2016 (its next vintage carries the correction) but not
# FY2012-FY2015, where both vintages carry the miscode. These 60 districts
# are genuine operating districts under MGL c.71 that file F-33 with
# enrollment every year and appear in the published panel from FY2016 on,
# so their FY2012-FY2015 rows are restored via this explicit vetted list
# (see MA_REGIONAL_RESCUE.md). The list deliberately omits the 26 MA
# regional vocational-technical districts and 2 districts that merged away
# in 2014: their F-33 schlev is 05 from FY2013 on, so the school-level
# screen excludes them in every other year and a rescue would only create
# a one-year FY2012 blip. A panel-modal type rule was rejected for the
# same reason: it would rescue the 56 CA county offices of education in
# FY2012, whose F-33 schlev that year (03; 05 thereafter) slips past the
# school-level screen.
ma_regional_rescue <- c(
  "2500001", # Quabbin
  "2500002", # Spencer-E Brookfield
  "2500013", # Southwick-Tolland-Granville
  "2500014", # Chesterfield-Goshen
  "2500043", # Up-Island Regional
  "2500067", # Manchester Essex Regional
  "2500541", # Somerset Berkley
  "2500542", # Ayer Shirley
  "2500544", # Monomoy Regional
  "2501710", # Acton-Boxborough
  "2501780", # Adams-Cheshire (Hoosac Valley)
  "2501920", # Amherst-Pelham
  "2502040", # Ashburnham-Westminster
  "2502160", # Athol-Royalston
  "2502530", # Berkshire Hills
  "2502580", # Berlin-Boylston
  "2502715", # Blackstone-Millville
  "2503030", # Bridgewater-Raynham
  "2503070", # Bristol County Agricultural
  "2503390", # Central Berkshire
  "2503870", # Concord-Carlisle
  "2504140", # Dennis-Yarmouth
  "2504200", # Dighton-Rehoboth
  "2504290", # Dover-Sherborn
  "2504360", # Dudley-Charlton
  "2504560", # Nauset
  "2505070", # Freetown-Lakeville
  "2505100", # Frontier
  "2505160", # Gateway
  "2505270", # Gill-Montague
  "2505500", # Groton-Dunstable
  "2505670", # Hamilton-Wenham
  "2505730", # Hampden-Wilbraham
  "2505740", # Hampshire
  "2506000", # Hawlemont
  "2506510", # King Philip
  "2506930", # Lincoln-Sudbury
  "2507380", # Martha's Vineyard
  "2507410", # Masconomet
  "2507680", # Mendon-Upton
  "2507990", # Mohawk Trail
  "2508160", # Mount Greylock
  "2508280", # Narragansett
  "2508310", # Nashoba
  "2508530", # New Salem-Wendell
  "2508650", # Norfolk County Agricultural
  "2508790", # North Middlesex
  "2508910", # Northboro-Southboro
  "2509150", # Old Rochester
  "2509450", # Pentucket
  "2509600", # Pioneer Valley
  "2509900", # Ralph C Mahar
  "2510830", # Silver Lake
  "2511040", # Southern Berkshire
  "2511490", # Tantasqua
  "2511740", # Triton
  "2511880", # Wachusett
  "2512100", # Quaboag Regional
  "2512930", # Whitman-Hanson
  "2513321"  # Farmington River
)

# load f33 data
f33_sy12_sy23 <- read_rds("data/processed/f33_sy12_sy23.rds") |>
  select(-dist_name)

# canary: the f33 input must postdate the flag-aware NA pass (see
# FLAG_NA_REGRESSION_FIX_PLAN.md); NYC never reported the COVID items, so a
# zero here means a stale pre-flag rds
stopifnot(
  f33_sy12_sy23 |>
    filter(ncesid == "3620580", year == "2021") |>
    pull(exp_covid_total) |>
    is.na()
)

# load saipe data
saipe_fy12_fy23_clean <- read_rds("data/processed/saipe_fy12_fy23_clean.rds") |>
  select(-state, -dist_name)

# load cpi exclusion data
cpi_exclusions_sy12 <- read_rds("data/processed/cpi_exclusions_sy12.rds")

# load cwift data (year is integer here; convert to character to match the
# panel join key)
cwift_lea_clean <- read_rds("data/processed/cwift_lea_clean.rds") |>
  mutate(year = as.character(year))

# unify acs data -----

acs_fy12_fy23_all <- bind_rows(
  acs_fy12_fy23_elementary,
  acs_fy12_fy23_secondary,
  acs_fy12_fy23_unified
) |>
  select(-dist_name, -state)

# join data ------
edfinr_join_fy12_fy23 <- f33_sy12_sy23 |>
  left_join(dir_sy12_sy23, by = c("ncesid", "year")) |>
  left_join(acs_fy12_fy23_all, by = c("ncesid", "year")) |>
  left_join(saipe_fy12_fy23_clean, by = c("ncesid", "year")) |>
  left_join(cwift_lea_clean, by = c("ncesid", "year")) |>
  left_join(cpi_exclusions_sy12 |> select("year", "cpi_sy12"), by = "year") |>
  select(ncesid, year, state, county, dist_name, state_leaid, enroll, everything())

# guard against silent directory-join failures: a year-alignment bug or a bad
# vintage would show up as F-33 district-years with no directory match, which
# then get dropped downstream as "LEA Type" exclusions (lea_type_id is NA)
dir_match_rate <- edfinr_join_fy12_fy23 |>
  filter(rev_total > 0, enroll > 0) |>
  summarise(rate = mean(!is.na(lea_type_id))) |>
  pull(rate)
stopifnot(dir_match_rate > 0.97)


# examine incomplete data -------

# districts and charter schools with less than 0 enrollment
exclude_no_enroll <- edfinr_join_fy12_fy23 |>
  filter(enroll < 0)

# districts and charters with less than 0 reported total revenue
exclude_no_total_rev <- edfinr_join_fy12_fy23 |>
  filter(rev_total < 0)

# lea_type outliers
exclude_lea_type <- edfinr_join_fy12_fy23 |>
  filter(!lea_type_id %in% c(1, 2, 3, 7))

# sch_type outliers
exclude_sch_type <- edfinr_join_fy12_fy23 |>
  filter(!schlev %in% c("01", "02", "03"))

# clean data ----

edfinr_data_fy12_fy23_pre_exclusion <- edfinr_join_fy12_fy23 |>
  # initial exclusions
  filter(rev_total > 0) |>
  filter(enroll > 0) |>
  # apply revenue adjustments
  mutate(
    rev_state_adj_temp = rev_state - c11, # subtract capital/debt service
    rev_local_adj_temp = rev_local - u11, # subtract property sales
    # add tx pre-2013 adjustment to subtract l12 from local revenue
    rev_local_adj_temp = case_when(
      as.integer(year) < 2013 & state == "TX" ~ rev_local_adj_temp - l12,
      TRUE ~ rev_local_adj_temp
    ),
    # this is a new adjustment to account for payments to other districts
    # for tuition/other services
    other_sys_pay = v91 + v92 + q11, # subtract payments to other systems

    # interim totals to calculate other system payment adjustments
    rev_total_adj_temp = rev_state_adj_temp + rev_local_adj_temp + rev_fed,
    state_adj_pct = rev_state_adj_temp / rev_total_adj_temp,
    local_adj_pct = rev_local_adj_temp / rev_total_adj_temp,
    fed_adj_pct = rev_fed / rev_total_adj_temp,

    # calculate charter payment adj revenue by subtracting
    # payments to other systems proportionally from adj state, adj local,
    # and federal revenues
    rev_state_adj = rev_state_adj_temp - (other_sys_pay * state_adj_pct),
    rev_local_adj = rev_local_adj_temp - (other_sys_pay * local_adj_pct),
    rev_fed_adj = rev_fed - (other_sys_pay * fed_adj_pct),
    # calculate total adj revenue
    rev_total_adj = rev_state_adj + rev_local_adj + rev_fed_adj
  ) |>
  # create cols for raw rev totals
  mutate(
    rev_total_unadj = rev_total, 
    rev_local_unadj = rev_local,
    rev_state_unadj = rev_state,
    rev_fed_unadj = rev_fed
  ) |> 
    # remove non-adjusted revenue and interim columns
  select(
    -rev_total, -rev_local, -rev_state, -rev_fed,
    -u11, -c24, -l12, -m12, -d11,
    -rev_state_adj_temp, -rev_local_adj_temp,
    -rev_total_adj_temp, -state_adj_pct, -local_adj_pct, -fed_adj_pct
  ) |>
    # rename adjusted rev columms
  rename(
    rev_local = rev_local_adj,
    rev_state = rev_state_adj,
    rev_fed = rev_fed_adj,
    rev_total = rev_total_adj,
    # expose the capital outlay/debt service state revenue (f-33 item C11)
    # subtracted in the state revenue adjustment above; zero-filled rather
    # than NA-ed because it feeds that arithmetic
    rev_state_cap_debt = c11
  ) |>
  # create pp vars
  mutate(
    rev_local_pp = rev_local / enroll,
    rev_state_pp = rev_state / enroll,
    rev_fed_pp = rev_fed / enroll,
    rev_total_pp = rev_total / enroll,
    # unadjusted per-pupil revenue so users can compare adjusted vs.
    # unadjusted values directly
    rev_state_unadj_pp = rev_state_unadj / enroll,
    rev_local_unadj_pp = rev_local_unadj / enroll,
    # share of unadjusted total revenue paid to other systems (private
    # schools, charters, other leas) -- makes the magnitude of the
    # proportional adjustment visible
    osp_pct = other_sys_pay / rev_total_unadj,
    # include as a check on this new calculation
    # other_sys_pp = other_sys_pay / enroll,
    exp_cur_pp = exp_cur_total / enroll,
    # capital outlay per pupil (single-year values are lumpy -- see README)
    exp_cap_total_pp = exp_cap_total / enroll,
    rev_exp_pp_diff = rev_total_pp - exp_cur_pp
  ) |>
  # rename columns
  rename(
    exp_pay_private_sch = v91, 
    exp_pay_charter_sch = v92, 
    exp_pay_other_lea = q11, 
    exp_other_sys_pay = other_sys_pay,

  ) |> 
  # select and arrange final columns
  select(
    ncesid, year, state, dist_name, enroll,
    rev_total_pp, rev_local_pp, rev_state_pp, rev_fed_pp,
    rev_total, rev_local, rev_state, rev_fed,
    rev_total_unadj, rev_local_unadj, rev_state_unadj, rev_fed_unadj,
    rev_state_unadj_pp, rev_local_unadj_pp,
    # placed above lea_type_id so it also lands in the skinny file, letting
    # skinny users reconstruct the state revenue adjustment
    rev_state_cap_debt,

    exp_cur_pp, exp_cap_total_pp, rev_exp_pp_diff,
    exp_cur_st_loc, exp_cur_fed, exp_cur_resa, exp_cur_total, exp_cap_total,
    cpi_sy12, 
    mhi, mean_hhi, mpv,
    adult_pop, ba_plus_pop, ba_plus_pct,
    gini, owner_pct, snap_pct, unemp_rate,
    total_pop, student_pop,
    stpov_pop, stpov_pct, cong_dist,
    state_leaid, county, cbsa,
    urbanicity_raw, urbanicity_raw_cat, urbanicity,
    schlev, lea_type, lea_type_id,

    exp_emp_salary, exp_emp_bene, exp_textbooks, 
    exp_utilities, exp_tech_supp, exp_tech_equip,
    exp_pay_private_sch, exp_pay_charter_sch,
    exp_pay_other_lea, exp_other_sys_pay,
    osp_pct,

    exp_instr_total, exp_instr_sal, exp_instr_bene,
    exp_supp_stu_total, exp_supp_stu_sal, exp_supp_stu_bene,
    exp_supp_instr_total, exp_supp_instr_sal, exp_supp_instr_bene,
    exp_supp_gen_admin_total, exp_supp_gen_admin_sal, exp_supp_gen_admin_bene,
    exp_supp_sch_admin_total, exp_supp_sch_admin_sal, exp_supp_sch_admin_bene,
    exp_supp_ops_total, exp_supp_ops_sal, exp_supp_ops_bene,
    exp_supp_trans_total, exp_supp_trans_sal, exp_supp_trans_bene,
    exp_central_serv_total, exp_central_serv_sal, exp_central_serv_bene,
    exp_noninstr_food_total, exp_noninstr_food_sal, exp_noninstr_food_bene,
    exp_noninstr_ent_ops_total, exp_noninstr_ent_ops_bene,
    exp_noninstr_other,
    
    exp_covid_total,
    exp_covid_instr, exp_covid_supp, exp_covid_cap_out,
    exp_covid_tech_supp, exp_covid_tech_equip,
    exp_covid_supp_plant, exp_covid_food,

    # capital detail, debt & fund balances (full only; exp_cap_total and
    # exp_cap_total_pp are placed above so they also land in the skinny file)
    exp_cap_construction, exp_cap_land,
    exp_cap_equip_instr, exp_cap_equip_other, exp_cap_equip_nonspec,
    exp_debt_interest,
    debt_lt_begin, debt_lt_issued, debt_lt_retired, debt_lt_end,
    debt_st_begin, debt_st_end,
    fund_bal_debt_svc, fund_bal_bond, fund_bal_other,

    # CWIFT labor-cost index (cwift_est + cwift_imputed also added to skinny)
    cwift_est, cwift_se, cwift_imputed, cwift_impute_method

  ) |>
  # join the year-specific revenue-outlier thresholds (CPI-adjusted to 2012
  # dollars) so the exclusion logic compares against them by year rather than
  # by positional index -- this stays correct as new years are added
  left_join(
    cpi_exclusions_sy12 |> select(year, exclude_lo, exclude_hi),
    by = "year"
  ) |>
  left_join(lea_type_next, by = c("ncesid", "year")) |>
  # id leas for exclusion
  mutate(
    exclusion_cat = case_when(
      # no same-year directory row (closed or not yet in the LEA universe)
      is.na(lea_type_id) ~ "LEA Type",

      # lea type outliers; a same-vintage miscode alone does not exclude a
      # district -- the following vintage must agree (rows the next vintage
      # codes as a regular district/supervisory union/charter are kept), and
      # the vetted MA regionals are exempt (miscoded in both vintages
      # FY2012-FY2015; see ma_regional_rescue above)
      !lea_type_id %in% c(1, 2, 3, 7) &
        !lea_type_id_next %in% c(1, 2, 3, 7) &
        !ncesid %in% ma_regional_rescue ~ "LEA Type",

      # sch type outliers
      !schlev %in% c("01", "02", "03") &
        # create exceptions for CA districts mis-labeled in 2019
        !ncesid %in% c(
          "0601330", # modesto
          "0601329" # santa rosa
        ) ~ "schtype",

      # high revenue outliers
      rev_total_pp > exclude_hi ~ "Over",

      # low revenue outliers
      rev_total_pp < exclude_lo ~ "Under",
      TRUE ~ "Safe"
    )
  ) |>
  # drop the joined threshold and lea-type helper columns
  select(-exclude_lo, -exclude_hi, -lea_type_id_next)

edfinr_data_fy12_fy23_clean <- edfinr_data_fy12_fy23_pre_exclusion |>
  # filter out revenue outliers
  filter(exclusion_cat == "Safe") |>
  # filter out semi-private CT schools: gilbert, NFA, woodstock
  filter(!ncesid %in% c("0905371", "0905372", "0905373")) |>
  select(-exclusion_cat)

exclusion_leas <- edfinr_data_fy12_fy23_pre_exclusion |>
  filter(exclusion_cat != "Safe")

# flag district-years where the c11-driven state revenue adjustment removed
# >50% of unadjusted state revenue and the adjustment is >25pp above the
# district's own historical median -- these reflect one-time state capital
# grants (e.g. MA MSBA, CO BEST) rather than changes in operating aid;
# see adjustment_column_anomalies.md for methodology and affected states
dist_med_state_adj <- edfinr_data_fy12_fy23_clean |>
  mutate(state_adj_pct = (rev_state_unadj - rev_state) / rev_state_unadj) |>
  group_by(ncesid) |>
  summarise(med_state_adj_pct = median(state_adj_pct, na.rm = TRUE),
            .groups = "drop")

edfinr_data_fy12_fy23_clean <- edfinr_data_fy12_fy23_clean |>
  mutate(state_adj_pct = (rev_state_unadj - rev_state) / rev_state_unadj) |>
  left_join(dist_med_state_adj, by = "ncesid") |>
  mutate(
    c11_spike_flag = state_adj_pct > 0.5 &
      state_adj_pct > med_state_adj_pct + 0.25
  ) |>
  select(-state_adj_pct, -med_state_adj_pct)

# create df sans expenditure detail
edfinr_data_fy12_fy23_skinny <- edfinr_data_fy12_fy23_clean |>
  select(ncesid:lea_type_id, osp_pct, c11_spike_flag, cwift_est, cwift_imputed)

# export data -----
# parquet (gzip) for smaller, columnar hosted downloads; factor columns are
# written as-is and reconstructed on the package read side (see EDFINR_UPDATE_PLAN.md)
write_parquet(edfinr_data_fy12_fy23_clean, "data/processed/edfinr_data_fy12_fy23_full.parquet", compression = "gzip")
write_parquet(edfinr_data_fy12_fy23_skinny, "data/processed/edfinr_data_fy12_fy23_skinny.parquet", compression = "gzip")

# per-year slices: one file per year per dataset_type (24 total). these let the
# package download only the requested year(s) (~4 MB full / ~3 MB skinny each)
# instead of the full combined file above (~50 MB / ~34 MB); yr = "all" still
# reads the combined file. year is sorted within each slice and factor levels
# are identical across slices, so the package can bind_rows them with no drift.
dir.create("data/processed/by_year", showWarnings = FALSE)
for (yy in sort(unique(edfinr_data_fy12_fy23_clean$year))) {
  write_parquet(
    filter(edfinr_data_fy12_fy23_clean, year == yy),
    sprintf("data/processed/by_year/edfinr_data_fy%s_full.parquet", yy),
    compression = "gzip"
  )
  write_parquet(
    filter(edfinr_data_fy12_fy23_skinny, year == yy),
    sprintf("data/processed/by_year/edfinr_data_fy%s_skinny.parquet", yy),
    compression = "gzip"
  )
}
