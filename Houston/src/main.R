# Setup ----
rm(list=ls())
setwd("~/Git/violation-data-analysis") # !!CHANGE WORKING DIR TO MATCH YOUR CASE!!
is_run_parent = TRUE # let child scripts know, do not repeat rm and setwd

# Download, import, and clean-up latest data from MSHA ----
# Input: None
# Output: AssessedViolations.RData, Accidents.RData, Mines.RData
source("./Houston/src/import_msha_txt.R")

# Consolidate data ----
# Input: AssessedViolations.RData, Accidents.RData, Mines.RData
# Output: Consolidated.RData
source("./Houston/src/consolidate_data.R")

# Perform conditional logistic regression ----
# Input: Consolidated.RData
# Output: Result_clogit.RData
source("./Houston/src/conditional_logistic.R")
