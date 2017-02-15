setwd("~/jy/Regulatory Analysis Research - Prof. Venkat Venkatasubramanian/retooling/")

library(dplyr)
library(RcppRoll)

## Total script run time (if no data exists): ~10 minutes (Ashu's guesstimate)
## Total script run time (if all data exists): 20-25 seconds

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


longest.period <- 3
actual.start.year <- 2000
start.year <- 2000 - longest.period
mines.with.accidents.post.start.year <- (actual.accidents %>% filter(cal_yr >= actual.start.year))$mine_id %>% unique()
end.year <- 2015
number.years <- end.year - start.year + 1


## Challenge: fill in nonpresent values for mines with 0 days lost
## For example, mine could have just not had a day lost, but that won't show up in `quarter.level.accidents`
## 1. First, initialize all blank data frame by figuring out final structure (we know exactly what pattern mine_id, quarter, and year should follow
##    a particular set of repetitions)
## 2. Anti-join will only keep data from the set of keys not found in the actual data
## 3. Then we can just join the two sets of rows!
blank.full.quarter.level.days_lost <- data.frame(mine_id = rep(mines.with.accidents.post.2k, each = 4 * number.years),
                                                 quarter = rep(1:4, times = length(mines.with.accidents.post.start.year) * number.years),
                                                 year = rep(rep(start.year:end.year, times = rep(4, number.years)),
                                                            times = length(mines.with.accidents.post.start.year)),
                                                 num.days.lost = 0)
full.quarter.level.days_lost <- anti_join(blank.full.quarter.level.days_lost, quarter.level.accidents,
                                          by = c("mine_id" = "mine_id", "quarter" = "cal_qtr", "year" = "cal_yr"))
full.quarter.level.days_lost <- rbind(full.quarter.level.days_lost,
                                      quarter.level.accidents %>% 
                                        select(mine_id, quarter = cal_qtr,
                                               year = cal_yr, num.days.lost = quarter_level_days_lost) %>% 
                                        data.frame() %>% filter(year >= start.year) %>% 
                                        filter(year <= end.year)) %>% arrange(mine_id, year, quarter)


## Challenge: Calculating past period statistics
## lag will put value of index n - 1 at index n
## roll_sum will do a sum from the specified number of previous rows and put NA's at the beginning
## We filter with actual.start.year so there are no NA's. 
##   (The year that data is ready and the year that data needs to start being used are different.)
full.quarter.level.days_lost <- full.quarter.level.days_lost %>% 
                                group_by(mine_id) %>%
                                mutate(last.quarter = lag(num.days.lost),
                                       last.year = roll_sum(lag(num.days.lost), 4, align = "right", fill = NA),
                                       last.three.years = roll_sum(lag(num.days.lost), 12, align = "right", fill = NA)) %>%
                                filter(year >= actual.start.year)

write.csv(full.quarter.level.days_lost, "quarter_level_days_lost.csv")