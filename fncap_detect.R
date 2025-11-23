# Get packages.

library(tidyverse)
library(magrittr)
library(patchwork)
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

dat_boundaries_32610 = dat_boundaries %>% project("EPSG:32610")

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

# dat_landsat_4 =
#   "data/data_landsat/LC08_L1TP_046030_20150607_20200909_02_T1_B4.TIF" %>%
#   rast
# 
# dat_landsat_5 =
#   "data/data_landsat/LC08_L1TP_046030_20150607_20200909_02_T1_B5.TIF" %>%
#   rast
# 
# dat_landsat_ndvi = (dat_landsat_5 - dat_landsat_4) / (dat_landsat_5 + dat_landsat_4)

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

dat_landsat = 
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
  filter(tier == "T1") %>% 
  # Get a mosaic by month and band.
  group_by(month, band) %>% 
  nest %>% 
  ungroup %>% 
  mutate(data = 
           data %>% 
           map(pull, "dat") %>% 
           map(sprc) %>% 
           map(mosaic)) %>% 
  pivot_wider(names_from = band,
              values_from = data) %>% 
  mutate(NDVI = map2(B4, B5, ~ (.y - .x) / (.y + .x)),
         NDVI_Mask = map(NDVI, ~ mask(.x, dat_boundaries_32610)) %>% map(., trim),
         NDVI_Mask_Lag = NDVI_Mask %>% lag) %>% 
  filter(month > min(month)) %>% 
  mutate(NDVI_Delta = map2(NDVI_Mask, NDVI_Mask_Lag, ~ (.x - .y))) %>% 
  select(Month = month, NDVI_Delta)

# Visualization

#  Legend

# min_1 = global(dat_landsat$NDVI_Delta[[1]], min, na.rm = TRUE)
# min_2 = global(dat_landsat$NDVI_Delta[[2]], min, na.rm = TRUE)
# min_3 = global(dat_landsat$NDVI_Delta[[3]], min, na.rm = TRUE)
# min_all = min(min_1, min_2, min_3)
# 
# max_1 = global(dat_landsat$NDVI_Delta[[1]], max, na.rm = TRUE)
# max_2 = global(dat_landsat$NDVI_Delta[[2]], max, na.rm = TRUE)
# max_3 = global(dat_landsat$NDVI_Delta[[3]], max, na.rm = TRUE)
# max_all = max(max_1, max_2, max_3)

#  Plot

vis_7 = 
  ggplot() + 
  geom_spatraster(data = dat_landsat$NDVI_Delta[[1]] %>% rename(NDVI = 1),
                  aes(fill = NDVI)) +
  scale_fill_whitebox_c(limits = c(-1, 1),
                        breaks = c(-1, 0, 1),
                        palette = "muted") +
  labs(title = "June-July 2015",
       fill = "Change in Mean NDVI") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5))

vis_8 = 
  ggplot() + 
  geom_spatraster(data = dat_landsat$NDVI_Delta[[2]] %>% rename(NDVI = 1),
                  aes(fill = NDVI)) +
  scale_fill_whitebox_c(limits = c(-1, 1),
                        breaks = c(-1, 0, 1),
                        palette = "muted") +
  labs(title = "July-August 2015",
       fill = "Change in Mean NDVI") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5))

vis_9 = 
  ggplot() + 
  geom_spatraster(data = dat_landsat$NDVI_Delta[[3]] %>% rename(NDVI = 1),
                  aes(fill = NDVI)) +
  scale_fill_whitebox_c(limits = c(-1, 1),
                        breaks = c(-1, 0, 1),
                        palette = "muted") +
  labs(title = "August-September 2015",
       fill = "Change in Mean NDVI") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5))

vis_all = 
  vis_7 + 
  vis_8 + 
  plot_annotation(title = "Changes in Mean NDVI, Lane County, OR") +
  plot_layout(guides = 'collect') &
  theme(legend.position = "bottom",
        legend.direction = "horizontal",
        legend.key.height = unit(0.50, "lines"),
        legend.key.width = unit(5, "lines"),
        legend.ticks = element_blank(),
        legend.title = element_blank(),
        plot.title = element_text(hjust = 0.5))

ggsave("vis.png",
       dpi = 300,
       width = 8)
