library(ggplot2)
library(dplyr)
library(plm)

setwd("~/Git/violation-data-analysis/A New Hope")
load("days_lost.accident.Rdata")

test.year.quarter <- full.days_lost.accidents.date %>% rowwise() %>%
  mutate(year = year + quarter / 5)
result <- plm(num.days.lost ~ last.year.x, index = c("mine_id", "year"), model = "within", data = test.year.quarter)
summary(result)

result <- lm(num.days.lost~last.quarter.x + last.year.x + last.three.years.x + last.quarter.y + last.year.y + last.three.years.y, data = full.days_lost.accidents.date)
summary(result)

result <- lm(num.days.lost~last.year.x+mine_id, data=full.days_lost.accidents.date)
summary(result)

# http://stats.stackexchange.com/questions/79723/interpretation-of-r2-in-fixed-effects-panel-regression
reg.fe <- plm(num.days.lost~last.year.x, data = full.days_lost.accidents.date, index="mine_id",model = "within")
summary(reg.fe)
length(unique(test$mine_id))

test.nonezero <- test %>% filter(num.days.lost >0 & last.year.x >0)
reg = lm(num.days.lost~last.quarter.x+last.quarter.y+last.year.x+last.year.y+last.three.years.x+last.three.years.y,data=test)
summary(reg)

new.data.high <- test %>% 
  filter(num.days.lost >= 250) %>%
  select(mine_id, year, quarter, num.days.lost, last.year.x, last.year.y)

new.data.low <- test %>% 
  filter(num.days.lost < 250 & num.days.lost > 0) %>%
  select(mine_id, year, quarter, num.days.lost, last.year.x, last.year.y)

new.data <- test %>% 
  filter(num.days.lost >0) %>%
  select(mine_id, year, quarter, num.days.lost, last.year.x, last.year.y)


qplot(last.year.x, num.days.lost, data=new.data.low, color='green')

qplot(new.data.high$last.year.y, geom="histogram",binwidth=10,xlim=c(0,1000))

new.data.high$sr <- 'high'
new.data.low$sr <- 'low'
both = rbind(new.data.low,new.data.high)
ggplot(both, aes(last.year.x)) + geom_bar(alpha=0.5, width=10) + xlim(0,1000) + ylim(0,1000)

sd(new.data.high$last.year.x)

ggplot(new.data.low, aes(last.year.y)) + 
  geom_histogram(data = new.data.high, fill = "red", alpha = 0.2) 
#  geom_histogram(data = new.data.low, fill = "blue", alpha = 0.2)




ggplot(data=mpg,mapping = aes(x=cty,y=hwy))+geom_point()+aes(color=factor(mpg$year))
View(mpg)

ggplot(data=both,mapping=aes(x=last.year.x,y=num.days.lost)) + geom_point(alpha=0.05,position = "jitter") + aes(color=factor(both$sr))

ggplot(data=both,aes(last.year.x)) + geom_histogram(alpha=0.05) + aes(color=factor(both$sr)) + xlim(0,2000) + ylim(0,10000)

summary(lm(formula = num.days.lost~last.year.x,new.data.low))


data("Produc", package = "plm")
head(Produc)
zz <- plm(num.days.lost ~ last.year.x,
          data = test, index = c("mine_id"))
summary(zz)

yy <- plm(log(gsp) ~ log(pcap) + log(pc) + log(emp) + unemp,
          data = Produc, index = c("state","year"))
summary(yy)

summary(lm(formula = num.days.lost ~ last.year.x, test %>% filter(num.days.lost >= 0)))

ggplot(data=test, mapping=aes(x=last.year.x,y=num.days.lost)) + geom_point()
ggplot(data=new.data.high, mapping=aes(x=last.year.x,y=num.days.lost)) + geom_point(alpha=0.5)



# http://stats.stackexchange.com/questions/25568/estimating-the-distribution-from-data
# http://stackoverflow.com/questions/23050928/error-in-plot-new-figure-margins-too-large-scatter-plot
require(fitdistrplus)
par("mar")
par(mar=c(1,1,1,1))
test.nz <- test %>% filter(num.days.lost > 0)
f <- fitdist(log(test.nz$num.days.lost), "norm")
plotdist(log(test.nz$num.days.lost),"norm",para=list(mean=f$estimate[1], sd=f$estimate[2]))




test.upper <- test %>% filter(mine_id==4608436)
summary(lm(num.days.lost~last.year.x,data=test.upper))
qplot(last.year.x,num.days.lost,data=test.upper)

test.top <- test %>% top_n(100,num.days.lost) %>% arrange(desc(num.days.lost))



require("PerformanceAnalytics")
my_data <- test %>% select(num.days.lost, last.quarter.x, last.year.x)
chart.Correlation(my_data, histogram=TRUE, pch=19)
