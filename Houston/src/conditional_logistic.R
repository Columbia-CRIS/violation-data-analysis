rm(list=ls())

# initialize ----
require(dplyr)
require(survival)
require(caret)
require(e1071)

# choose working directory
setwd("C:/Users/CATHY/OneDrive/Documents/2016-2017 Junior/15 Mines Research/violation-data-analysis")
setwd("~/Git/violation-data-analysis")

# load consolidated data
load("./Houston/output/Consolidated.RData")

# sigmoid function
sigmoid <- function(x) {
  1 / (1 + exp(-x))
}

# label data ----
labeled_data_death_dis_only <- complete_active_quarters %>% filter(ACTIVE) %>% mutate(
  SEVERE = ifelse(
    NUM_DEATH + NUM_DIS > 0, TRUE, FALSE
  )
)
labeled_data_plus_days_lost <- complete_active_quarters %>% filter(ACTIVE) %>% mutate(
  SEVERE = ifelse(
    NUM_DEATH + NUM_DIS > 0 | NUM_DAYS_LOST > 300, TRUE, FALSE
  )
)
# pick one label
labeled_data <- labeled_data_death_dis_only

# fixed effects on combined data ----
# fixed effects model
in_sample_model <- clogit(SEVERE ~ 
                         LAST_QUARTER_DAYS_LOST + LAST_YEAR_DAYS_LOST + LAST_THREE_YEARS_DAYS_LOST +
                         LAST_QUARTER_DAYS_RESTRICT + LAST_YEAR_DAYS_RESTRICT + LAST_THREE_YEARS_DAYS_RESTRICT +
                         LAST_QUARTER_DEATH + LAST_YEAR_DEATH + LAST_THREE_YEARS_DEATH +
                         LAST_QUARTER_DIS + LAST_YEAR_DIS + LAST_THREE_YEARS_DIS +
                         LAST_QUARTER_VIOLATION + LAST_YEAR_VIOLATION + LAST_THREE_YEARS_VIOLATION +
                         LAST_QUARTER_PENALTY + LAST_YEAR_PENALTY + LAST_THREE_YEARS_PENALTY +
                           strata(MINE_ID), #COAL_METAL_IND, CURRENT_MINE_TYPE), 
                         data = labeled_data
                       )
summary(in_sample_model)

# test the fixed effects model (see top 20 fatal accidents since 2005)
in_sample_prediction <- predict(object = in_sample_model, type = "lp") %>% sigmoid()
in_sample_result <- labeled_data %>% select(
  MINE_ID, CURRENT_MINE_NAME, YEAR, QUARTER, NUM_DEATH, NUM_DIS, SEVERE)
in_sample_result$PROBABILITY <- in_sample_prediction
in_sample_result <- in_sample_result %>% mutate(
  PREDICTION = ifelse(
    PROBABILITY > 0.5, TRUE, FALSE
  )
)
head(in_sample_result %>% arrange(desc(NUM_DEATH), CURRENT_MINE_NAME), 10)
head(in_sample_result %>% arrange(desc(PROBABILITY), CURRENT_MINE_NAME), 10)

# confusion matrix and other performance metrics
in_sample_performance <- confusionMatrix(data = in_sample_result$PREDICTION, 
                                         reference = in_sample_result$SEVERE, 
                                         positive = "TRUE")
print(in_sample_performance)

# output file ----
save(
     sigmoid,
     in_sample_result, in_sample_performance,
     file="./Houston/output/Result_clogit.RData")