setwd("~/jy/Regulatory Analysis Research - Prof. Venkat Venkatasubramanian/")

library(dplyr)
library(survival)
library(RcppRoll)

if(!exists("accidents")) {
  accidents <- read.csv("msha_accident_counts2.csv", stringsAsFactors = F)
  accidents <- accidents %>% filter(year >= 2000) %>% filter(year <= 2015)
}
if(!exists("violations")) {
  violations <- read.table("msha_violation_counts2.csv", header = T, sep=",", quote='"', stringsAsFactors=FALSE, fill=TRUE)  
  violations <- violations %>% filter(year >= 2000) %>% filter(year <= 2015)
  violations$total_penalties <- ifelse(is.na(as.numeric(violations$total_penalties)), 0, as.numeric(violations$total_penalties))
}

all.mine.ids <- union(unique(accidents$mine_id), unique(violations$mine_id))

yearly.accidents <- accidents %>% group_by(mine_id, year) %>% summarize(total.accidents = sum(perm_disability + fatality))
yearly.violations <- violations %>% group_by(mine_id, year) %>% summarize(total.violations = sum(num_violations), yearly.total.penalties = sum(total_penalties))


window.size <- 3
start.year <- 2000 + window.size
end.year <- 2015

all.zero.yearly.accidents <- data.frame(mine_id = rep(unique(all.mine.ids), each = length(start.year:end.year)),
                                        year = rep(start.year:end.year, times = length(unique(all.mine.ids))),
                                        total.accidents = rep(0, times = length(unique(all.mine.ids)) * length(start.year:end.year)))
all.zero.yearly.violations <- data.frame(mine_id = rep(unique(all.mine.ids), each = length(start.year:end.year)),
                                         year = rep(start.year:end.year, times = length(unique(all.mine.ids))),
                                         total.violations = rep(0, times = length(unique(all.mine.ids)) * length(start.year:end.year)),
                                         yearly.total.penalties = rep(0, times = length(unique(all.mine.ids)) * length(start.year:end.year)))

full.yearly.accidents <- all.zero.yearly.accidents %>% anti_join(yearly.accidents, by = c("mine_id", "year")) %>% 
                                                       bind_rows(yearly.accidents) %>% arrange(mine_id, year) %>%
                                                       filter(year >= start.year)
full.yearly.violations <- all.zero.yearly.violations %>% anti_join(yearly.violations, by = c("mine_id", "year")) %>%
                                                         bind_rows(yearly.violations) %>% arrange(mine_id, year) %>%
                                                         transform(last.year = lag(total.violations)) %>% 
                                                         transform(last.three.years = roll_mean(lag(total.violations), n = window.size, align = "right", fill = NA)) %>%
                                                         filter(year >= start.year)

training.data <- data.frame(mine.id = full.yearly.accidents$mine_id, accidents = full.yearly.accidents$total.accidents,
                            accident.happened = full.yearly.accidents$total.accidents >= 1,
                            last.year = full.yearly.violations$last.year,
                            ratio = full.yearly.violations$last.year / full.yearly.violations$last.three.years)
training.data <- training.data %>% transform(smoothed.ratio = ifelse(is.na(ratio), last.year, ratio))
conditional.logistic.regression.model <- clogit(accident.happened ~ last.year + smoothed.ratio + strata(mine.id), training.data)
print(summary(conditional.logistic.regression.model))

sigmoid <- function(x) {
  1 / (1 + exp(-x))
}


top.twenty <- training.data %>% mutate(index = row.names(training.data)) %>% 
                                arrange(desc(accidents)) %>% head(20) %>% 
                                .[['index']] %>% as.numeric()
top.twenty.predicted.probabilities <- predict(conditional.logistic.regression.model, training.data, type = "lp") %>% 
                                      .[top.twenty] %>% sigmoid
non.top.twenty.predicted.probabilities <- predict(conditional.logistic.regression.model, training.data, type = "lp") %>% 
                                         .[-top.twenty] %>% sigmoid