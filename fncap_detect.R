# Get packages.

library(tidyverse)
library(magrittr)
library(terra)
# library(luna)
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

# so we have ####_####_(Path)(Row)_(DateCaptured)_(DateProcessed)_(Collection)_(Tier)_(Band).TIF

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

dat_landsat_read = 
  "data/data_landsat" %>% 
  list.files %>% 
  paste0("data/data_landsat/", .) %>% 
  tibble("path" = .) %>% 
  filter(str_sub(path, -6, -5) %in% c("B4", "B5")) %>% 
  # Get metadata.
  mutate(col = path %>% str_sub(29, 31),
         row = path %>% str_sub(32, 34),
         date = path %>% str_sub(36, 43) %>% as_date,
         year = date %>% year,
         month = date %>% month,
         day = date %>% day,
         collection = path %>% str_sub(-12, -11),
         tier = path %>% str_sub(-9, -8),
         band = path %>% str_sub(-6, -5)) %>% 
  # Get data.
  mutate(dat = path %>% map(rast)) %>%
  # Cut some data.
  filter(tier == "T1")

dat_landsat_reference = 
  dat_landsat_read %>% 
  group_by(col, row) %>% 
  filter(date == date %>% min & band == "B4") %>% 
  ungroup %>% 
  pull(dat) %>% 
  sprc %>% 
  merge

values(dat_landsat_reference) <- NA

dat_landsat = 
  dat_landsat_read %>% 
  # filter(row_number() %in% 1:10) %>% 
  # mutate(dat = dat %>% map(merge, dat_landsat_reference)) %>% 
  group_by(month, band) %>% 
  nest %>% 
  ungroup %>% 
  mutate(data = 
           data %>% 
           map(pull, "dat") %>% 
           map(sprc) %>% 
           map(mosaic))

# note that landsat_reference doesn't seem worth keeping so this could all be one pipeline.

# pivot_wider on band, get NDVI, then map Lane County mask, then get (1) plots of raw values by month and (2) change by month
