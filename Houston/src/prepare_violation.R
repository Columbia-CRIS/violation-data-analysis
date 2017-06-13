# rm(list=ls())
# 
# require(dplyr)
# # setwd("C:/Users/CATHY/OneDrive/Documents/2016-2017 Junior/15 Mines Research/violation-data-analysis")
# setwd("~/Git/violation-data-analysis") # !!CHANGE WORKING DIR TO MATCH YOUR CASE!!
# 
prepare_violation <- function(data){
  data <- data %>% mutate(CAL_YR = as.numeric(format(as.Date(OCCURRENCE_DT, "%m/%d/%Y"), "%Y")),
                          CAL_M = as.numeric(format(as.Date(OCCURRENCE_DT, "%m/%d/%Y"), "%m")),
                          CAL_QTR = ifelse(
                            CAL_M >9, 4, ifelse(
                              CAL_M > 6, 3, ifelse(
                                CAL_M > 3, 2, 1
                              )
                            )
                          )
                          )
  data$VIOLATION <- 1
  AssessedViolations_altered <- data %>% select(MINE_ID, CAL_QTR,CAL_YR,VIOLATION,PROPOSED_PENALTY_AMT)
  return(AssessedViolations_altered)
}
# 
# save(prepare_violation,file="./Houston/src/prepare_violation.R")
