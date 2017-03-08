rm(list=ls())
# Upper Big Branch: 4608436

# setup
require(dplyr)
library(RcppRoll)
setwd("~/Git/violation-data-analysis")

# load accidents, violations, and function roll_over
if(!exists("accidents") | !exists("violations") | !exists("roll_over")) {
  load("./Analysis/data/msha_accidents_violations.RData")
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
rm(quarter.level.num.days.restrict)

quarter.level.num.deaths <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(deaths, na.rm = T))
death_rollover <- roll_over(actual.accidents,
                              quarter.level.num.deaths,
                               longest.period,
                               actual.start.year,
                               end.year)
rm(quarter.level.num.deaths)

# cleanup violations
quarter.level.violations <- violations %>% group_by(mine_id, cal_qtr, cal_yr) %>% 
  summarize(base = n())
violation_rollover <- roll_over(violations,
                                quarter.level.violations,
                                longest.period,
                                actual.start.year,
                                end.year)




day.level.accidents <- actual.accidents %>% group_by(mine_id, ai_dt) %>% summarize(day_level_days_lost = sum(days_lost, na.rm = T))
quarter.level.accidents <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr) %>% summarize(quarter_level_days_lost = sum(days_lost, na.rm = T))

quarter.level.accidents <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(days_lost, na.rm = T))
accident_rollover <- roll_over(actual.accidents,
                               quarter.level.accidents,
                               longest.period,
                               actual.start.year,
                               end.year)


