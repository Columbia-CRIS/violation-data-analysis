# Setup ----
# All data are after 2000
if(!exists("is_run_parent")){
  rm(list=ls())
  setwd("~/Git/violation-data-analysis") # !!CHANGE WORKING DIR TO MATCH YOUR CASE!!
}
require(dplyr)
dest.dir <- "./Houston/data"
dir.create(file.path(dest.dir))

# Import violation ----
# Date retried: 4/8/2017
# download and import violation table
temp <- tempfile()
download.file(url = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/AssessedViolations.zip",
              destfile = temp)
assessedviolations.txt <- unzip(zipfile = temp, files = "AssessedViolations.txt")
AssessedViolations <- read.table(file = assessedviolations.txt, 
                                 sep = "|", stringsAsFactors = FALSE, fill = TRUE, header = TRUE)
unlink(temp)
unlink(assessedviolations.txt)
sapply(AssessedViolations, class)

# download and import violation definition
temp <- tempfile()
download.file(url = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Assessed_Violations_Definition_File.txt",
              destfile = temp)
AssessedViolations.definition <- read.table(file = temp,
                                            sep = "|", stringsAsFactors = FALSE, fill = TRUE, header = TRUE,
                                            quote = NULL)
unlink(temp)
save(AssessedViolations, AssessedViolations.definition, file = file.path(dest.dir, "AssessedViolations.RData"))

# Import accidents ----
# Date retried: 4/8/2017
# accident table
temp <- tempfile()
download.file(url = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Accidents.zip",
              destfile = temp)
accidents.txt <- unzip(zipfile = temp, files = "Accidents.txt")
Accidents <- read.table(file = accidents.txt, 
                        sep = "|", stringsAsFactors = FALSE, fill = TRUE, header = TRUE)
unlink(temp)
unlink(accidents.txt)
sapply(Accidents, class)

# accident definition
temp <- tempfile()
download.file(url = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Accidents_Definition_File.txt",
              destfile = temp)
Accidents.definition <- read.table(file = temp,
                                   sep = "|", stringsAsFactors = FALSE, fill = TRUE, header = TRUE,
                                   quote = NULL)
unlink(temp)
save(Accidents, Accidents.definition, file = file.path(dest.dir, "Accidents.RData"))

# Import mines ----
# Date retried: 4/8/2017
# mine table
temp <- tempfile()
download.file(url = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Mines.zip",
              destfile = temp)
mines.txt <- unzip(zipfile = temp, files = "Mines.txt")
Mines <- read.table(file = mines.txt, 
                    sep = "|", stringsAsFactors = FALSE, fill = TRUE, header = TRUE)
unlink(temp)
unlink(mines.txt)
sapply(Mines, class)

# mine definition
temp <- tempfile()
download.file(url = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Mines_Definition_File.txt",
              destfile = temp)
Mines.definition <- read.table(file = temp,
                               sep = "|", stringsAsFactors = FALSE, fill = TRUE, header = TRUE,
                               quote = NULL)
unlink(temp)
save(Mines, Mines.definition, file = file.path(dest.dir, "Mines.RData"))