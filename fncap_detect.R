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
  project("EPSG:2992") # For FERNS.

# Get FERNS data.

#  Note that these need to be replaced with a "final" run.

dat_notifications = 
  "data/data_notifications.gdb" %>% 
  vect %>% 
  crop(dat_boundaries)

# Get Landsat data.
#  Note luna in rspatial ecosystem
#  and LandsatTS

getLandsat()
