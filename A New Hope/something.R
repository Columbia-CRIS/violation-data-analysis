setwd("~/jy/Regulatory Analysis Research - Prof. Venkat Venkatasubramanian/retooling/")

library(dplyr)

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

day.level.accidents <- actual.accidents %>% group_by(mine_id, ai_dt)