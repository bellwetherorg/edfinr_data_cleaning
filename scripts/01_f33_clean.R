# 01_f33_clean.R
# 2024-09-20

# load --------
library(tidyverse)
options(scipen = 999)

# load nces f33 data
f33_sy12_raw <- read_tsv("data/raw/ccd/sdf121a.txt")
f33_sy13_raw <- read_tsv("data/raw/ccd/sdf13_1a.txt")
f33_sy14_raw <- read_tsv("data/raw/ccd/Sdf14_1a.txt")
f33_sy15_raw <- read_tsv("data/raw/ccd/sdf15_1a.txt")
f33_sy16_raw <- read_tsv("data/raw/ccd/Sdf16_1a.txt")
f33_sy17_raw <- read_tsv("data/raw/ccd/sdf17_1a.txt")
f33_sy18_raw <- read_tsv("data/raw/ccd/sdf18_1a.txt")
f33_sy19_raw <- read_tsv("data/raw/ccd/sdf19_2a.txt")
f33_sy20_raw <- read_tsv("data/raw/ccd/sdf20_1a.txt")
f33_sy21_raw <- read_tsv("data/raw/ccd/sdf21_1a.txt")
f33_sy22_raw <- read_tsv("data/raw/ccd/sdf22_1a.txt")
f33_sy23_raw <- read_tsv("data/raw/ccd/sdf23_1a.txt")

# clean ----------

# create function to replace '-1' and '-2' codes with NA
clean_na <- function(x) {

  new_val <- case_when(
    x == -1 ~ NA,
    x == -2 ~ NA,
    TRUE ~ x
  )

  return(new_val)

}


# create cleaning function for sy12-sy14
clean_f33_pre_essa <- function(df) {
  df |>
    rename_with(tolower) |>
    rename(
      state = stabbr,
      ncesid = leaid,
      dist_name = name,
      # year = yrdata,
      enroll = v33,
      rev_total = totalrev,
      rev_local = tlocrev,
      rev_state = tstrev,
      rev_fed = tfedrev,
      # total current elsec expenditure (TCURELSC); the ESSA fund-type
      # split (CE1/CE2/CE3) does not exist before SY16
      exp_cur_total = tcurelsc,

      # part x
      exp_emp_salary = z32,
      exp_emp_bene = z34,
      exp_textbooks = v93,
      # part ii
      exp_instr_total = e13, 
      exp_instr_sal = z33,
      exp_instr_bene = v10,
      exp_supp_stu_total = e17,
      exp_supp_stu_sal = v11,
      exp_supp_stu_bene = v12,
      exp_supp_instr_total = e07,
      exp_supp_instr_sal = v13,
      exp_supp_instr_bene = v14,
      exp_supp_gen_admin_total = e08,
      exp_supp_gen_admin_sal = v15,
      exp_supp_gen_admin_bene = v16,
      exp_supp_sch_admin_total = e09,
      exp_supp_sch_admin_sal = v17,
      exp_supp_sch_admin_bene = v18,
      exp_supp_ops_total = v40,
      exp_supp_ops_sal = v21,
      exp_supp_ops_bene = v22,
      exp_supp_trans_total = v45,
      exp_supp_trans_sal = v23,
      exp_supp_trans_bene = v24,
      exp_central_serv_total = v90,
      exp_central_serv_sal = v37,
      exp_central_serv_bene = v38,
      exp_noninstr_food_total = e11,
      exp_noninstr_food_sal = v29,
      exp_noninstr_food_bene = v30,
      exp_noninstr_ent_ops_total = v60,
      exp_noninstr_ent_ops_bene = v32,
      exp_noninstr_other = v65,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total = tcapout, # total capital outlay
      exp_cap_construction = f12, # construction
      exp_cap_land = g15, # land & existing structures
      exp_cap_equip_instr = k09, # instructional equipment
      exp_cap_equip_other = k10, # other equipment
      exp_cap_equip_nonspec = k11, # nonspecified equipment
      exp_debt_interest = i86, # interest on debt
      debt_lt_begin = `_19h`, # long-term debt outstanding, beginning of fy
      debt_lt_issued = `_21f`, # long-term debt issued during fy
      debt_lt_retired = `_31f`, # long-term debt retired during fy
      debt_lt_end = `_41f`, # long-term debt outstanding, end of fy
      debt_st_begin = `_61v`, # short-term debt outstanding, beginning of fy
      debt_st_end = `_66v`, # short-term debt outstanding, end of fy
      fund_bal_debt_svc = w01, # debt service fund cash & securities, fye
      fund_bal_bond = w31, # bond fund cash & securities, fye
      fund_bal_other = w61 # other funds cash & securities, fye

    ) |>
    select(
      ncesid, dist_name, year, state, cbsa, schlev, enroll,
      rev_total, rev_local, rev_state, rev_fed,
      c11, # capital outlay + debt service
      u11, # sale of property
      v91, # payments to private schools
      v92, # payments to charter schools
      c24, # census state/nces local revenue
      l12, # payments to state govt
      m12, # payment to local govts
      d11, # rev from other school systems
      q11, # payment to other school systems
      exp_cur_total,

      exp_emp_salary,
      exp_emp_bene,
      exp_textbooks,

      exp_instr_total, 
      exp_instr_sal,
      exp_instr_bene,
      exp_supp_stu_total,
      exp_supp_stu_sal,
      exp_supp_stu_bene,
      exp_supp_instr_total,
      exp_supp_instr_sal,
      exp_supp_instr_bene,
      exp_supp_gen_admin_total,
      exp_supp_gen_admin_sal,
      exp_supp_gen_admin_bene,
      exp_supp_sch_admin_total,
      exp_supp_sch_admin_sal,
      exp_supp_sch_admin_bene,
      exp_supp_ops_total,
      exp_supp_ops_sal,
      exp_supp_ops_bene,
      exp_supp_trans_total,
      exp_supp_trans_sal,
      exp_supp_trans_bene,
      exp_central_serv_total,
      exp_central_serv_sal,
      exp_central_serv_bene,
      exp_noninstr_food_total,
      exp_noninstr_food_sal,
      exp_noninstr_food_bene,
      exp_noninstr_ent_ops_total,
      exp_noninstr_ent_ops_bene,
      exp_noninstr_other,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total,
      exp_cap_construction,
      exp_cap_land,
      exp_cap_equip_instr,
      exp_cap_equip_other,
      exp_cap_equip_nonspec,
      exp_debt_interest,
      debt_lt_begin,
      debt_lt_issued,
      debt_lt_retired,
      debt_lt_end,
      debt_st_begin,
      debt_st_end,
      fund_bal_debt_svc,
      fund_bal_bond,
      fund_bal_other

    ) |>
    # address -1 and -2 codes in expenditure data
    mutate(across(c11:fund_bal_other, ~clean_na(.x))) |>
    # clean up district name formatting
    mutate(
      dist_name = str_to_title(dist_name),
      # convert year to 4 digit
      year = paste0("20", year),
      # make sure enrollment is a numeric variable
      enroll = as.numeric(enroll),
      # transform rev/exp data into $ instead of 1000s of $
      # across(rev_total:q11, ~ .x * 1000)
    )
}

# create cleaning function for sy15
clean_f33_pre_essa2 <- function(df) {
  df |>
    rename_with(tolower) |>
    rename(
      state = stabbr,
      ncesid = leaid,
      dist_name = name,
      # year = yrdata,
      enroll = v33,
      rev_total = totalrev,
      rev_local = tlocrev,
      rev_state = tstrev,
      rev_fed = tfedrev,
      # total current elsec expenditure (TCURELSC); the ESSA fund-type
      # split (CE1/CE2/CE3) does not exist before SY16
      exp_cur_total = tcurelsc,

      # part x
      exp_emp_salary = z32,
      exp_emp_bene = z34,
      exp_textbooks = v93,
      exp_utilities = v95,
      exp_tech_supp = v02,
      exp_tech_equip = k14,
      # part ii
      exp_instr_total = e13, 
      exp_instr_sal = z33,
      exp_instr_bene = v10,
      exp_supp_stu_total = e17,
      exp_supp_stu_sal = v11,
      exp_supp_stu_bene = v12,
      exp_supp_instr_total = e07,
      exp_supp_instr_sal = v13,
      exp_supp_instr_bene = v14,
      exp_supp_gen_admin_total = e08,
      exp_supp_gen_admin_sal = v15,
      exp_supp_gen_admin_bene = v16,
      exp_supp_sch_admin_total = e09,
      exp_supp_sch_admin_sal = v17,
      exp_supp_sch_admin_bene = v18,
      exp_supp_ops_total = v40,
      exp_supp_ops_sal = v21,
      exp_supp_ops_bene = v22,
      exp_supp_trans_total = v45,
      exp_supp_trans_sal = v23,
      exp_supp_trans_bene = v24,
      exp_central_serv_total = v90,
      exp_central_serv_sal = v37,
      exp_central_serv_bene = v38,
      exp_noninstr_food_total = e11,
      exp_noninstr_food_sal = v29,
      exp_noninstr_food_bene = v30,
      exp_noninstr_ent_ops_total = v60,
      exp_noninstr_ent_ops_bene = v32,
      exp_noninstr_other = v65,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total = tcapout, # total capital outlay
      exp_cap_construction = f12, # construction
      exp_cap_land = g15, # land & existing structures
      exp_cap_equip_instr = k09, # instructional equipment
      exp_cap_equip_other = k10, # other equipment
      exp_cap_equip_nonspec = k11, # nonspecified equipment
      exp_debt_interest = i86, # interest on debt
      debt_lt_begin = `_19h`, # long-term debt outstanding, beginning of fy
      debt_lt_issued = `_21f`, # long-term debt issued during fy
      debt_lt_retired = `_31f`, # long-term debt retired during fy
      debt_lt_end = `_41f`, # long-term debt outstanding, end of fy
      debt_st_begin = `_61v`, # short-term debt outstanding, beginning of fy
      debt_st_end = `_66v`, # short-term debt outstanding, end of fy
      fund_bal_debt_svc = w01, # debt service fund cash & securities, fye
      fund_bal_bond = w31, # bond fund cash & securities, fye
      fund_bal_other = w61 # other funds cash & securities, fye

    ) |>
    select(
      ncesid, dist_name, year, state, cbsa, schlev, enroll,
      rev_total, rev_local, rev_state, rev_fed,
      c11, # capital outlay + debt service
      u11, # sale of property
      v91, # payments to private schools
      v92, # payments to charter schools
      c24, # census state/nces local revenue
      l12, # payments to state govt
      m12, # payment to local govts
      d11, # rev from other school systems
      q11, # payment to other school systems
      exp_cur_total,

      exp_emp_salary,
      exp_emp_bene,
      exp_textbooks,
      exp_utilities,
      exp_tech_supp,
      exp_tech_equip,

      exp_instr_total, 
      exp_instr_sal,
      exp_instr_bene,
      exp_supp_stu_total,
      exp_supp_stu_sal,
      exp_supp_stu_bene,
      exp_supp_instr_total,
      exp_supp_instr_sal,
      exp_supp_instr_bene,
      exp_supp_gen_admin_total,
      exp_supp_gen_admin_sal,
      exp_supp_gen_admin_bene,
      exp_supp_sch_admin_total,
      exp_supp_sch_admin_sal,
      exp_supp_sch_admin_bene,
      exp_supp_ops_total,
      exp_supp_ops_sal,
      exp_supp_ops_bene,
      exp_supp_trans_total,
      exp_supp_trans_sal,
      exp_supp_trans_bene,
      exp_central_serv_total,
      exp_central_serv_sal,
      exp_central_serv_bene,
      exp_noninstr_food_total,
      exp_noninstr_food_sal,
      exp_noninstr_food_bene,
      exp_noninstr_ent_ops_total,
      exp_noninstr_ent_ops_bene,
      exp_noninstr_other,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total,
      exp_cap_construction,
      exp_cap_land,
      exp_cap_equip_instr,
      exp_cap_equip_other,
      exp_cap_equip_nonspec,
      exp_debt_interest,
      debt_lt_begin,
      debt_lt_issued,
      debt_lt_retired,
      debt_lt_end,
      debt_st_begin,
      debt_st_end,
      fund_bal_debt_svc,
      fund_bal_bond,
      fund_bal_other

    ) |>
    # address -1 and -2 codes in expenditure data
    mutate(across(c11:fund_bal_other, ~clean_na(.x))) |>
    # clean up district name formatting
    mutate(
      dist_name = str_to_title(dist_name),
      # convert year to 4 digit
      year = paste0("20", year),
      # make sure enrollment is a numeric variable
      enroll = as.numeric(enroll),
      # transform rev/exp data into $ instead of 1000s of $
      # across(rev_total:q11, ~ .x * 1000)
    )
}

# create cleaning function for sy16-sy17
clean_f33_essa <- function(df) {
  df |>
    rename_with(tolower) |>
    rename(
      state = stabbr,
      ncesid = leaid,
      dist_name = name,
      # year = yrdata,
      enroll = v33,
      rev_total = totalrev,
      rev_local = tlocrev,
      rev_state = tstrev,
      rev_fed = tfedrev,
      # total current elsec expenditure (TCURELSC); CE1/CE2 are the ESSA
      # fund-type split, unreported by some states (see README)
      exp_cur_total = tcurelsc,
      exp_cur_st_loc = ce1,
      exp_cur_fed = ce2,
      # part x
      exp_emp_salary = z32,
      exp_emp_bene = z34,
      exp_textbooks = v93,
      exp_utilities = v95,
      exp_tech_supp = v02,
      exp_tech_equip = k14,
      # part ii
      exp_instr_total = e13, 
      exp_instr_sal = z33,
      exp_instr_bene = v10,
      exp_supp_stu_total = e17,
      exp_supp_stu_sal = v11,
      exp_supp_stu_bene = v12,
      exp_supp_instr_total = e07,
      exp_supp_instr_sal = v13,
      exp_supp_instr_bene = v14,
      exp_supp_gen_admin_total = e08,
      exp_supp_gen_admin_sal = v15,
      exp_supp_gen_admin_bene = v16,
      exp_supp_sch_admin_total = e09,
      exp_supp_sch_admin_sal = v17,
      exp_supp_sch_admin_bene = v18,
      exp_supp_ops_total = v40,
      exp_supp_ops_sal = v21,
      exp_supp_ops_bene = v22,
      exp_supp_trans_total = v45,
      exp_supp_trans_sal = v23,
      exp_supp_trans_bene = v24,
      exp_central_serv_total = v90,
      exp_central_serv_sal = v37,
      exp_central_serv_bene = v38,
      exp_noninstr_food_total = e11,
      exp_noninstr_food_sal = v29,
      exp_noninstr_food_bene = v30,
      exp_noninstr_ent_ops_total = v60,
      exp_noninstr_ent_ops_bene = v32,
      exp_noninstr_other = v65,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total = tcapout, # total capital outlay
      exp_cap_construction = f12, # construction
      exp_cap_land = g15, # land & existing structures
      exp_cap_equip_instr = k09, # instructional equipment
      exp_cap_equip_other = k10, # other equipment
      exp_cap_equip_nonspec = k11, # nonspecified equipment
      exp_debt_interest = i86, # interest on debt
      debt_lt_begin = `_19h`, # long-term debt outstanding, beginning of fy
      debt_lt_issued = `_21f`, # long-term debt issued during fy
      debt_lt_retired = `_31f`, # long-term debt retired during fy
      debt_lt_end = `_41f`, # long-term debt outstanding, end of fy
      debt_st_begin = `_61v`, # short-term debt outstanding, beginning of fy
      debt_st_end = `_66v`, # short-term debt outstanding, end of fy
      fund_bal_debt_svc = w01, # debt service fund cash & securities, fye
      fund_bal_bond = w31, # bond fund cash & securities, fye
      fund_bal_other = w61 # other funds cash & securities, fye

    ) |>
    select(
      ncesid, dist_name, year, state, cbsa, schlev, enroll,
      rev_total, rev_local, rev_state, rev_fed,
      c11, # capital outlay + debt service
      u11, # sale of property
      v91, # payments to private schools
      v92, # payments to charter schools
      c24, # census state/nces local revenue
      l12, # payments to state govt
      m12, # payment to local govts
      d11, # rev from other school systems
      q11, # payment to other school systems
      exp_cur_total,
      exp_cur_st_loc,
      exp_cur_fed,

      exp_emp_salary,
      exp_emp_bene,
      exp_textbooks,
      exp_utilities,
      exp_tech_supp,
      exp_tech_equip,

      exp_instr_total, 
      exp_instr_sal,
      exp_instr_bene,
      exp_supp_stu_total,
      exp_supp_stu_sal,
      exp_supp_stu_bene,
      exp_supp_instr_total,
      exp_supp_instr_sal,
      exp_supp_instr_bene,
      exp_supp_gen_admin_total,
      exp_supp_gen_admin_sal,
      exp_supp_gen_admin_bene,
      exp_supp_sch_admin_total,
      exp_supp_sch_admin_sal,
      exp_supp_sch_admin_bene,
      exp_supp_ops_total,
      exp_supp_ops_sal,
      exp_supp_ops_bene,
      exp_supp_trans_total,
      exp_supp_trans_sal,
      exp_supp_trans_bene,
      exp_central_serv_total,
      exp_central_serv_sal,
      exp_central_serv_bene,
      exp_noninstr_food_total,
      exp_noninstr_food_sal,
      exp_noninstr_food_bene,
      exp_noninstr_ent_ops_total,
      exp_noninstr_ent_ops_bene,
      exp_noninstr_other,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total,
      exp_cap_construction,
      exp_cap_land,
      exp_cap_equip_instr,
      exp_cap_equip_other,
      exp_cap_equip_nonspec,
      exp_debt_interest,
      debt_lt_begin,
      debt_lt_issued,
      debt_lt_retired,
      debt_lt_end,
      debt_st_begin,
      debt_st_end,
      fund_bal_debt_svc,
      fund_bal_bond,
      fund_bal_other
    ) |>
    # address -1 and -2 codes in expenditure data
    mutate(across(c11:fund_bal_other, ~clean_na(.x))) |> 
    # clean up district name formatting
    mutate(
      dist_name = str_to_title(dist_name),
      # convert year to 4 digit
      year = paste0("20", year),
      # make sure enrollment is a numeric variable
      enroll = as.numeric(enroll)
    )
}

# create cleaning function for sy18-sy19
clean_f33_essa2 <- function(df) {
  df |>
    rename_with(tolower) |>
    rename(
      state = stabbr,
      ncesid = leaid,
      dist_name = name,
      # year = yrdata,
      enroll = v33,
      rev_total = totalrev,
      rev_local = tlocrev,
      rev_state = tstrev,
      rev_fed = tfedrev,
      # total current elsec expenditure (TCURELSC); CE1/CE2/CE3 are the ESSA
      # fund-type split, unreported by some states (see README)
      exp_cur_total = tcurelsc,
      exp_cur_st_loc = ce1,
      exp_cur_fed = ce2,
      exp_cur_resa = ce3,
      # part x
      exp_emp_salary = z32,
      exp_emp_bene = z34,
      exp_textbooks = v93,
      exp_utilities = v95,
      exp_tech_supp = v02,
      exp_tech_equip = k14,
      # part ii
      exp_instr_total = e13, 
      exp_instr_sal = z33,
      exp_instr_bene = v10,
      exp_supp_stu_total = e17,
      exp_supp_stu_sal = v11,
      exp_supp_stu_bene = v12,
      exp_supp_instr_total = e07,
      exp_supp_instr_sal = v13,
      exp_supp_instr_bene = v14,
      exp_supp_gen_admin_total = e08,
      exp_supp_gen_admin_sal = v15,
      exp_supp_gen_admin_bene = v16,
      exp_supp_sch_admin_total = e09,
      exp_supp_sch_admin_sal = v17,
      exp_supp_sch_admin_bene = v18,
      exp_supp_ops_total = v40,
      exp_supp_ops_sal = v21,
      exp_supp_ops_bene = v22,
      exp_supp_trans_total = v45,
      exp_supp_trans_sal = v23,
      exp_supp_trans_bene = v24,
      exp_central_serv_total = v90,
      exp_central_serv_sal = v37,
      exp_central_serv_bene = v38,
      exp_noninstr_food_total = e11,
      exp_noninstr_food_sal = v29,
      exp_noninstr_food_bene = v30,
      exp_noninstr_ent_ops_total = v60,
      exp_noninstr_ent_ops_bene = v32,
      exp_noninstr_other = v65,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total = tcapout, # total capital outlay
      exp_cap_construction = f12, # construction
      exp_cap_land = g15, # land & existing structures
      exp_cap_equip_instr = k09, # instructional equipment
      exp_cap_equip_other = k10, # other equipment
      exp_cap_equip_nonspec = k11, # nonspecified equipment
      exp_debt_interest = i86, # interest on debt
      debt_lt_begin = `_19h`, # long-term debt outstanding, beginning of fy
      debt_lt_issued = `_21f`, # long-term debt issued during fy
      debt_lt_retired = `_31f`, # long-term debt retired during fy
      debt_lt_end = `_41f`, # long-term debt outstanding, end of fy
      debt_st_begin = `_61v`, # short-term debt outstanding, beginning of fy
      debt_st_end = `_66v`, # short-term debt outstanding, end of fy
      fund_bal_debt_svc = w01, # debt service fund cash & securities, fye
      fund_bal_bond = w31, # bond fund cash & securities, fye
      fund_bal_other = w61 # other funds cash & securities, fye

    ) |>
    select(
      ncesid, dist_name, year, state, cbsa, schlev, enroll,
      rev_total, rev_local, rev_state, rev_fed,
      c11, # capital outlay + debt service
      u11, # sale of property
      v91, # payments to private schools
      v92, # payments to charter schools
      c24, # census state/nces local revenue
      l12, # payments to state govt
      m12, # payment to local govts
      d11, # rev from other school systems
      q11, # payment to other school systems
      exp_cur_total,
      exp_cur_st_loc,
      exp_cur_fed,
      exp_cur_resa,

      exp_emp_salary,
      exp_emp_bene,
      exp_textbooks,
      exp_utilities,
      exp_tech_supp,
      exp_tech_equip,

      exp_instr_total, 
      exp_instr_sal,
      exp_instr_bene,
      exp_supp_stu_total,
      exp_supp_stu_sal,
      exp_supp_stu_bene,
      exp_supp_instr_total,
      exp_supp_instr_sal,
      exp_supp_instr_bene,
      exp_supp_gen_admin_total,
      exp_supp_gen_admin_sal,
      exp_supp_gen_admin_bene,
      exp_supp_sch_admin_total,
      exp_supp_sch_admin_sal,
      exp_supp_sch_admin_bene,
      exp_supp_ops_total,
      exp_supp_ops_sal,
      exp_supp_ops_bene,
      exp_supp_trans_total,
      exp_supp_trans_sal,
      exp_supp_trans_bene,
      exp_central_serv_total,
      exp_central_serv_sal,
      exp_central_serv_bene,
      exp_noninstr_food_total,
      exp_noninstr_food_sal,
      exp_noninstr_food_bene,
      exp_noninstr_ent_ops_total,
      exp_noninstr_ent_ops_bene,
      exp_noninstr_other,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total,
      exp_cap_construction,
      exp_cap_land,
      exp_cap_equip_instr,
      exp_cap_equip_other,
      exp_cap_equip_nonspec,
      exp_debt_interest,
      debt_lt_begin,
      debt_lt_issued,
      debt_lt_retired,
      debt_lt_end,
      debt_st_begin,
      debt_st_end,
      fund_bal_debt_svc,
      fund_bal_bond,
      fund_bal_other

    ) |>
    # address -1 and -2 codes in expenditure data
    mutate(
      across(c11:fund_bal_other, ~clean_na(.x))
    ) |> 
    # clean up district name formatting
    mutate(
      dist_name = str_to_title(dist_name),
      # convert year to 4 digit
      year = paste0("20", year),
      # make sure enrollment is a numeric variable
      enroll = as.numeric(enroll)
    )
}

# create cleaning function for sy20
clean_f33_covid <- function(df) {
  df |>
    rename_with(tolower) |>
    rename(
      state = stabbr,
      ncesid = leaid,
      dist_name = name,
      # year = yrdata,
      enroll = v33,
      rev_total = totalrev,
      rev_local = tlocrev,
      rev_state = tstrev,
      rev_fed = tfedrev,
      # total current elsec expenditure (TCURELSC); CE1/CE2/CE3 are the ESSA
      # fund-type split, unreported by some states (see README)
      exp_cur_total = tcurelsc,
      exp_cur_st_loc = ce1,
      exp_cur_fed = ce2,
      exp_cur_resa = ce3,
      # part x
      exp_emp_salary = z32,
      exp_emp_bene = z34,
      exp_textbooks = v93,
      exp_utilities = v95,
      exp_tech_supp = v02,
      exp_tech_equip = k14,
      # part ii
      exp_instr_total = e13, 
      exp_instr_sal = z33,
      exp_instr_bene = v10,
      exp_supp_stu_total = e17,
      exp_supp_stu_sal = v11,
      exp_supp_stu_bene = v12,
      exp_supp_instr_total = e07,
      exp_supp_instr_sal = v13,
      exp_supp_instr_bene = v14,
      exp_supp_gen_admin_total = e08,
      exp_supp_gen_admin_sal = v15,
      exp_supp_gen_admin_bene = v16,
      exp_supp_sch_admin_total = e09,
      exp_supp_sch_admin_sal = v17,
      exp_supp_sch_admin_bene = v18,
      exp_supp_ops_total = v40,
      exp_supp_ops_sal = v21,
      exp_supp_ops_bene = v22,
      exp_supp_trans_total = v45,
      exp_supp_trans_sal = v23,
      exp_supp_trans_bene = v24,
      exp_central_serv_total = v90,
      exp_central_serv_sal = v37,
      exp_central_serv_bene = v38,
      exp_noninstr_food_total = e11,
      exp_noninstr_food_sal = v29,
      exp_noninstr_food_bene = v30,
      exp_noninstr_ent_ops_total = v60,
      exp_noninstr_ent_ops_bene = v32,
      exp_noninstr_other = v65,

      exp_covid_total = ae1, # exp from fed covid-19 funding
      exp_covid_instr = ae2, # exp from fed covid-19 funding, instructional expenditures
      exp_covid_supp = ae3, # exp from fed covid-19 funding, support services
      exp_covid_cap_out = ae4, # exp from fed covid-19 funding, capital outlay
      exp_covid_tech_supp = ae5, # exp from fed covid-19 funding, tech supplies & services
      exp_covid_tech_equip = ae6, # exp from fed covid-19 funding, tech equipment
      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total = tcapout, # total capital outlay
      exp_cap_construction = f12, # construction
      exp_cap_land = g15, # land & existing structures
      exp_cap_equip_instr = k09, # instructional equipment
      exp_cap_equip_other = k10, # other equipment
      exp_cap_equip_nonspec = k11, # nonspecified equipment
      exp_debt_interest = i86, # interest on debt
      debt_lt_begin = `_19h`, # long-term debt outstanding, beginning of fy
      debt_lt_issued = `_21f`, # long-term debt issued during fy
      debt_lt_retired = `_31f`, # long-term debt retired during fy
      debt_lt_end = `_41f`, # long-term debt outstanding, end of fy
      debt_st_begin = `_61v`, # short-term debt outstanding, beginning of fy
      debt_st_end = `_66v`, # short-term debt outstanding, end of fy
      fund_bal_debt_svc = w01, # debt service fund cash & securities, fye
      fund_bal_bond = w31, # bond fund cash & securities, fye
      fund_bal_other = w61 # other funds cash & securities, fye
      
    ) |>
    select(
      ncesid, dist_name, year, state, cbsa, schlev, enroll,
      rev_total, rev_local, rev_state, rev_fed,
      c11, # capital outlay + debt service
      u11, # sale of property
      v91, # payments to private schools
      v92, # payments to charter schools
      c24, # census state/nces local revenue
      l12, # payments to state govt
      m12, # payment to local govts
      d11, # rev from other school systems
      q11, # payment to other school systems
      exp_cur_total,
      exp_cur_st_loc,
      exp_cur_fed,
      exp_cur_resa,
      exp_emp_salary,
      exp_emp_bene,
      exp_textbooks,
      exp_utilities,
      exp_tech_supp,
      exp_tech_equip,

      exp_instr_total, 
      exp_instr_sal,
      exp_instr_bene,
      exp_supp_stu_total,
      exp_supp_stu_sal,
      exp_supp_stu_bene,
      exp_supp_instr_total,
      exp_supp_instr_sal,
      exp_supp_instr_bene,
      exp_supp_gen_admin_total,
      exp_supp_gen_admin_sal,
      exp_supp_gen_admin_bene,
      exp_supp_sch_admin_total,
      exp_supp_sch_admin_sal,
      exp_supp_sch_admin_bene,
      exp_supp_ops_total,
      exp_supp_ops_sal,
      exp_supp_ops_bene,
      exp_supp_trans_total,
      exp_supp_trans_sal,
      exp_supp_trans_bene,
      exp_central_serv_total,
      exp_central_serv_sal,
      exp_central_serv_bene,
      exp_noninstr_food_total,
      exp_noninstr_food_sal,
      exp_noninstr_food_bene,
      exp_noninstr_ent_ops_total,
      exp_noninstr_ent_ops_bene,
      exp_noninstr_other,
      exp_covid_total,
      exp_covid_instr,
      exp_covid_supp,
      exp_covid_cap_out,
      exp_covid_tech_supp,
      exp_covid_tech_equip,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total,
      exp_cap_construction,
      exp_cap_land,
      exp_cap_equip_instr,
      exp_cap_equip_other,
      exp_cap_equip_nonspec,
      exp_debt_interest,
      debt_lt_begin,
      debt_lt_issued,
      debt_lt_retired,
      debt_lt_end,
      debt_st_begin,
      debt_st_end,
      fund_bal_debt_svc,
      fund_bal_bond,
      fund_bal_other

    ) |>
    # address -1 and -2 codes in expenditure data
    mutate(
      across(c11:fund_bal_other, ~clean_na(.x))
    ) |> 
    # clean up district name formatting
    mutate(
      dist_name = str_to_title(dist_name),
      # convert year to 4 digit
      year = paste0("20", year),
      # make sure enrollment is a numeric variable
      enroll = as.numeric(enroll)
    )
}

# create cleaning function for sy21-sy23
# (sy23 layout matches sy22 exactly except for the dropped CENSUSID column,
# which is unused here, so the same cleaner applies)
clean_f33_covid2 <- function(df) {
  df |>
    rename_with(tolower) |>
    rename(
      state = stabbr,
      ncesid = leaid,
      dist_name = name,
      # year = yrdata,
      enroll = v33,
      rev_total = totalrev,
      rev_local = tlocrev,
      rev_state = tstrev,
      rev_fed = tfedrev,
      # total current elsec expenditure (TCURELSC); CE1/CE2/CE3 are the ESSA
      # fund-type split, unreported by some states (see README)
      exp_cur_total = tcurelsc,
      exp_cur_st_loc = ce1,
      exp_cur_fed = ce2,
      exp_cur_resa = ce3,
      # part x
      exp_emp_salary = z32,
      exp_emp_bene = z34,
      exp_textbooks = v93,
      exp_utilities = v95,
      exp_tech_supp = v02,
      exp_tech_equip = k14,
      # part ii
      exp_instr_total = e13, 
      exp_instr_sal = z33,
      exp_instr_bene = v10,
      exp_supp_stu_total = e17,
      exp_supp_stu_sal = v11,
      exp_supp_stu_bene = v12,
      exp_supp_instr_total = e07,
      exp_supp_instr_sal = v13,
      exp_supp_instr_bene = v14,
      exp_supp_gen_admin_total = e08,
      exp_supp_gen_admin_sal = v15,
      exp_supp_gen_admin_bene = v16,
      exp_supp_sch_admin_total = e09,
      exp_supp_sch_admin_sal = v17,
      exp_supp_sch_admin_bene = v18,
      exp_supp_ops_total = v40,
      exp_supp_ops_sal = v21,
      exp_supp_ops_bene = v22,
      exp_supp_trans_total = v45,
      exp_supp_trans_sal = v23,
      exp_supp_trans_bene = v24,
      exp_central_serv_total = v90,
      exp_central_serv_sal = v37,
      exp_central_serv_bene = v38,
      exp_noninstr_food_total = e11,
      exp_noninstr_food_sal = v29,
      exp_noninstr_food_bene = v30,
      exp_noninstr_ent_ops_total = v60,
      exp_noninstr_ent_ops_bene = v32,
      exp_noninstr_other = v65,

      exp_covid_total = ae1, # exp from fed covid-19 funding
      exp_covid_instr = ae2, # exp from fed covid-19 funding, instructional expenditures
      exp_covid_supp = ae3, # exp from fed covid-19 funding, support services
      exp_covid_cap_out = ae4, # exp from fed covid-19 funding, capital outlay
      exp_covid_tech_supp = ae5, # exp from fed covid-19 funding, tech supplies & services
      exp_covid_tech_equip = ae6, # exp from fed covid-19 funding, tech equipment
      exp_covid_supp_plant = ae7, # exp from fed covid-19 funding, support services & plant maintenance
      exp_covid_food = ae8, # exp from fed covid-19 funding, food services
      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total = tcapout, # total capital outlay
      exp_cap_construction = f12, # construction
      exp_cap_land = g15, # land & existing structures
      exp_cap_equip_instr = k09, # instructional equipment
      exp_cap_equip_other = k10, # other equipment
      exp_cap_equip_nonspec = k11, # nonspecified equipment
      exp_debt_interest = i86, # interest on debt
      debt_lt_begin = `_19h`, # long-term debt outstanding, beginning of fy
      debt_lt_issued = `_21f`, # long-term debt issued during fy
      debt_lt_retired = `_31f`, # long-term debt retired during fy
      debt_lt_end = `_41f`, # long-term debt outstanding, end of fy
      debt_st_begin = `_61v`, # short-term debt outstanding, beginning of fy
      debt_st_end = `_66v`, # short-term debt outstanding, end of fy
      fund_bal_debt_svc = w01, # debt service fund cash & securities, fye
      fund_bal_bond = w31, # bond fund cash & securities, fye
      fund_bal_other = w61 # other funds cash & securities, fye
    ) |>
    select(
      ncesid, dist_name, year, state, cbsa, schlev, enroll,
      rev_total, rev_local, rev_state, rev_fed,
      c11, # capital outlay + debt service
      u11, # sale of property
      v91, # payments to private schools
      v92, # payments to charter schools
      c24, # census state/nces local revenue
      l12, # payments to state govt
      m12, # payment to local govts
      d11, # rev from other school systems
      q11, # payment to other school systems
      exp_cur_total,
      exp_cur_st_loc,
      exp_cur_fed,
      exp_cur_resa,
      exp_emp_salary,
      exp_emp_bene,
      exp_textbooks,
      exp_utilities,
      exp_tech_supp,
      exp_tech_equip,

      exp_instr_total, 
      exp_instr_sal,
      exp_instr_bene,
      exp_supp_stu_total,
      exp_supp_stu_sal,
      exp_supp_stu_bene,
      exp_supp_instr_total,
      exp_supp_instr_sal,
      exp_supp_instr_bene,
      exp_supp_gen_admin_total,
      exp_supp_gen_admin_sal,
      exp_supp_gen_admin_bene,
      exp_supp_sch_admin_total,
      exp_supp_sch_admin_sal,
      exp_supp_sch_admin_bene,
      exp_supp_ops_total,
      exp_supp_ops_sal,
      exp_supp_ops_bene,
      exp_supp_trans_total,
      exp_supp_trans_sal,
      exp_supp_trans_bene,
      exp_central_serv_total,
      exp_central_serv_sal,
      exp_central_serv_bene,
      exp_noninstr_food_total,
      exp_noninstr_food_sal,
      exp_noninstr_food_bene,
      exp_noninstr_ent_ops_total,
      exp_noninstr_ent_ops_bene,
      exp_noninstr_other,
      exp_covid_total,
      exp_covid_instr,
      exp_covid_supp,
      exp_covid_cap_out,
      exp_covid_tech_supp,
      exp_covid_tech_equip,
      exp_covid_supp_plant,
      exp_covid_food,

      # capital, debt service & fund balances (F-33 individual-unit items)
      exp_cap_total,
      exp_cap_construction,
      exp_cap_land,
      exp_cap_equip_instr,
      exp_cap_equip_other,
      exp_cap_equip_nonspec,
      exp_debt_interest,
      debt_lt_begin,
      debt_lt_issued,
      debt_lt_retired,
      debt_lt_end,
      debt_st_begin,
      debt_st_end,
      fund_bal_debt_svc,
      fund_bal_bond,
      fund_bal_other

    ) |>
    # address -1 and -2 codes in expenditure data
    mutate(
      across(c11:fund_bal_other, ~clean_na(.x))
    ) |> 
    # clean up district name formatting
    mutate(
      dist_name = str_to_title(dist_name),
      # convert year to 4 digit
      year = paste0("20", year),
      # make sure enrollment is a numeric variable
      enroll = as.numeric(enroll)
    )
}

# clean raw f33 data
f33_sy12 <- clean_f33_pre_essa(f33_sy12_raw)
f33_sy13 <- clean_f33_pre_essa(f33_sy13_raw)
f33_sy14 <- clean_f33_pre_essa(f33_sy14_raw)
f33_sy15 <- clean_f33_pre_essa2(f33_sy15_raw)
f33_sy16 <- clean_f33_essa(f33_sy16_raw)
f33_sy17 <- clean_f33_essa(f33_sy17_raw)
f33_sy18 <- clean_f33_essa2(f33_sy18_raw)
f33_sy19 <- clean_f33_essa2(f33_sy19_raw)
f33_sy20 <- clean_f33_covid(f33_sy20_raw)
f33_sy21 <- clean_f33_covid2(f33_sy21_raw)
f33_sy22 <- clean_f33_covid2(f33_sy22_raw)
f33_sy23 <- clean_f33_covid2(f33_sy23_raw)

# join -------
f33_sy12_sy23 <- bind_rows(
  f33_sy12, f33_sy13, f33_sy14, f33_sy15,
  f33_sy16, f33_sy17, f33_sy18, f33_sy19,
  f33_sy20, f33_sy21, f33_sy22, f33_sy23
)

# write -----
write_rds(f33_sy12_sy23, "data/processed/f33_sy12_sy23.rds")
