if(!exists("is_run_parent")){
  rm(list=ls())
  # setwd("C:/Users/CATHY/OneDrive/Documents/2016-2017 Junior/15 Mines Research/violation-data-analysis")
  setwd("~/Git/violation-data-analysis")
  # load consolidated data
  load("./Houston/output/Consolidated.RData")  
}

# initialize ----
require(dplyr)
require(survival)
require(caret)
require(e1071)
library(plm)

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

# divide 50% training and 50% testing data
labeled_all_data <- labeled_data_death_dis_only
set.seed(1)
data_len <- nrow(labeled_data_death_dis_only)

groups <-
	labeled_all_data %>%
	select(MINE_ID) %>%
	distinct(MINE_ID) %>%
	rowwise() %>%
	mutate(group=sample(c("train","test"),1,replace=TRUE,prob=c(.5,.5)))

labeled_all_data <- labeled_all_data %>% left_join(groups)
labeled_test <- filter(labeled_all_data, group == "test")
labeled_train <- filter(labeled_all_data, group == "train")

# fixed effects on combined data ----
# fixed effects model
in_sample_model <- clogit(SEVERE ~ 
                         LAST_QUARTER_DAYS_LOST + LAST_YEAR_DAYS_LOST + LAST_THREE_YEARS_DAYS_LOST +
                         LAST_QUARTER_DAYS_RESTRICT + LAST_YEAR_DAYS_RESTRICT + LAST_THREE_YEARS_DAYS_RESTRICT +
                         LAST_QUARTER_DEATH + LAST_YEAR_DEATH + LAST_THREE_YEARS_DEATH +
                         LAST_QUARTER_DIS + LAST_YEAR_DIS + LAST_THREE_YEARS_DIS +
                         LAST_YEAR_VIOLATION + LAST_THREE_YEARS_VIOLATION +
                         LAST_QUARTER_PENALTY + LAST_YEAR_PENALTY + LAST_THREE_YEARS_PENALTY
                         # + strata(MINE_ID), # use this, we get 82% (TP) + 56% (TN)
                         + strata(CURRENT_MINE_TYPE,COAL_METAL_IND), # use this, we get 58% (TP) + 77% (TN)
                         data = labeled_all_data, method="breslow"
                       )
summary(in_sample_model)

# labeled_all_data

# test the fixed effects model (see top 20 fatal accidents since 2005)
in_sample_prediction <- predict(object = in_sample_model, newdata = labeled_all_data, type = "lp") %>% sigmoid()
in_sample_result <- labeled_all_data %>% select(
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

# fixed effects on training/testing data ----
# fixed effects model
out_sample_model <- clogit(SEVERE ~ 
                            LAST_QUARTER_DAYS_LOST + LAST_YEAR_DAYS_LOST + LAST_THREE_YEARS_DAYS_LOST +
                            LAST_QUARTER_DAYS_RESTRICT + LAST_YEAR_DAYS_RESTRICT + LAST_THREE_YEARS_DAYS_RESTRICT +
                            LAST_QUARTER_DEATH + LAST_YEAR_DEATH + LAST_THREE_YEARS_DEATH +
                            LAST_QUARTER_DIS + LAST_YEAR_DIS + LAST_THREE_YEARS_DIS +
                            LAST_YEAR_VIOLATION + LAST_THREE_YEARS_VIOLATION +
                            LAST_QUARTER_PENALTY + LAST_YEAR_PENALTY + LAST_THREE_YEARS_PENALTY
                          #+ strata(MINE_ID),
                          + strata(CURRENT_MINE_TYPE,COAL_METAL_IND), 
                          data = labeled_train, method="breslow"
)
summary(out_sample_model)

# labeled_all_data

# test the fixed effects model (see top 20 fatal accidents since 2005)
out_sample_prediction <- predict(object = out_sample_model, newdata = labeled_test, type = "lp") %>% sigmoid()
out_sample_result <- labeled_test %>% select(
  MINE_ID, CURRENT_MINE_NAME, YEAR, QUARTER, NUM_DEATH, NUM_DIS, SEVERE)
out_sample_result$PROBABILITY <- out_sample_prediction
out_sample_result <- out_sample_result %>% mutate(
  PREDICTION = ifelse(
    PROBABILITY > 0.5, TRUE, FALSE
  )
)
head(out_sample_result %>% arrange(desc(NUM_DEATH), CURRENT_MINE_NAME), 10)
head(out_sample_result %>% arrange(desc(PROBABILITY), CURRENT_MINE_NAME), 10)

# confusion matrix and other performance metrics
out_sample_performance <- confusionMatrix(data = out_sample_result$PREDICTION, 
                                         reference = out_sample_result$SEVERE, 
                                         positive = "TRUE")
print(out_sample_performance)

# output file ----
save(
     sigmoid,
     in_sample_result, in_sample_performance,
     out_sample_result, out_sample_performance,
     file="./Houston/output/Result_clogit.RData")
