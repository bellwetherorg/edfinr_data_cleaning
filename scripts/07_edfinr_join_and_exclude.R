# 07_edfinr_join_and_exclude.R

# load --------
library(tidyverse)

options(scipen = 999)

# load acs elementary data
acs_fy12_fy22_elementary <- read_rds("data/processed/acs_fy12_fy22_elementary.rds")

# load acs secondary data
acs_fy12_fy22_secondary <- read_rds("data/processed/acs_fy12_fy22_secondary.rds")

# load acs unified data
acs_fy12_fy22_unified <- read_rds("data/processed/acs_fy12_fy22_unified.rds")

# load ccd data
dir_sy12_sy22 <- read_rds("data/processed/dir_sy12_sy22.rds") |>
  mutate(year = as.character(year)) |>
  select(-enroll, -state)

# load f33 data
f33_sy12_sy22 <- read_rds("data/processed/f33_sy12_sy22.rds") |>
  select(-dist_name)

# load saipe data
saipe_fy12_fy22_clean <- read_rds("data/processed/saipe_fy12_fy22_clean.rds") |>
  select(-state, -dist_name)

# load cpi exclusion data
cpi_exclusions_sy12 <- read_rds("data/processed/cpi_exclusions_sy12.rds")

# unify acs data -----

acs_fy12_fy22_all <- bind_rows(
  acs_fy12_fy22_elementary,
  acs_fy12_fy22_secondary,
  acs_fy12_fy22_unified
) |>
  select(-dist_name, -state)

# join data ------
# there are 208,749 records included in this data frame
edfinr_join_fy12_fy22 <- f33_sy12_sy22 |>
  left_join(dir_sy12_sy22, by = c("ncesid", "year")) |>
  left_join(acs_fy12_fy22_all, by = c("ncesid", "year")) |>
  left_join(saipe_fy12_fy22_clean, by = c("ncesid", "year")) |>
  left_join(cpi_exclusions_sy12 |> select("year", "cpi_sy12"), by = "year") |>
  select(ncesid, year, state, county, dist_name, state_leaid, enroll, everything())


# examine incomplete data -------

# there are 21,986 districts and charter schools with less than 0 enrollment
exclude_no_enroll <- edfinr_join_fy12_fy22 |>
  filter(enroll < 0)

# there are 17,963 districts and charters with less than 0 reported total revenue
exclude_no_total_rev <- edfinr_join_fy12_fy22 |>
  filter(rev_total < 0)

# there are 20,202 lea_type outliers
exclude_lea_type <- edfinr_join_fy12_fy22 |>
  filter(!lea_type_id %in% c(1, 2, 3, 7))

# there are 25,236 sch_type outliers
exclude_sch_type <- edfinr_join_fy12_fy22 |>
  filter(!schlev %in% c("01", "02", "03"))

# clean data ----

# we started with 208,749 districts and charter schools
edfinr_data_fy12_fy22_pre_exclusion <- edfinr_join_fy12_fy22 |>
  # initial exclusions
  filter(rev_total > 0) |>
  filter(enroll > 0) |>
  # this reduces the lea total to 178,214
  # apply revenue adjustments
  mutate(
    rev_state_adj_temp = rev_state - c11, # subtract capital/debt service
    rev_local_adj_temp = rev_local - u11, # subtract property sales
    # add tx pre-2013 adjustment to subtract l12 from local revenue
    rev_local_adj_temp = case_when(
      year < 2013 & state == "TX" ~ rev_local_adj_temp - l12,
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
    # include as a check on this new calculation
    # other_sys_pp = other_sys_pay / enroll,
    exp_cur_pp = exp_cur_total / enroll,
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
    
    exp_cur_pp, rev_exp_pp_diff,
    exp_cur_st_loc, exp_cur_fed, exp_cur_resa, exp_cur_total,
    cpi_sy12, 
    mhi, mpv, 
    adult_pop, ba_plus_pop, ba_plus_pct,
    total_pop, student_pop,
    stpov_pop, stpov_pct, cong_dist,
    state_leaid, county, cbsa, urbanicity,
    schlev, lea_type, lea_type_id,

    exp_emp_salary, exp_emp_bene, exp_textbooks, 
    exp_utilities, exp_tech_supp, exp_tech_equip,
    exp_pay_private_sch, exp_pay_charter_sch,
    exp_pay_other_lea, exp_other_sys_pay,

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
    exp_covid_supp_plant, exp_covid_food

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
      year == 2012 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[1] ~ "Over",
      year == 2013 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[2] ~ "Over",
      year == 2014 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[3] ~ "Over",
      year == 2015 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[4] ~ "Over",
      year == 2016 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[5] ~ "Over",
      year == 2017 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[6] ~ "Over",
      year == 2018 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[7] ~ "Over",
      year == 2019 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[8] ~ "Over",
      year == 2020 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[9] ~ "Over",
      year == 2021 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[10] ~ "Over",
      year == 2022 & rev_total_pp > cpi_exclusions_sy12$exclude_hi[11] ~ "Over",

      # low revenue outliers
      year == 2012 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[1] ~ "Under",
      year == 2013 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[2] ~ "Under",
      year == 2014 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[3] ~ "Under",
      year == 2015 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[4] ~ "Under",
      year == 2016 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[5] ~ "Under",
      year == 2017 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[6] ~ "Under",
      year == 2018 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[7] ~ "Under",
      year == 2019 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[8] ~ "Under",
      year == 2020 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[9] ~ "Under",
      year == 2021 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[10] ~ "Under",
      year == 2022 & rev_total_pp < cpi_exclusions_sy12$exclude_lo[11] ~ "Under",
      TRUE ~ "Safe"
    )
  )

edfinr_data_fy12_fy22_clean <- edfinr_data_fy12_fy22_pre_exclusion |>
  # filter out revenue outliers
  filter(exclusion_cat == "Safe") |>
  # filter out semi-private CT schools: gilbert, NFA, woodstock
  filter(!ncesid %in% c("0905371", "0905372", "0905373")) |>
  select(-exclusion_cat)

exclusion_leas <- edfinr_data_fy12_fy22_pre_exclusion |>
  filter(exclusion_cat != "Safe")

# create df sans expenditure detail
edfinr_data_fy12_fy22_skinny <- edfinr_data_fy12_fy22_clean |> 
  select(ncesid:lea_type_id)

# export data -----
write_rds(edfinr_data_fy12_fy22_clean, "data/processed/edfinr_data_fy12_fy22_full.rds")
write_rds(edfinr_data_fy12_fy22_skinny, "data/processed/edfinr_data_fy12_fy22_skinny.rds")
