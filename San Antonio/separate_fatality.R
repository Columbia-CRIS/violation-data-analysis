rm(list=ls())
# Upper Big Branch: 4608436
# This is a temporary fix
# Inputs: raw accidents data and final data with only active mine-quarters
# Output: days lost, days restrict, deaths, and violations with only active mine-quarters

# setup
require(dplyr)
library(RcppRoll)
setwd("~/Git/violation-data-analysis")

# load accidents, violations, and function roll_over
if(!exists("accidents") | !exists("full.days_lost.accidents.date") | !exists("roll_over")) {
  load("./San Antonio/raw_accidents_fine_viol.RData")
  print("raw RData loaded")
}

# constant parameters
longest.period <- 3
actual.start.year <- 2000
end.year <- 2015

# generate accident_roll_over and death_roll_over
actual.accidents <- accidents %>% filter(is.element(inj_degr_desc, c("DAYS AWAY FROM WORK ONLY", 
                                                                     "DYS AWY FRM WRK & RESTRCTD ACT", 
                                                                     "DAYS RESTRICTED ACTIVITY ONLY", 
                                                                     "FATALITY", 
                                                                     "PERM TOT OR PERM PRTL DISABLTY", 
                                                                     "NO VALUE FOUND")))
actual.accidents["deaths"] <- 0
na.and.no.value.index <- is.element(actual.accidents$inj_degr_desc, "NO VALUE FOUND") & is.na(actual.accidents$days_lost)
actual.accidents[na.and.no.value.index, "days_restrict"] <- 0
actual.accidents[na.and.no.value.index, "days_lost"] <- 0
actual.accidents[which(actual.accidents$inj_degr_desc == "FATALITY"), "deaths"] <- 1
actual.accidents$ai_dt_actual_date <- strftime(actual.accidents$ai_dt, "%F")
rm(na.and.no.value.index)

quarter.level.num.days.lost <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(days_lost, na.rm = T))
days_lost_rollover <- roll_over(actual.accidents,
                                quarter.level.num.days.lost,
                                longest.period,
                                actual.start.year,
                                end.year)
rm(quarter.level.num.days.lost)

quarter.level.num.days.restrict <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(days_restrict, na.rm = T))
days_restrict_rollover <- roll_over(actual.accidents,
                                quarter.level.num.days.restrict,
                                longest.period,
                                actual.start.year,
                                end.year)
colnames(days_restrict_rollover)[4] <- "num.days.restrict"
rm(quarter.level.num.days.restrict)

quarter.level.num.deaths <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(deaths, na.rm = T))
death_rollover <- roll_over(actual.accidents,
                              quarter.level.num.deaths,
                               longest.period,
                               actual.start.year,
                               end.year)
colnames(death_rollover)[4] <- "num.deaths"
rm(quarter.level.num.deaths)

# cleanup violations
active_violation_rollover = full.days_lost.accidents.date %>%
  select(mine_id, year, quarter, viol.quantity, last.quarter.y, last.year.y, last.three.years.y)

# join accidents and violation
temp <- merge(days_lost_rollover, days_restrict_rollover, by = c("mine_id","year","quarter"),all=TRUE)
temp[is.na(temp)] <- 0
temp <- merge(temp, death_rollover, by = c("mine_id","year","quarter"),all=TRUE)
temp[is.na(temp)] <- 0
temp <- merge(temp, active_violation_rollover, by = c("mine_id","year","quarter"),all.y=TRUE)
temp[is.na(temp)] <- 0

# result
complete.active.quarters <- temp
save(complete.active.quarters, file="./San Antonio/result.RData")


