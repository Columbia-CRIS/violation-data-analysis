# some resources:
# http://blog.minitab.com/blog/adventures-in-statistics-2/how-to-interpret-regression-analysis-results-p-values-and-coefficients
# http://stats.stackexchange.com/questions/59250/how-to-interpret-the-output-of-the-summary-method-for-an-lm-object-in-r

# setup
require(dplyr)
require(survival)
require(ggplot2)
setwd("~/Git/violation-data-analysis")
load("./San Antonio/output/result.RData")

train <- complete.active.quarters
# train <- train %>% rowwise() %>% mutate(high_severity = num.death > 0 | num.days.lost > 100)
# train <- train[, c(1:5, 22, 6:21)]
# train %>% count(high_severity)

View(train %>% filter(mine_id == 1102752))
new_era <- accidents %>% filter(mine_id == 1102752 & cal_qtr == 2 & cal_yr == 2005) %>% arrange(
  desc(days_lost)
)
View(new_era)

summary(lm(num.days.lost + num.days.restrict ~ last.quarter.viol+last.year.viol+last.three.years.viol, data=train %>% filter(active)))

bad <- train %>% filter(active & num.days.restrict >= 30 & last.quarter.lost > 0)
bad$mark <- 'bad'
good <- train %>% filter(active & num.days.restrict < 30 & last.quarter.lost > 0)
good$mark <- 'good'
goodbad <- rbind(good, bad)
goodbad <- goodbad %>% rowwise() %>% mutate(ratio = last.quarter.lost / (last.year.lost / 4))
ggplot(goodbad, aes(num.days.lost)) + geom_density(alpha = 0.2)
plot(ecdf(x = train$num.days.lost))

# msha_glm <- clogit(high_severity ~ num.days.lost + viol.quantity + strata(mine_id),
#                    data = train%>% top_n(100) %>% filter(active) %>% select(mine_id, num.days.lost, high_severity, viol.quantity))
# 
# print(msha_glm)

sapply(train, function(x) sum(is.na(x)))

# lm on composite num.days.lost
summary(lm(30*num.death+1*num.days.lost+1*num.days.restrict~last.quarter.lost+last.year.lost+last.three.years.lost
           +last.quarter.restrict+last.year.restrict+last.three.years.restrict
           +last.quarter.viol+last.year.viol+last.three.years.viol
           +last.quarter.death+last.year.death+last.three.years.death, 
           data=complete.active.quarters %>% filter(active)))
