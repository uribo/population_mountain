source(here::here("commons.R"))

plan_tokyo23 <- 
  drake::drake_plan(
    sf_tky_23ward =
      jpn_pref(13, district = TRUE) %>% 
      dplyr::filter(stringr::str_detect(city, "区$")) %>% 
      verify(nrow(.) == 23) %>% 
      st_union() %>% 
      st_sf(),
    tokyo_files =
      fs::dir_ls(here::here("data-raw"),
                 regexp = "5339.txt$",
                 recursive = TRUE) %>% 
      ensurer::ensure_that(length(.) == 5),
    df_pops_tky_23ward =
      tokyo_files %>% 
      purrr::set_names(seq(1995, 2015, by = 5)) %>% 
      purrr::map(~ pop_mesh(.x) %>% 
                   st_join(sf_tky_23ward,
                           join = st_within,
                           left = FALSE)) %>% 
      ensurer::ensure_that(length(.) == 5),
    df_pop_tokyo_diff =
      df_pops_tky_23ward$`2015` %>%
      dplyr::select(meshcode, population_total, geometry) %>% 
      left_join(
        df_pops_tky_23ward$`1995` %>% 
          st_set_geometry(NULL) %>% 
          select(meshcode, population_total95 = population_total),
        by = "meshcode"
      ) %>% 
      mutate(diff = population_total - population_total95),
    strings_in_dots = "literals"
  )
drake::make(plan_tokyo23)
drake::loadd(list = plan_tokyo23$target)


drake::loadd(list = "df_pops_tky_23ward")
df_mapdeck_tokyo <- 
  df_pops_tky_23ward$`1995` %>% 
  var_uncount(population_total, scale = 10)

mapdeck(style = mapdeck_style("light"),
        pitch = 45,
        location = c(139.7671, 35.6812),
        zoom = 9) %>% 
  add_grid(
    data = df_mapdeck_tokyo,
    lon = "longitude",
    lat = "latitude",
    cell_size = 1200,
    elevation_scale = 20,
    colour_range = scico::scico(30, palette = "tokyo"),
    layer_id = "grid_layer")

# Differenced 1995 and 2015 ------------------------------------------
drake::loadd(list = "df_pop_tokyo_diff")

df_mapdeck_diff_increase <- 
  df_pop_tokyo_diff %>% 
  dplyr::filter(diff >= 0) %>% 
  var_uncount(diff, scale = 10)
df_mapdeck_diff_decrease <- 
  df_pop_tokyo_diff %>% 
  dplyr::filter(diff < 0) %>% 
  mutate(diff = abs(diff)) %>% 
  var_uncount(diff, scale = 10)

mapdeck(style = mapdeck_style("light"),
        pitch = 45,
        location = c(139.7671, 35.6812),
        zoom = 9) %>%
  add_grid(
    data = df_mapdeck_diff_increase,
    lon = "longitude",
    lat = "latitude",
    cell_size = 1200,
    elevation_scale = 20,
    colour_range = RColorBrewer::brewer.pal(5, "Greens"),
    layer_id = "grid_layer"
  ) %>%
  add_grid(
    data = df_mapdeck_diff_decrease,
    lon = "longitude",
    lat = "latitude",
    cell_size = 1200,
    elevation_scale = 20,
    colour_range = RColorBrewer::brewer.pal(5, "Oranges"),
    layer_id = "grid_layer2"
  )
