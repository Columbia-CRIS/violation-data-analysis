rm(list=ls())

# initialize ----
library(dplyr)
library(survival)
library(caret)
library(e1071)
setwd("~/Git/violation-data-analysis")
load("./San Antonio/output/result.RData")

sigmoid <- function(x) {
  1 / (1 + exp(-x))
}

# label data ----
labeled.data.death <- complete.active.quarters %>% filter(active) %>% mutate(
  severe = ifelse(
    num.death + num.dis > 0, TRUE, FALSE
  )
)
labeled.data.lost <- complete.active.quarters %>% filter(active) %>% mutate(
  severe = ifelse(
    num.death + num.dis > 0 | num.days.lost > 300, TRUE, FALSE
  )
)

# fixed effects on combined data ----
# fixed effects model
fe.cmb.model <- clogit(severe ~ last.quarter.lost+last.year.lost+last.three.years.lost
                   +last.quarter.restrict+last.year.restrict+last.three.years.restrict
                   +last.quarter.viol+last.year.viol+last.three.years.viol
                   +last.quarter.death+last.year.death+last.three.years.death
                   + strata(mine_id), data = labeled.data.death)
summary(fe.cmb.model)

# test the fixed effects model (see top 20 fatal accidents since 2005)
fe.cmb.prediction <- predict(object = fe.cmb.model, type = "lp") %>% sigmoid()
fe.cmb.result <- labeled.data.death %>% select(mine_id, mine.name, year, quarter, num.death, num.dis, severe)
fe.cmb.result$prob <- fe.cmb.prediction
fe.cmb.result <- fe.cmb.result %>% mutate(
  pred = ifelse(
    prob > 0.5, TRUE, FALSE
  )
)
head(fe.cmb.result %>% filter(year >= 2005) %>% arrange(desc(num.death), mine.name), 10)
head(fe.cmb.result %>% filter(year >= 2005) %>% arrange(desc(prob), mine.name), 10)

# confusion matrix and other performance metrics
fe.cmb.performance <- confusionMatrix(data = fe.cmb.result$pred, reference = fe.cmb.result$severe, positive = "TRUE")
print(fe.cmb.performance)

# logistic regression without fixed effects ----
# regular logistic regression model
glm.model <- glm(severe ~ 
                   last.quarter.lost+last.year.lost+last.three.years.lost
                 +last.quarter.restrict+last.year.restrict+last.three.years.restrict
                 +last.quarter.viol+last.year.viol+last.three.years.viol
                 +last.quarter.death+last.year.death+last.three.years.death,
                 data = labeled.data.death, family = binomial(link='logit'))
summary(glm.model)

glm.prediction <- predict(object = glm.model, type = "response")
glm.result <- labeled.data.death %>% select(mine_id, mine.name, year, quarter, num.death, num.dis, severe)
glm.result$prob <- glm.prediction
glm.result <- glm.result %>% mutate(
  pred = ifelse(
    prob > 0.5, TRUE, FALSE
  )
)
head(glm.result %>% filter(year >= 2005) %>% arrange(desc(num.death), mine.name), 10)
head(glm.result %>% filter(year >= 2005) %>% arrange(desc(prob), mine.name), 10)

glm.performance <- confusionMatrix(data = glm.result$pred, reference = glm.result$severe, positive = "TRUE")
print(glm.performance)

# fixed effects on training and testing data ----
# train and test
set.seed(1)
data.len <- nrow(labeled.data.death)
train.indices <- sample(seq_len(nrow(labeled.data.death)), size = floor(data.len / 2))
labeled.data.death.train <- labeled.data.death[train.indices, ]
labeled.data.death.result <- labeled.data.death[-train.indices, ]
labeled.data.death.result <- labeled.data.death.result %>% filter(is.element(mine_id, unique(labeled.data.death.train$mine_id)))

fe.div.model <- clogit(severe ~ last.quarter.lost+last.year.lost+last.three.years.lost
                   +last.quarter.restrict+last.year.restrict+last.three.years.restrict
                   +last.quarter.viol+last.year.viol+last.three.years.viol
                   +last.quarter.death+last.year.death+last.three.years.death
                   + strata(mine_id), data = labeled.data.death.train)
summary(fe.div.model)

fe.div.prediction <- predict(object = fe.div.model, newdata = labeled.data.death.result,type = "lp") %>% sigmoid()
fe.div.result <- labeled.data.death.result %>% select(mine_id, mine.name, year, quarter, num.death, num.dis, severe)
fe.div.result$prob <- fe.div.prediction
fe.div.result <- fe.div.result %>% mutate(
  pred = ifelse(
    prob > 0.5, TRUE, FALSE
  )
)
head(fe.div.result %>% filter(year >= 2005) %>% arrange(desc(num.death), mine.name), 10)
head(fe.div.result %>% filter(year >= 2005) %>% arrange(desc(prob), mine.name), 10)


# confusion matrix and other performance metrics
fe.div.performance <- confusionMatrix(data = fe.div.result$pred, reference = fe.div.result$severe, positive = "TRUE")
print(fe.div.performance)

# fixed effects on training and testing data (using labeled.data.lost) ----
# fe.div + num.days.lost: train and test
labeled.data.lost.train <- labeled.data.lost[train.indices, ]
labeled.data.lost.result <- labeled.data.lost[-train.indices, ]
labeled.data.lost.result <- labeled.data.lost.result %>% filter(is.element(mine_id, unique(labeled.data.lost.train$mine_id)))

fe.div2.model <- clogit(severe ~ last.quarter.lost+last.year.lost+last.three.years.lost
                       +last.quarter.restrict+last.year.restrict+last.three.years.restrict
                       +last.quarter.viol+last.year.viol+last.three.years.viol
                       +last.quarter.death+last.year.death+last.three.years.death
                       + strata(mine_id), data = labeled.data.lost.train)
summary(fe.div2.model)

fe.div2.prediction <- predict(object = fe.div2.model, newdata = labeled.data.lost.result,type = "lp") %>% sigmoid()
fe.div2.result <- labeled.data.lost.result %>% select(mine_id, mine.name, year, quarter, num.death, num.dis, severe)
fe.div2.result$prob <- fe.div2.prediction
fe.div2.result <- fe.div2.result %>% mutate(
  pred = ifelse(
    prob > 0.5, TRUE, FALSE
  )
)
head(fe.div2.result %>% filter(year >= 2005) %>% arrange(desc(num.death), mine.name), 10)
head(fe.div2.result %>% filter(year >= 2005) %>% arrange(desc(prob), mine.name), 10)


# confusion matrix and other performance metrics
fe.div2.performance <- confusionMatrix(data = fe.div2.result$pred, reference = fe.div2.result$severe, positive = "TRUE")
print(fe.div2.performance)

# output file ----
save(
  # labeled.data.death, 
     sigmoid,
     # fe.cmb.model, 
     fe.cmb.result, fe.cmb.performance,
     # glm.model, 
     glm.result, glm.performance,
     # fe.div.model, 
     fe.div.result, fe.div.performance,
     fe.div2.result, fe.div2.performance,
     file="./San Antonio/output/results_fixed_effects.RData")