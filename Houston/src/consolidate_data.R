rm(list=ls())
# Upper Big Branch: 4608436
# Inputs: raw accidents data and final data with only active mine-quarters
# Output: days lost, days restrict, deaths, and violations with only active mine-quarters

# setup
require(dplyr)
library(RcppRoll)
setwd("C:/Users/CATHY/OneDrive/Documents/2016-2017 Junior/15 Mines Research/violation-data-analysis")
#setwd("~/Git/violation-data-analysis")

# load Accidents, Accidents.definition, AssessedViolation, AssedViolation.definition, Mines, Mines.definition, roll_over
if(!exists("Accidents") | 
   !exists("AssessedViolations") | 
   !exists("Mines")|
   !exists("roll_over")) {
  load("./Houston/data/Accidents.RData")
  load("./Houston/data/AssessedViolations.RData")
  load("./Houston/data/Mines.RData")
  load("./Houston/data/roll_over.RData")
  load("./Houston/data/prepare_violation.RData")
  print("raw RData loaded")
}

# constant parameters
longest_period <- 3
actual_start_year <- 2003
end_year <- 2015

# generate accident_roll_over and death_roll_over
actual_accidents <- Accidents %>% filter(is.element(DEGREE_INJURY, c("DAYS AWAY FROM WORK ONLY", 
                                                                     "DYS AWY FRM WRK & RESTRCTD ACT", 
                                                                     "DAYS RESTRICTED ACTIVITY ONLY", 
                                                                     "FATALITY", 
                                                                     "PERM TOT OR PERM PRTL DISABLTY", 
                                                                     "NO VALUE FOUND")))

# creates 2 new columns for death and perm disability. All NA in days lost and days restrict is changed to 0
actual_accidents["DEATH"] <- 0
actual_accidents["PERM_DIS"] <- 0
actual_accidents[is.na(actual_accidents$DAYS_LOST), "DAYS_LOST"] <- 0
actual_accidents[is.na(actual_accidents$DAYS_RESTRICT), "DAYS_RESTRICT)"] <- 0
actual_accidents[which(actual_accidents$DEGREE_INJURY == "FATALITY"), "DEATH"] <- 1
actual_accidents[which(actual_accidents$DEGREE_INJURY == "PERM TOT OR PERM PRTL DISABLTY"), "PERM_DIS"] <- 1
#edited to use date
actual_accidents$ai_dt_actual_date <- as.Date(actual_accidents$ACCIDENT_DT, format = "%m/%d/%Y")
###############################DAYS_LOST##################################################

quarter_level_num_days_lost <- actual_accidents %>% group_by(MINE_ID, CAL_QTR, CAL_YR) %>%
                                                    summarize(base = sum(DAYS_LOST, na.rm = T))

days_lost_rollover <- roll_over(actual_accidents,
                                quarter_level_num_days_lost,
                                longest_period,
                                actual_start_year,
                                end_year)

colnames(days_lost_rollover) <- c(
  "MINE_ID", "QUARTER", "YEAR",
  "NUM_DAYS_LOST", "LAST_QUARTER_DAYS_LOST", "LAST_YEAR_DAYS_LOST", "LAST_THREE_YEARS_DAYS_LOST"
)
rm(quarter_level_num_days_lost)


###########################DAYS_RESTRICT####################################################
quarter_level_num_days_restrict <- actual_accidents %>% group_by(MINE_ID, CAL_QTR, CAL_YR) %>%
                                                        summarize(base = sum(DAYS_RESTRICT, na.rm = T))
days_restrict_rollover <- roll_over(actual_accidents,
                                    quarter_level_num_days_restrict,
                                    longest_period,
                                    actual_start_year,
                                    end_year)
colnames(days_restrict_rollover) <- c(
  "MINE_ID", "QUARTER", "YEAR",
  "NUM_DAYS_RESTRICT", "LAST_QUARTER_DAYS_RESTRICT", "LAST_YEAR_DAYS_RESTRICT", "LAST_THREE_YEARS_DAYS_RESTRICT"
)
rm(quarter_level_num_days_restrict)

###########################DEATH##########################################################
quarter_level_num_deaths <- actual_accidents %>% group_by(MINE_ID, CAL_QTR, CAL_YR) %>%
                                                 summarize(base = sum(DEATH, na.rm = T))
death_rollover <- roll_over(actual_accidents,
                            quarter_level_num_deaths,
                            longest_period,
                            actual_start_year,
                            end_year)
colnames(death_rollover) <- c(
  "MINE_ID", "QUARTER", "YEAR",
  "NUM_DEATH", "LAST_QUARTER_DEATH", "LAST_YEAR_DEATH", "LAST_THREE_YEARS_DEATH"
)
rm(quarter_level_num_deaths)

################################PERM_DIS###################################################
quarter_level_num_perm_dis <- actual_accidents %>% group_by(MINE_ID, CAL_QTR, CAL_YR) %>%
                                                   summarize(base = sum(PERM_DIS, na.rm = T))
dis_rollover <- roll_over(actual_accidents,
                          quarter_level_num_perm_dis,
                          longest_period,
                          actual_start_year,
                          end_year)
colnames(dis_rollover) <- c(
  "MINE_ID", "QUARTER", "YEAR",
  "NUM_DIS", "LAST_QUARTER_DIS", "LAST_YEAR_DIS", "LAST_THREE_YEARS_DIS"
)
rm(quarter_level_num_perm_dis)

######################################VIOLATION###########################################
violation_altered <- prepare_violation(AssessedViolations)

quarter_level_viol_quantity <- violation_altered %>% group_by(MINE_ID, CAL_QTR, CAL_YR) %>%
                                                     summarize(base = sum(VIOLATION, na.rm = T))
violation_rollover <- roll_over(violation_altered,
                                quarter_level_viol_quantity,
                                longest_period,
                                actual_start_year,
                                end_year)
colnames(violation_rollover) <- c(
  "MINE_ID", "QUARTER", "YEAR",
  "VIOLATION_QUANTITY", "LAST_QUARTER_VIOLATION", "LAST_YEAR_VIOLATION", "LAST_THREE_YEARS_VIOLATION"
)
rm(quarter_level_viol_quantity )

################################PENALTY####################################################
quarter_level_viol_amount <- violation_altered %>% group_by(MINE_ID, CAL_QTR, CAL_YR) %>%
                                                   summarize(base = sum(PROPOSED_PENALTY_AMT, na.rm = T))
violation_penalty_rollover <- roll_over(violation_altered,
                                quarter_level_viol_amount,
                                longest_period,
                                actual_start_year,
                                end_year)
colnames(violation_penalty_rollover) <- c(
  "MINE_ID", "QUARTER","YEAR",
  "PROPOSED_PENALTY", "LAST_QUARTER_PENALTY", "LAST_YEAR_PENALTY", "LAST_THREE_YEARS_PENALTY"
)
rm(quarter_level_viol_amount)



# join accidents and violation
temp <- merge(days_lost_rollover, days_restrict_rollover, by = c("MINE_ID", "QUARTER","YEAR"),all=TRUE)
temp <- merge(temp, death_rollover, by = c("MINE_ID", "QUARTER","YEAR"),all=TRUE)
temp <- merge(temp, dis_rollover, by = c("MINE_ID", "QUARTER","YEAR"),all=TRUE)
temp <- merge(temp, violation_rollover, by = c("MINE_ID", "QUARTER","YEAR"),all.x=TRUE)
temp <- merge(temp, violation_penalty_rollover, by = c("MINE_ID", "QUARTER","YEAR"),all.x=TRUE)
temp[is.na(temp)] <- 0

# assign TRUE to active as long as there are some values
temp <- temp %>% mutate(ACTIVE= ifelse(rowSums(temp[,4:ncol(temp)]) > 0, TRUE,FALSE))

#adding attributes of mine
mines <- Mines %>% select(MINE_ID, CURRENT_MINE_NAME, COAL_METAL_IND, CURRENT_MINE_TYPE, NO_EMPLOYEES,CURRENT_STATUS_DT)
temp <- merge(temp, mines, by = "MINE_ID", all.x=TRUE)

#rearranging columns
temp <- temp[, c(1, 29:ncol(temp), 2:3, 28, 4:27)]

# result
complete_active_quarters <- temp
save(complete_active_quarters, file="./Houston/output/Consolidated.RData")

# see simple_lm.R for simple lm