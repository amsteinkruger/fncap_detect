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

#  Note that these need to be replaced with a "final" run.

dat_notifications = 
  "data/data_notifications.gdb" %>% 
  vect %>% 
  filter(ActivityType == "Clearcut/Overstory Removal") %>% 
  filter(ActivityUnit == "MBF") %>% 
  filter(LandOwnerType == "Partnership/Corporate Forestland Ownership") %>% 
  project("EPSG:3857") %>% # Redundant.
  crop(dat_boundaries)

# Get Landsat data.


