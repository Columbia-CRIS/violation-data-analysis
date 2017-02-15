setwd("~/jy/Regulatory Analysis Research - Prof. Venkat Venkatasubramanian/retooling/")

library(dplyr)
library(RcppRoll)

if(!exists("accidents")) {
  accidents <- read.csv("msha_accident.csv", stringsAsFactors = F)
}
if(!exists("violations")) {
  violations <- read.csv("msha_violation.csv", stringsAsFactors = F)
}
if(!exists("assessed_violations")) {
  assessed_violations <- read.csv("msha_assssd_violation.csv", stringsAsFactors = F)
}

actual.accidents <- accidents %>% filter(is.element(inj_degr_desc, c("DAYS AWAY FROM WORK ONLY", 
                                                                     "DYS AWY FRM WRK & RESTRCTD ACT", 
                                                                     "DAYS RESTRICTED ACTIVITY ONLY", 
                                                                     "FATALITY", 
                                                                     "PERM TOT OR PERM PRTL DISABLTY", 
                                                                     "NO VALUE FOUND")))
na.and.no.value.index <- is.element(actual.accidents$inj_degr_desc, "NO VALUE FOUND") & is.na(actual.accidents$days_lost)
actual.accidents[na.and.no.value.index, "days_restrict"] <- 0
actual.accidents[na.and.no.value.index, "days_lost"] <- 0
actual.accidents[which(actual.accidents$inj_degr_desc == "FATALITY"), "days_lost"] <- 300
actual.accidents$ai_dt_actual_date <- strftime(actual.accidents$ai_dt, "%F")

day.level.accidents <- actual.accidents %>% group_by(mine_id, ai_dt) %>% summarize(day_level_days_lost = sum(days_lost, na.rm = T))
quarter.level.accidents <- actual.accidents %>% group_by(mine_id, cal_qtr, cal_yr) %>% summarize(quarter_level_days_lost = sum(days_lost, na.rm = T))

start.year <- 2000
mines.with.accidents.post.2k <- (actual.accidents %>% filter(cal_yr >= 2000))$mine_id %>% unique()
end.year <- 2015
number.years <- end.year - start.year + 1

blank.full.quarter.level.days_lost <- data.frame(mine_id = rep(mines.with.accidents.post.2k, each = 4 * number.years),
                                                 quarter = rep(1:4, times = length(mines.with.accidents.post.2k) * number.years),
                                                 year = rep(rep(start.year:end.year, times = rep(4, number.years)),
                                                            times = length(mines.with.accidents.post.2k)),
                                                 num_days_lost = 0)
full.quarter.level.days_lost <- anti_join(blank.full.quarter.level.days_lost, quarter.level.accidents,
                                          by = c("mine_id" = "mine_id", "quarter" = "cal_qtr", "year" = "cal_yr"))
full.quarter.level.days_lost <- rbind(full.quarter.level.days_lost,
                                      quarter.level.accidents %>% 
                                        select(mine_id, quarter = cal_qtr,
                                               year = cal_yr, num_days_lost = quarter_level_days_lost) %>% 
                                        data.frame() %>% filter(year >= start.year) %>% 
                                        filter(year <= end.year)) %>% arrange(mine_id, year, quarter)

full.quarter.level.days_lost <- full.quarter.level.days_lost %>% 
                                group_by(mine_id) %>%
                                mutate(last.quarter = lag(num_days_lost),
                                       last.year = roll_sum(lag(num_days_lost), 4, align = "right", fill = NA)) %>%
                                filter(year > start.year)

write.csv(full.quarter.level.days_lost, "quarter_level_days_lost.csv")