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
if(!exists("accidents") | 
   !exists("violations.lite") | 
   !exists("roll_over") | 
   !exists("mines")) {
  load("./San Antonio/data/secret_ingredients.RData")
  load("./San Antonio/data/albert_violation.RData")
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
actual.accidents["perm_dis"] <- 0
actual.accidents[is.na(actual.accidents$days_lost), "days_lost"] <- 0
actual.accidents[is.na(actual.accidents$days_restrict), "days_restrict"] <- 0
actual.accidents[which(actual.accidents$inj_degr_desc == "FATALITY"), "deaths"] <- 1
actual.accidents[which(actual.accidents$inj_degr_desc == "PERM TOT OR PERM PRTL DISABLTY"), "perm_dis"] <- 1
actual.accidents$ai_dt_actual_date <- strftime(actual.accidents$ai_dt, "%F")

quarter.level.num.days.lost <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(days_lost, na.rm = T))
days_lost_rollover <- roll_over(actual.accidents,
                                quarter.level.num.days.lost,
                                longest.period,
                                actual.start.year,
                                end.year)
colnames(days_lost_rollover) <- c(
  "mine_id", "quarter", "year",
  "num.days.lost", "last.quarter.lost", "last.year.lost", "last.three.years.lost"
  )
rm(quarter.level.num.days.lost)

quarter.level.num.days.restrict <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(days_restrict, na.rm = T))
days_restrict_rollover <- roll_over(actual.accidents,
                                quarter.level.num.days.restrict,
                                longest.period,
                                actual.start.year,
                                end.year)
colnames(days_restrict_rollover) <- c(
  "mine_id", "quarter", "year",
  "num.days.restrict", "last.quarter.restrict", "last.year.restrict", "last.three.years.restrict"
)
rm(quarter.level.num.days.restrict)

quarter.level.num.deaths <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(deaths, na.rm = T))
death_rollover <- roll_over(actual.accidents,
                              quarter.level.num.deaths,
                               longest.period,
                               actual.start.year,
                               end.year)
colnames(death_rollover) <- c(
  "mine_id", "quarter", "year",
  "num.death", "last.quarter.death", "last.year.death", "last.three.years.death"
)
rm(quarter.level.num.deaths)

quarter.level.num.perm_dis <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(perm_dis, na.rm = T))
dis_rollover <- roll_over(actual.accidents,
                            quarter.level.num.perm_dis,
                            longest.period,
                            actual.start.year,
                            end.year)
colnames(dis_rollover) <- c(
  "mine_id", "quarter", "year", 
  "num.dis", "last.quarter.dis", "last.year.dis", "last.three.years.dis"
)
rm(quarter.level.num.perm_dis)

quarter.level.viol.quantity <- violations.lite %>% group_by(mine_id, cal_qtr, cal_yr)%>% 
  summarize(base = sum(violation, na.rm = T))
violation_rollover <- roll_over(violations.lite,
                          quarter.level.viol.quantity,
                          longest.period,
                          actual.start.year,
                          end.year)
colnames(violation_rollover) <- c(
  "mine_id", "quarter", "year", 
  "viol.quantity", "last.quarter.viol", "last.year.viol", "last.three.years.viol"
)
rm(quarter.level.viol.quantity)

# # cleanup violations
# active_violation_rollover = full.days_lost.accidents.date %>%
#   select(mine_id, year, quarter, viol.quantity, last.quarter.y, last.year.y, last.three.years.y)
# active_violation_rollover$active <- TRUE
# colnames(active_violation_rollover) <- c(
#   "mine_id", "year", "quarter", 
#   "viol.quantity", "last.quarter.viol", "last.year.viol", "last.three.years.viol",
#   "active"
# )


# join accidents and violation
temp <- merge(days_lost_rollover, days_restrict_rollover, by = c("mine_id","year","quarter"),all=TRUE)
temp[is.na(temp)] <- 0
temp <- merge(temp, death_rollover, by = c("mine_id","year","quarter"),all=TRUE)
temp[is.na(temp)] <- 0
temp <- merge(temp, dis_rollover, by = c("mine_id","year","quarter"),all=TRUE)
temp[is.na(temp)] <- 0
temp <- merge(temp, violation_rollover, by = c("mine_id","year","quarter"),all.x=TRUE)
temp[is.na(temp)] <- 0

# assign TRUE to active as long as there are some values
temp <- temp %>% mutate(
  active = ifelse(
    num.days.lost + last.quarter.lost + last.year.lost + last.three.years.lost +
    num.days.restrict + last.quarter.restrict + last.year.restrict + last.three.years.restrict +
    num.death + last.quarter.death + last.year.death + last.three.years.death +
    num.dis + last.quarter.dis + last.year.dis + last.three.years.dis + 
    viol.quantity + last.quarter.viol + last.year.viol + last.three.years.viol
                  > 0, TRUE, FALSE
                  )
  )

# temp <- merge(temp, active_violation_rollover, by = c("mine_id","year","quarter"),all.x=TRUE)
# the code below is to make sure that whenever there is something for a row, it is active
# temp <- temp %>% mutate(
#   active = ifelse(is.na(active) &
#                     num.days.lost + num.days.restrict + num.death + num.dis +
#                     last.quarter.lost + last.quarter.restrict + last.quarter.death + last.quarter.dis +
#                     last.year.lost + last.year.restrict + last.quarter.death + last.quarter.dis +
#                     last.three.years.lost + last.three.years.restrict + last.three.years.death + last.three.years.dis
#                   > 0, TRUE,
#                   ifelse(is.na(active),
#                          FALSE, 
#                          ifelse(active, TRUE, FALSE))
#   )
#     )
# temp[is.na(temp)] <- 0

colnames(mines) <- c("mine_id", "mine.name")
temp <- merge(temp, mines, by = "mine_id", all.x=TRUE)

temp <- temp[, c(1, 25, 2:3, 24, 4:23)]

# result
complete.active.quarters <- temp
# colnames(complete.active.quarters) <- 
#   c("mine_id", "year", "quarter", 
#     "num.days.lost", "last.quarter.lost", "last.year.lost", "last.three.years.lost",
#     "num.days.restrict", "last.quarter.restrict", "last.year.restrict", "last.three.years.restrict",
#     "num.death", "last.quarter.death", "last.year.death", "last.three.years.death",
#     "viol.quantity", "last.quarter.viol", "last.year.viol", "last.three.years.viol",
#     "active", "mine.name")
# complete.active.quarters <- complete.active.quarters[, c(1, 21, 2:3, 20, 4:19)]

save(complete.active.quarters, file="./San Antonio/output/result.RData")

# see simple_lm.R for simple lm