source(here::here("commons.R"))

plan_okayama <- 
  drake::drake_plan(
    df_mesh33 = 
      administration_mesh(33, type = "city"),
    okym_files =
      fs::dir_ls(here::here("data-raw"),
                 regexp = "(5133|5134|5233|5234|5333|5334).txt$",
                 recursive = TRUE) %>% 
      ensurer::ensure_that(length(.) == 12L),
    df_pop_okym95 = 
      okym_files %>% 
      stringr::str_subset("data-raw/1995") %>% 
      purrr::map(~ pop_mesh(.x)) %>%
      purrr::reduce(rbind) %>% 
      inner_join(df_mesh33 %>% 
                   st_set_geometry(NULL), by = "meshcode") %>% 
      verify(dim(.) == c(3984, 6)),
    df_pop_okym15 =
      okym_files %>%
      stringr::str_subset("data-raw/2015") %>% 
      purrr::map(~ pop_mesh(.x)) %>%
      purrr::reduce(rbind) %>% 
      inner_join(df_mesh33 %>% 
                   st_set_geometry(NULL), by = "meshcode") %>% 
      verify(dim(.) == c(4921, 6)),
    strings_in_dots = "literals")
drake::make(plan_okayama)
drake::loadd(list = plan_okayama$target)


# Compared with gender ----------------------------------------------------
df_mapdeck_okym_woman <- 
  df_pop_okym15 %>%
  var_uncount(population_woman, scale = 10)

mapdeck(style = mapdeck_style("dark"), 
        pitch = 45,
        location = c(133.819566, 34.655107),
        zoom = 9) %>%
  add_grid(
    data = df_mapdeck_okym_woman,
    lon = "longitude",
    lat = "latitude",
    cell_size = 1800,
    elevation_scale = 20,
    colour_range = RColorBrewer::brewer.pal(10, "Reds"),
    layer_id = "grid_layer")

df_mapdeck_okym_man <- 
  df_pop_okym15 %>%
  var_uncount(population_man, scale = 10)

mapdeck(style = mapdeck_style("dark"), 
        pitch = 45,
        location = c(133.819566, 34.655107),
        zoom = 9) %>%
  add_grid(
    data = df_mapdeck_okym_man,
    lon = "longitude",
    lat = "latitude",
    cell_size = 1800,
    elevation_scale = 20,
    colour_range = RColorBrewer::brewer.pal(10, "Blues"),
    layer_id = "grid_layer")

