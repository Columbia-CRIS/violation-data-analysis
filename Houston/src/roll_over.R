roll_over <- function(data, quarter_level, longest_period, actual_start_year,end_year){
  start_year <- actual_start_year-longest_period
  
  number_years <-  end_year - start_year + 1
  
  mines_with_accidents_post_start_year <- (data %>% filter(CAL_YR >= actual_start_year))$MINE_ID %>% unique()
  
  blank_full_quarter_level_days_lost <- data.frame(MINE_ID = rep(mines_with_accidents_post_start_year, each = 4 * number_years),
                                                   QUARTER = rep(1:4, times = length(mines_with_accidents_post_start_year) * number_years),
                                                   YEAR = rep(rep(start_year:end_year, times = rep(4, number_years)),
                                                              times = length(mines_with_accidents_post_start_year)),
                                                   NUM_DAYS_LOST = 0)
  
  full_quarter_level_days_lost <- anti_join(blank_full_quarter_level_days_lost, quarter_level,
                                            by = c("MINE_ID" = "MINE_ID", "QUARTER" = "CAL_QTR", "YEAR" = "CAL_YR"))
  
  full_quarter_level_days_lost <- rbind(full_quarter_level_days_lost,
                                        quarter_level %>% 
                                        select(MINE_ID, QUARTER=CAL_QTR, YEAR=CAL_YR, NUM_DAYS_LOST=base) %>% 
                                        data.frame() %>% filter(YEAR >= start_year) %>% 
                                        filter(YEAR <= end_year)) %>% arrange(MINE_ID,YEAR,QUARTER)
  
  
  ## Challenge: Calculating past period statistics
  ## lag will put value of index n - 1 at index n
  ## roll_sum will do a sum from the specified number of previous rows and put NA's at the beginning
  ## We filter with actual.start.year so there are no NA's. 
  ##   (The year that data is ready and the year that data needs to start being used are different.)
  full_quarter_level_days_lost <- full_quarter_level_days_lost %>% 
                                  group_by(MINE_ID) %>%
                                  mutate(LAST_QUARTER = lag(NUM_DAYS_LOST),
                                       LAST_YEAR = roll_sum(lag(NUM_DAYS_LOST), 4, align = "right", fill = NA),
                                       LAST_THREE_YEARS = roll_sum(lag(NUM_DAYS_LOST), 12, align = "right", fill = NA)) %>%
                                  filter(YEAR >= actual_start_year)
  
  return(full_quarter_level_days_lost)
}


save(roll_over , file = "./Houston/data/roll_over.RData")
