rm(list=ls())

library(dplyr)
library(survival)
library(caret)
library(e1071)
setwd("~/Git/violation-data-analysis")
load("./San Antonio/output/result.RData")

sigmoid <- function(x) {
  1 / (1 + exp(-x))
}

active.quarters <- complete.active.quarters %>% filter(active)
active.quarters <- active.quarters %>% mutate(
  severe = ifelse(
    num.death + num.dis > 0, TRUE, FALSE
  )
)
fe.model <- clogit(severe ~ 
                     last.quarter.lost+last.year.lost+last.three.years.lost
                   +last.quarter.restrict+last.year.restrict+last.three.years.restrict
                   +last.quarter.viol+last.year.viol+last.three.years.viol
                   +last.quarter.death+last.year.death+last.three.years.death
                   + strata(mine_id), data = active.quarters)
summary(fe.model)



fe.predict <- predict(object = fe.model, type = "lp") %>% sigmoid()
test <- active.quarters %>% select(mine_id, mine.name, year, quarter, num.death, num.dis, severe)
test$prob <- fe.predict
test <- test %>% mutate(
  prediction = ifelse(
    prob > 0.5, TRUE, FALSE
  )
)
head(test %>% filter(year >= 2005) %>% arrange(desc(num.death)), 20)

test.performance <- confusionMatrix(data = test$prediction, reference = test$severe, positive = "TRUE")
print(test.performance)

save(fe.model, active.quarters, test, test.performance, file="./San Antonio/output/results_fixed_effects.RData")
