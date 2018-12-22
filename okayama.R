source(here::here("commons.R"))

plan_okayama <- 
  drake::drake_plan(
    df_mesh33 = 
      administration_mesh(33, type = "city"),
    okym_files = 
      fs::dir_ls(here::here("data-raw", "2015"),
                 regexp = "(5133|5134|5233|5234|5333|5334).txt$") %>% 
      ensurer::ensure_that(length(.) == 6L),
    df_pop_okym =
      okym_files %>%
      purrr::map(~ pop_mesh(.x)) %>%
      purrr::reduce(rbind) %>% 
      inner_join(df_mesh33 %>% 
                   st_set_geometry(NULL), by = "meshcode") %>% 
      verify(dim(.) == c(4921, 7)),
    strings_in_dots = "literals")
drake::make(plan_okayama)
drake::loadd(list = plan_okayama$target)

df_mapdeck_okym <- 
  df_pop_okym %>%
  var_uncount(population_total, scale = 100)

mapdeck(style = mapdeck_style("light"), 
        pitch = 45,
        location = c(133.919566, 34.655107),
        zoom = 9) %>%
  add_grid(
    data = df_mapdeck_okym,
    lon = "longitude",
    lat = "latitude",
    cell_size = 1800,
    elevation_scale = 20,
    colour_range = scico::scico(30, palette = "tokyo"),
    layer_id = "grid_layer")

