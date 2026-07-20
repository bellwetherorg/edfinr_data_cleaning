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

# load f33 data
f33_sy12_sy23 <- read_rds("data/processed/f33_sy12_sy23.rds") |>
  select(-dist_name)

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
    -c11, -u11, -c24, -l12, -m12, -d11, 
    -rev_state_adj_temp, -rev_local_adj_temp,
    -rev_total_adj_temp, -state_adj_pct, -local_adj_pct, -fed_adj_pct
  ) |>
    # rename adjusted rev columms
  rename(
    rev_local = rev_local_adj,
    rev_state = rev_state_adj,
    rev_fed = rev_fed_adj,
    rev_total = rev_total_adj
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
  # id leas for exclusion
  mutate(
    exclusion_cat = case_when(
      # lea type outliers
      !lea_type_id %in% c(1, 2, 3, 7) ~ "LEA Type",

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
  # drop the joined threshold helper columns
  select(-exclude_lo, -exclude_hi)

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
