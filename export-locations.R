# Export lat/long & date to use for fetching moar Earth Engine data

vars_to_keep <- c("Location.ID", "ObsDate", "Latitude", "Longitude")
locs <- RS[vars_to_keep]

locs <- subset(locs, Longitude != 0 & Latitude != 0)

write.csv(locs, "~/Projects/DataKind/PlantDiseaseSpread/data/locs.csv", row.names=FALSE)
