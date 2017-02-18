quarter.level.violations <- violations %>% group_by(mine_id, cal_qtr, cal_yr) %>% 
                                            summarize(quarter_level_violation = n())
#check is accident is a subset of violations
is.subset(unique(blank.full.quarter.level.days_lost$mine_id),unique(quarter.level.accidents$mine_id))


longest.period <- 3
actual.start.year <- 2000
start.year <- 2000 - longest.period
mines.with.violation.post.start.year <- (violations %>% filter(cal_yr >= actual.start.year))$mine_id %>% unique()
end.year <- 2015
number.years <- end.year - start.year + 1


## Challenge: fill in nonpresent values for mines with 0 days lost
## For example, mine could have just not had a day lost, but that won't show up in `quarter.level.accidents`
## 1. First, initialize all blank data frame by figuring out final structure (we know exactly what pattern mine_id, quarter, and year should follow
##    a particular set of repetitions)
## 2. Anti-join will only keep data from the set of keys not found in the actual data
## 3. Then we can just join the two sets of rows!
blank.full.quarter.level.violations <- data.frame(mine_id = rep(mines.with.violation.post.start.year, each = 4 * number.years),
                                                 quarter = rep(1:4, times = length(mines.with.violation.post.start.year) * number.years),
                                                 year = rep(rep(start.year:end.year, times = rep(4, number.years)),
                                                            times = length(mines.with.violation.post.start.year)),
                                                 viol.quantity = 0)
full.quarter.level.violations <- anti_join(blank.full.quarter.level.violations, quarter.level.violations,
                                          by = c("mine_id" = "mine_id", "quarter" = "cal_qtr", "year" = "cal_yr"))
full.quarter.level.violations <- rbind(full.quarter.level.violations,
                                       quarter.level.violations %>% 
                                        select(mine_id, quarter = cal_qtr,
                                               year = cal_yr, viol.quantity = quarter_level_violation) %>% 
                                        data.frame() %>% filter(year >= start.year) %>% 
                                        filter(year <= end.year)) %>% arrange(mine_id, year, quarter)


## Challenge: Calculating past period statistics
## lag will put value of index n - 1 at index n
## roll_sum will do a sum from the specified number of previous rows and put NA's at the beginning
## We filter with actual.start.year so there are no NA's. 
##   (The year that data is ready and the year that data needs to start being used are different.)
full.quarter.level.violations <- full.quarter.level.violations %>% 
  group_by(mine_id) %>%
  mutate(last.quarter = lag(viol.quantity),
         last.year = roll_sum(lag(viol.quantity), 4, align = "right", fill = NA),
         last.three.years = roll_sum(lag(viol.quantity), 12, align = "right", fill = NA)) %>%
  filter(year >= actual.start.year)

test <- merge(full.quarter.level.days_lost, full.quarter.level.violations , by = c("mine_id","year","quarter"),all=TRUE)
test[is.na(test)] <- 0
