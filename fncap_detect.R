# Get packages.

library(tidyverse)
library(terra)
library(luna)
library(tidyterra)

# Get administrative boundaries.

dat_boundaries = 
  "data/data_boundaries.gdb" %>% 
  vect %>% 
  filter(STATENAME == "Oregon" & NAME == "Lane") %>% 
  project("EPSG:3857") # For FERNS.

dat_boundaries_4326 = dat_boundaries %>% project("EPSG:4326")

ext_boundaries = dat_boundaries_4326 %>% ext

# Get FERNS data.

dat_notifications = 
  "data/data_notifications.gdb" %>% 
  vect %>% 
  filter(ActivityType == "Clearcut/Overstory Removal") %>% 
  filter(ActivityUnit == "MBF") %>% 
  filter(LandOwnerType == "Partnership/Corporate Forestland Ownership") %>% 
  project("EPSG:3857") %>% # Redundant.
  crop(dat_boundaries)

# Get Landsat data.

#  Scratch

dat_landsat_4 =
  "data/data_landsat/LC08_L1TP_046030_20150607_20200909_02_T1_B4.TIF" %>%
  rast

dat_landsat_5 =
  "data/data_landsat/LC08_L1TP_046030_20150607_20200909_02_T1_B5.TIF" %>%
  rast

dat_landsat_ndvi = (dat_landsat_5 - dat_landsat_4) / (dat_landsat_5 + dat_landsat_4)

dat_landsat_4_1 = dat_landsat_4

dat_landsat_4_2 = 
  "data/data_landsat/LC08_L1TP_045029_20150718_20200908_02_T1_B4.TIF" %>%
  rast

dat_landsat_4_3 = 
  "data/data_landsat/LC08_L1TP_045030_20150702_20200909_02_T1_B4.TIF" %>% 
  rast

# so we have ####_####_(Path)(Row)_(DateCaptured)_(DateProcessed)_(Collection)_(Tier)_(Band).TIF

# and we want to merge by date
# then take means over dates up to quarters (but then we have an extent/spatial origin and resolution problem)
# so double-nest by quarters then dates
# and check that paths/rows work out

# so find a way to get the spatial origin and resolution out over . . . one Landsat cycle?

#  Wrangling

files_landsat_compressed = 
  "data/data_landsat_compressed" %>% 
  list.files %>% 
  paste0("data/data_landsat_compressed/", .) %>% 
  tibble("path" = .) %T>% 
  mutate(out = 
           path %>% 
           map(untar,
               exdir = "data/data_landsat"))

files_landsat_read = 
  "data/data_landsat" %>% 
  list.files %>% 
  paste0("data/data_landsat/", .) %>% 
  tibble("path" = .) %>% 
  filter(str_sub(path, -6, -5) %in% c("B4", "B5"))


