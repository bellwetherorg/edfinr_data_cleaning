# verify_exp_cur_fix.R
#
# Post-rebuild verification for the exp_cur_total redefinition
# (CE1 + CE2 + CE3 -> TCURELSC). Run from the project root AFTER
# scripts/run_all.R has regenerated data/processed/.
#
# Compares the rebuilt files against the previously published (pre-fix)
# parquet files, which are downloaded from the hosted bucket to tempdir()
# on first run. Census benchmark workbooks are also downloaded to tempdir().
#
# Output goes to the console and to
# data/processed/verification_exp_cur_fix.txt

library(tidyverse)
library(arrow)
library(readxl)

options(scipen = 999)

new_full <- read_parquet("data/processed/edfinr_data_fy12_fy23_full.parquet")
new_skinny <- read_parquet("data/processed/edfinr_data_fy12_fy23_skinny.parquet")

base_url <- "https://edfinr-tidy-data.s3.us-east-2.amazonaws.com/"
fetch_prev <- function(type) {
  fname <- paste0("edfinr_data_fy12_fy23_", type, ".parquet")
  dest <- file.path(tempdir(), paste0("prev_", fname))
  if (!file.exists(dest)) download.file(paste0(base_url, fname), dest, quiet = TRUE, mode = "wb")
  read_parquet(dest)
}
prev_full <- fetch_prev("full")
prev_skinny <- fetch_prev("skinny")

sink("data/processed/verification_exp_cur_fix.txt", split = TRUE)
cat("exp_cur_total TCURELSC fix verification --", format(Sys.time()), "\n")

cat("\n== 1. Dimensions unchanged ==\n")
cat(sprintf("full:   new %d x %d | prev %d x %d\n",
            nrow(new_full), ncol(new_full), nrow(prev_full), ncol(prev_full)))
cat(sprintf("skinny: new %d x %d | prev %d x %d\n",
            nrow(new_skinny), ncol(new_skinny), nrow(prev_skinny), ncol(prev_skinny)))
stopifnot(dim(new_full) == dim(prev_full), dim(new_skinny) == dim(prev_skinny))
new_cols_only <- setdiff(names(new_full), names(prev_full))
dropped_cols <- setdiff(names(prev_full), names(new_full))
cat("column set changes (expect none):",
    if (length(new_cols_only) + length(dropped_cols) == 0) "none" else
      paste("ADDED:", toString(new_cols_only), "DROPPED:", toString(dropped_cols)), "\n")

cat("\n== 2. Keys ==\n")
dup_n <- new_full |> count(ncesid, year) |> filter(n > 1) |> nrow()
cat("duplicate (ncesid, year) keys:", dup_n, "\n")
stopifnot(dup_n == 0)

cat("\n== 3. NYC panel (ncesid 3620580) ==\n")
nyc <- new_full |>
  filter(ncesid == "3620580") |>
  arrange(year) |>
  select(year, enroll, exp_cur_total, exp_cur_pp)
print(as.data.frame(nyc))
stopifnot(sum(is.finite(nyc$exp_cur_pp)) == 12)
yoy <- diff(nyc$exp_cur_pp) / head(nyc$exp_cur_pp, -1)
cat("max abs YoY change in NYC exp_cur_pp:", sprintf("%.1f%%", 100 * max(abs(yoy))),
    "(flag if > ~15%)\n")

cat("\n== 4. exp_cur_total NA share by year (new vs prev) ==\n")
na_tbl <- new_full |>
  group_by(year) |>
  summarise(new_na_pct = round(100 * mean(is.na(exp_cur_total)), 1)) |>
  left_join(
    prev_full |>
      group_by(year) |>
      summarise(prev_na_pct = round(100 * mean(is.na(exp_cur_total)), 1)),
    by = "year"
  )
print(as.data.frame(na_tbl))
cat("expect new_na_pct ~1-3% every year (prev: 100% FY12-15, 16-50% after)\n")

cat("\n== 5. Shift audit: districts with a pre-fix CE-based value ==\n")
shift <- prev_full |>
  filter(!is.na(exp_cur_total), exp_cur_total > 0) |>
  select(ncesid, year, prev = exp_cur_total) |>
  inner_join(select(new_full, ncesid, year, new = exp_cur_total),
             by = c("ncesid", "year")) |>
  filter(!is.na(new), new > 0) |>
  mutate(ratio = new / prev)
cat(sprintf("n = %d district-years | ratio median %.4f, p1 %.3f, p99 %.3f\n",
            nrow(shift), median(shift$ratio),
            quantile(shift$ratio, .01), quantile(shift$ratio, .99)))
cat(sprintf("changed by >10%%: %d (%.1f%%)\n",
            sum(abs(shift$ratio - 1) > 0.10),
            100 * mean(abs(shift$ratio - 1) > 0.10)))
cat("expect median ~1.00; tails reflect CE-vs-TCURELSC object exclusions\n")

cat("\n== 6. Census benchmark (current spending, published Table 6) ==\n")
bench_url <- function(yy) paste0(
  "https://www2.census.gov/programs-surveys/school-finances/tables/20", yy,
  "/secondary-education-finance/elsec", yy, "_sumtables.xlsx"
)
read_t6 <- function(yy) {
  dest <- file.path(tempdir(), paste0("elsec", yy, "_sumtables.xlsx"))
  if (!file.exists(dest)) download.file(bench_url(yy), dest, quiet = TRUE, mode = "wb")
  read_excel(dest, sheet = "6", col_names = FALSE) |>
    select(area = 1, total = 3) |>
    mutate(area = str_remove_all(area, "\\.+$") |> str_trim(),
           total = as.numeric(total) * 1000) |>
    filter(!is.na(area), !is.na(total))
}
for (yy in c("22", "23")) {
  yr <- paste0("20", yy)
  bench <- read_t6(yy)
  us_bench <- bench$total[bench$area == "United States"]
  ed_total <- sum(new_full$exp_cur_total[new_full$year == yr], na.rm = TRUE)
  prev_total <- sum(prev_full$exp_cur_total[prev_full$year == yr], na.rm = TRUE)
  cat(sprintf("FY%s: new $%.1fB | prev $%.1fB | Census $%.1fB | new vs Census %+.1f%%\n",
              yr, ed_total / 1e9, prev_total / 1e9, us_bench / 1e9,
              100 * (ed_total - us_bench) / us_bench))
}
cat("expect new within ~1-2% of Census (TCURELSC is the published concept);\n")
cat("note: edfinr excludes some LEA types, so a small shortfall is normal\n")

cat("\n== 7. Spot checks vs raw F-33 TCURELSC ==\n")
spot_raw <- function(path, leaid) {
  hdr <- toupper(names(read_tsv(path, n_max = 0, show_col_types = FALSE)))
  raw <- read_tsv(path, col_types = cols(.default = col_character()))
  names(raw) <- hdr
  raw |> filter(LEAID == leaid) |> pull(TCURELSC) |> as.numeric()
}
spots <- tribble(
  ~ncesid, ~label, ~file, ~yr,
  "3620580", "New York City, NY", "data/raw/ccd/Sdf16_1a.txt", "2016",
  "1709930", "Chicago, IL",       "data/raw/ccd/sdf22_1a.txt", "2022",
  "2721244", "Minneapolis, MN",   "data/raw/ccd/sdf23_1a.txt", "2023"
)
for (i in seq_len(nrow(spots))) {
  s <- spots[i, ]
  raw_val <- spot_raw(s$file, s$ncesid)
  new_val <- new_full |>
    filter(ncesid == s$ncesid, year == s$yr) |>
    pull(exp_cur_total)
  cat(sprintf("%s FY%s: pipeline %s | raw TCURELSC %s | match: %s\n",
              s$label, s$yr, format(new_val, big.mark = ","),
              format(raw_val, big.mark = ","),
              identical(as.numeric(new_val), raw_val)))
}

cat("\n== 8. CE components vs TCURELSC total (documentation stat) ==\n")
comp <- new_full |>
  filter(!is.na(exp_cur_st_loc), !is.na(exp_cur_fed), exp_cur_total > 0) |>
  mutate(ce_sum = exp_cur_st_loc + exp_cur_fed + coalesce(exp_cur_resa, 0),
         ratio = ce_sum / exp_cur_total)
cat(sprintf("district-years with CE reported: %d | ce_sum/total median %.4f, p1 %.3f, p99 %.3f\n",
            nrow(comp), median(comp$ratio),
            quantile(comp$ratio, .01), quantile(comp$ratio, .99)))
cat("components are the ESSA fund-type split and do NOT sum exactly to\n")
cat("exp_cur_total (differing object exclusions) -- documented in README\n")

sink()
cat("\nArtifact written to data/processed/verification_exp_cur_fix.txt\n")
