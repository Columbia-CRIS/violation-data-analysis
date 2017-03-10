# some resources:
# http://blog.minitab.com/blog/adventures-in-statistics-2/how-to-interpret-regression-analysis-results-p-values-and-coefficients
# http://stats.stackexchange.com/questions/59250/how-to-interpret-the-output-of-the-summary-method-for-an-lm-object-in-r

# setup
require(dplyr)
setwd("~/Git/violation-data-analysis")
load("./San Antonio/output/result.RData")

# lm on composite num.days.lost
summary(lm(30*num.death+1*num.days.lost+1*num.days.restrict~last.quarter.lost+last.year.lost+last.three.years.lost
           +last.quarter.restrict+last.year.restrict+last.three.years.restrict
           +last.quarter.viol+last.year.viol+last.three.years.viol
           +last.quarter.death+last.year.death+last.three.years.death, 
           data=complete.active.quarters %>% filter(active)))
