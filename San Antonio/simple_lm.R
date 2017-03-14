rm(list=ls())
# some resources:
# http://blog.minitab.com/blog/adventures-in-statistics-2/how-to-interpret-regression-analysis-results-p-values-and-coefficients
# http://stats.stackexchange.com/questions/59250/how-to-interpret-the-output-of-the-summary-method-for-an-lm-object-in-r

# setup
require(dplyr)
require(survival)
require(ggplot2)
setwd("~/Git/violation-data-analysis")
load("./San Antonio/output/result.RData")
train <- complete.active.quarters %>% filter(active)
train <- train %>% mutate(severe = num.death + num.dis > 0)

hist(train$num.days.restrict)

# good mine/bad mine
# http://www.markhneedham.com/blog/2014/11/26/r-dplyr-select-random-rows-from-a-data-frame/
set.seed(1)
train.positive <- train %>% filter(severe)
train.negative <- train %>% filter(!severe) %>% sample_n(nrow(train.positive))
train.training <- rbind(train.positive, train.negative)
train.training <- train.training %>%
  mutate(magic.num = ifelse(last.year.viol == 0,
                        last.year.viol / last.three.years.viol * 3,
                        1)
         )
ggplot(train.training, aes(magic.num, fill = severe)) + geom_density(alpha = 0.2)

#
y <- rchisq(500, df = 3)
## Q-Q plot for Chi^2 data against true theoretical distribution:
# qqplot(qchisq(ppoints(500), df = 3), y)
qqline(y, distribution = function(p) qnorm(p, mean = 3.3, sd = 1.78),
       prob = c(0.1, 0.6), col = 2)


# lognormal 
training.nonzero <- complete.active.quarters %>% filter(num.days.lost >0 & active)
qqnorm(log(training.nonzero$num.days.lost))
qqline(log(training.nonzero$num.days.lost), distribution = function(p) qnorm(p, mean = 3.3, sd = 1.78))
      # distribution = function(p) qnorm(p, mean = 3.3, sd = 1.78))


train.non.zero <- train %>% filter(num.days.lost > 0)
plot(ecdf(train.non.zero$num.days.lost))

qqnorm((train %>% filter(num.days.lost > 0))$num.days.lost)

top.days.lost <- complete.active.quarters %>% filter(active) %>% arrange(desc(num.days.lost)) %>% select(mine_id, mine.name, year, quarter, num.days.lost)
head(top.days.lost, 10)

# Lightning strike at Shoal Creek mine injures 6
# http://blog.al.com/spotnews/2007/06/lightning_strike_at_mine_injur.html
View(accidents %>% filter(mine_id == 102901 & ai_dt == "2007-06-27") %>% arrange(desc(days_lost)))


# train <- train %>% rowwise() %>% mutate(high_severity = num.death > 0 | num.days.lost > 100)
# train <- train[, c(1:5, 22, 6:21)]
# train %>% count(high_severity)

# View(train %>% filter(mine_id == 1102752))
# new_era <- accidents %>% filter(mine_id == 1102752 & cal_qtr == 2 & cal_yr == 2005) %>% arrange(
#   desc(days_lost)
# )
# View(new_era)
# 
# summary(lm(num.days.lost + num.days.restrict ~ last.quarter.viol+last.year.viol+last.three.years.viol, data=train %>% filter(active)))

cutoff <- 50
bad <- train %>% filter((num.death > 0 | num.dis > 0 | num.days.lost + num.days.restrict > cutoff))
bad$mark <- 'bad'
good <- train %>% filter( num.death == 0 & num.dis == 0 & num.days.lost + num.days.restrict <= cutoff)
good$mark <- 'good'
goodbad <- rbind(good, bad)
goodbad <- goodbad %>% rowwise() %>% mutate(ratio = (last.year.viol / (last.three.years.viol / 3)))
ggplot(goodbad, aes(ratio, fill = mark)) + geom_density(alpha = 0.2)

ggplot(train %>% filter(active & last.year.lost > 0), aes(last.year.lost / last.three.years.lost * 3)) + geom_density()

head(goodbad %>% filter(ratio == 4))

View(train %>% filter(mine_id == 100004)) %>% rowwise() %>% mutate(ratio = last.year.viol / (last.three.years.viol / 4))

#ggplot(goodbad, aes(ratio)) + geom_density(alpha = 0.2)

plot(ecdf(x = train$num.death + train$num.dis))
qqnorm(train$num.days.lost)

# msha_glm <- clogit(high_severity ~ num.days.lost + viol.quantity + strata(mine_id),
#                    data = train%>% top_n(100) %>% filter(active) %>% select(mine_id, num.days.lost, high_severity, viol.quantity))
# 
# print(msha_glm)

sapply(complete.active.quarters, function(x) sum(is.na(x)))

# lm on composite num.days.lost
summary(lm(0*num.death+1*num.days.lost+1*num.days.restrict~last.quarter.lost+last.year.lost+last.three.years.lost
           +last.quarter.restrict+last.year.restrict+last.three.years.restrict
           +last.quarter.viol+last.year.viol+last.three.years.viol
           +last.quarter.death+last.year.death+last.three.years.death, 
           data=train ))


# logistic regression
train <- complete.active.quarters
die.or.dis <- train %>% filter(active & (num.death > 0 | num.dis >0))
summary(lm(num.death + num.dis~last.quarter.viol+last.year.viol+last.three.years.viol,
           data=die.or.dis))
