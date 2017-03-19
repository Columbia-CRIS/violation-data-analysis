rm(list=ls())

# initialize
library(dplyr)
library(survival)
library(caret)
library(e1071)
setwd("~/Git/violation-data-analysis")
load("./San Antonio/output/result.RData")

sigmoid <- function(x) {
  1 / (1 + exp(-x))
}

# use nonzero fatality or permenant disability as severe label
active.quarters <- complete.active.quarters %>% filter(active)
active.quarters <- active.quarters %>% mutate(
  severe = ifelse(
    num.death + num.dis > 0, TRUE, FALSE
  )
)

# fixed effects model with conditional logistic regression on **COMBINED** data
fe.cmb.model <- clogit(severe ~ last.quarter.lost+last.year.lost+last.three.years.lost
                   +last.quarter.restrict+last.year.restrict+last.three.years.restrict
                   +last.quarter.viol+last.year.viol+last.three.years.viol
                   +last.quarter.death+last.year.death+last.three.years.death
                   + strata(mine_id), data = active.quarters)
summary(fe.cmb.model)

# test the fixed effects model (see top 20 fatal accidents since 2005)
fe.cmb.prediction <- predict(object = fe.cmb.model, type = "lp") %>% sigmoid()
fe.cmb.result <- active.quarters %>% select(mine_id, mine.name, year, quarter, num.death, num.dis, severe)
fe.cmb.result$prob <- fe.cmb.prediction
fe.cmb.result <- fe.cmb.result %>% mutate(
  pred = ifelse(
    prob > 0.5, TRUE, FALSE
  )
)
head(fe.cmb.result %>% filter(year >= 2005) %>% arrange(desc(num.death)), 20)

# confusion matrix and other performance metrics
fe.cmb.performance <- confusionMatrix(data = fe.cmb.result$pred, reference = fe.cmb.result$severe, positive = "TRUE")
print(fe.cmb.performance)

# regular logistic regression
glm.model <- glm(severe ~ 
                   last.quarter.lost+last.year.lost+last.three.years.lost
                 +last.quarter.restrict+last.year.restrict+last.three.years.restrict
                 +last.quarter.viol+last.year.viol+last.three.years.viol
                 +last.quarter.death+last.year.death+last.three.years.death,
                 data = active.quarters, family = binomial(link='logit'))
summary(glm.model)

glm.prediction <- predict(object = glm.model, type = "response")
glm.result <- active.quarters %>% select(mine_id, mine.name, year, quarter, num.death, num.dis, severe)
glm.result$prob <- glm.prediction
glm.result <- glm.result %>% mutate(
  pred = ifelse(
    prob > 0.5, TRUE, FALSE
  )
)
head(glm.result %>% filter(year >= 2005) %>% arrange(desc(num.death)), 20)
glm.performance <- confusionMatrix(data = glm.result$pred, reference = glm.result$severe, positive = "TRUE")
print(glm.performance)

# train and test
set.seed(1)
data.len <- nrow(active.quarters)
train.indices <- sample(seq_len(nrow(active.quarters)), size = floor(data.len / 2))
active.quarters.train <- active.quarters[train.indices, ]
active.quarters.result <- active.quarters[-train.indices, ]
active.quarters.result <- active.quarters.result %>% filter(is.element(mine_id, unique(active.quarters.train$mine_id)))

fe.div.model <- clogit(severe ~ last.quarter.lost+last.year.lost+last.three.years.lost
                   +last.quarter.restrict+last.year.restrict+last.three.years.restrict
                   +last.quarter.viol+last.year.viol+last.three.years.viol
                   +last.quarter.death+last.year.death+last.three.years.death
                   + strata(mine_id), data = active.quarters.train)
summary(fe.div.model)

fe.div.prediction <- predict(object = fe.div.model, newdata = active.quarters.result,type = "lp") %>% sigmoid()
fe.div.result <- active.quarters.result %>% select(mine_id, mine.name, year, quarter, num.death, num.dis, severe)
fe.div.result$prob <- fe.div.prediction
fe.div.result <- fe.div.result %>% mutate(
  pred = ifelse(
    prob > 0.5, TRUE, FALSE
  )
)
head(fe.div.result %>% filter(year >= 2005) %>% arrange(desc(num.death)), 20)

# confusion matrix and other performance metrics
fe.div.performance <- confusionMatrix(data = fe.div.result$pred, reference = fe.div.result$severe, positive = "TRUE")
print(fe.div.performance)

# output file
save(
  # active.quarters, 
     sigmoid,
     # fe.cmb.model, 
     fe.cmb.result, fe.cmb.performance,
     # glm.model, 
     glm.result, glm.performance,
     # fe.div.model, 
     fe.div.result, fe.div.performance,
     file="./San Antonio/output/results_fixed_effects.RData")