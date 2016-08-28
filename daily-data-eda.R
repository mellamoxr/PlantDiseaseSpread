# Load modis daily data
library(lubridate)
library(plyr)

rs$ObsDate <- as.Date(levels(rs$ObsDate), "%m/%d/%Y %H:%M:%S %p")[rs$ObsDate]
vars_to_keep <- c("Location.ID", "ObsDate", "GrowthStageName", "StemRust.Binary", "YellowRust.Binary", "NoRust.Binary")
tmp <- rs[vars_to_keep]

dailies$year <- substring(dailies$index, 13, 16)
dailies$month <- substring(dailies$index, 18, 19)
dailies$day <- substring(dailies$index, 21, 22)
dailies$date <- as.Date(paste(dailies$year, dailies$month, dailies$day, sep="-"))

dailies <- merge(modis_daily_data, tmp, by="Location.ID")
dailies$days.before.survey <- difftime(dailies$date, dailies$ObsDate, unit="days")

plot <- ggplot(dailies, aes(x=days.before.survey, y=EVI, color=NoRust.Binary)) 
plot <- plot + geom_line()
plot <- plot + facet_wrap(~ Location.ID, scales="free")
plot 

# Fit a regression line for each Location.ID
library(data.table)
set.seed(1)
dat <- data.table(dailies)
models <- dat[,list(intercept=coef(lm(EVI~days.before.survey))[1], coef=coef(lm(EVI~days.before.survey))[2]),by=Location.ID]
models <- data.frame(models)

dailies <- merge(dailies, models, by="Location.ID", all.x=TRUE)

plot <- ggplot(dailies, aes(x=coef, color=NoRust.Binary)) + geom_density()
plot
