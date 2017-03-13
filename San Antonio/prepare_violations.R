rm(list=ls())
require(dplyr)
setwd("~/Git/violation-data-analysis")
violations <- read.csv("./San Antonio/data/AssessedViolations.csv", stringsAsFactors = FALSE)
colnames(violations)[1] <- "mine_id"

violations <- violations %>% mutate(
  cal_yr = as.numeric(format(as.Date(OCCURRENCE_DT, "%m/%d/%Y"), "%Y")),
  cal_mm = as.numeric(format(as.Date(OCCURRENCE_DT, "%m/%d/%Y"), "%m")),
  cal_qtr = ifelse(
    cal_mm >9, 4, ifelse(
      cal_mm > 6, 3, ifelse(
        cal_mm > 3, 2, 1
      )
    )
  )
)

violations$violation <- 1
violations.lite <- violations %>% select(mine_id, cal_qtr, cal_yr, violation)
save(violations.lite, file="./San Antonio/data/albert_violation.RData")
