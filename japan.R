source(here::here("commons.R"))

# Making workflow -----------------------------------------------------------
plan_files <- 
  drake::drake_plan(
    jpn_files95 =
      fs::dir_ls(here::here("data-raw", "1995"),
                 regexp = ".txt$",
                 recursive = TRUE) %>% 
      ensurer::ensure_that(length(.) == 151L),
    jpn_files15 =
      fs::dir_ls(here::here("data-raw", "2015"),
                 regexp = ".txt$",
                 recursive = TRUE) %>% 
      ensurer::ensure_that(length(.) == 151L),
    df_pop_jpn95 = 
      jpn_files95 %>% 
      purrr::map(~ pop_mesh(.x)) %>% 
      purrr::reduce(rbind) %>% 
      st_set_geometry(NULL) %>% 
      dplyr::select(meshcode, population_total),
    df_pop_jpn15 = 
      jpn_files15 %>% 
      purrr::map(~ pop_mesh(.x)) %>% 
      purrr::reduce(rbind) %>% 
      ensurer::ensure_that(identical(class(.), 
                                     c("sf", "tbl_df", "tbl", "data.frame"))) %>% 
      verify(dim(.) == c(178397, 7)),
    df_pop_jpn_diff =
      df_pop_jpn15 %>%
      dplyr::select(meshcode, population_total, geometry) %>% 
      left_join(
        df_pop_jpn95 %>% 
          rename(population_total95 = population_total),
        by = "meshcode"
      ) %>% 
      mutate(diff = population_total - population_total95),
    strings_in_dots = "literals")
drake::make(plan_files)

drake::loadd(list = "df_pop_jpn15")
df_mapdeck_japan <- 
  df_pop_jpn15 %>% 
  var_uncount(population_total, scale = 10)

mapdeck(style = mapdeck_style("light"), 
        pitch = 45,
        location = c(139.024556, 36.104611),
        zoom = 5) %>%
  add_grid(
    data = df_mapdeck_japan,
    lon = "longitude",
    lat = "latitude",
    cell_size = 2000,
    elevation_scale = 80,
    colour_range = scico::scico(30, palette = "lajolla"),
    layer_id = "grid_layer")


# Differenced 1995 and 2015 ------------------------------------------
drake::loadd(list = "df_pop_jpn_diff")

df_mapdeck_diff_increase <- 
  df_pop_jpn_diff %>% 
  dplyr::filter(diff >= 0) %>% 
  var_uncount(diff, scale = 10)
df_mapdeck_diff_decrease <- 
  df_pop_jpn_diff %>% 
  dplyr::filter(diff < 0) %>% 
  mutate(diff = abs(diff)) %>% 
  var_uncount(diff, scale = 10)

mapdeck(style = mapdeck_style("light"),
        pitch = 45,
        location = c(139.024556, 36.104611),
        zoom = 5) %>%
  add_grid(
    data = df_mapdeck_diff_increase,
    lon = "longitude",
    lat = "latitude",
    cell_size = 2000,
    elevation_scale = 80,
    colour_range = RColorBrewer::brewer.pal(5, "Greens"),
    layer_id = "grid_layer"
  ) %>%
  add_grid(
    data = df_mapdeck_diff_decrease,
    lon = "longitude",
    lat = "latitude",
    cell_size = 2000,
    elevation_scale = 80,
    colour_range = RColorBrewer::brewer.pal(5, "Oranges"),
    layer_id = "grid_layer2"
  )
