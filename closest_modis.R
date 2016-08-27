library(memisc)
library(reshape2)

RS <- read.csv("~/Projects/DataKind/PlantDiseaseSpread/data/RustSurvey+EarthEngine.csv")

# Convert obsdate to datetime
RS$ObsDate <- as.Date(levels(RS$ObsDate), "%m/%d/%Y %H:%M:%S %p")[RS$ObsDate]
RS$JulianDay <- as.numeric(format(RS$ObsDate, "%j"))
RS$ObsMonth <- format(RS$ObsDate, "%m")
RS$ObsDoM <- format(RS$ObsDate, "%d")

# Identify the relevant composite period for MODIS data
# Meant to be bimonthly - cycles 1 & 2 are jan, etc.
# 19 is missing - use 18 for early Oct.
RS$MODIS_MOD13Q1_period <- with(RS, cases(
  "01"= ObsMonth=="01" & ObsDoM <= 15,
  "02"= ObsMonth=="01" & ObsDoM > 15,
  "03"= ObsMonth=="02" & ObsDoM <= 14,
  "04"= ObsMonth=="02" & ObsDoM > 14,
  "05"= ObsMonth=="03" & ObsDoM <= 15,
  "06"= ObsMonth=="03" & ObsDoM > 15,
  "07"= ObsMonth=="04" & ObsDoM <= 15,
  "08"= ObsMonth=="04" & ObsDoM > 15,
  "09"= ObsMonth=="05" & ObsDoM <= 15,
  "10"= ObsMonth=="05" & ObsDoM > 15,
  "11"= ObsMonth=="06" & ObsDoM <= 15,
  "12"= ObsMonth=="06" & ObsDoM > 15,
  "13"= ObsMonth=="07" & ObsDoM <= 15,
  "14"= ObsMonth=="07" & ObsDoM > 15,
  "15"= ObsMonth=="08" & ObsDoM <= 15,
  "16"= ObsMonth=="08" & ObsDoM > 15,
  "17"= ObsMonth=="09" & ObsDoM <= 15,
  "18"= (ObsMonth=="09" & ObsDoM > 15) | (ObsMonth=="10" & ObsDoM <= 15),
  "20"= ObsMonth=="10" & ObsDoM > 15,
  "21"= ObsMonth=="11" & ObsDoM <= 15,
  "22"= ObsMonth=="11" & ObsDoM > 15,
  "23"= ObsMonth=="12" & ObsDoM <= 15,
  "24"= ObsMonth=="12" & ObsDoM > 15
))

# Melt into long format 
RS.m <- melt(RS, id.vars=c("Location.ID", "ObsDate", "MODIS_MOD13Q1_period"))
RS.m <- subset(RS.m, grepl("MODIS_MOD13Q1", RS.m$variable))

# Discard all rows where $variable does not match MODIS_MOD13Q1_##
RS.m$pattern <- paste("MODIS_MOD13Q1_", RS.m$MODIS_MOD13Q1_period, "_", sep="")
RS.m$keep <- mapply(grepl, RS.m$pattern, RS.m$variable)

RS.m <- subset(RS.m, RS.m$keep==TRUE)

# Create new variable names. Cast back into wide format & append to RS dataframe.
RS.m$newvar <- mapply(sub, RS.m$pattern, "MODIS_MOD13Q1_closest_", RS.m$variable)

RS.m$variable <- RS.m$newvar
RS.m$newvare <- RS.m$pattern <- RS.m$keep <- NULL
RS.m$MODIS_MOD13Q1_period <- RS.m$Obsdate <- NULL
RS.m$newvar <- NULL
RS.m$ObsDate <- NULL

RS.append <- dcast(RS.m, Location.ID ~ variable)

RS <- merge(RS, RS.append, by="Location.ID")

# Any MODIS data with a pixel reliability code of -1, 2, or 3 should be ignored/discarded. 
# 0 and 1 can be kept.
# See quality code descriptions at 
# https://lpdaac.usgs.gov/dataset_discovery/modis/modis_products_table/mod13q1
