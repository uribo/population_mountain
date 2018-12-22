#' Read population count text file
#'
#' @file target file
#' @description Convert to meshcode
#' sf geometry.
pop_mesh <- function(file) {
  
  meshcode <- geometry <- NULL
  
  readr::read_csv(file = file, 
                  skip = 2,
                  col_names = c("meshcode", "hitoku_syori",
                                paste("population", 
                                      c("total", "man", "woman", "age65gt"), 
                                      sep = "_")),
                  col_types = paste0("cc__ddd", 
                                     paste(rep("_", 12), collapse = ""),
                                     "d", 
                                     paste(rep("_", 25), collapse = "")),
                  locale = readr::locale(encoding = "cp932")) %>%
    dplyr::mutate(geometry = purrr::map_chr(meshcode, 
                                            ~ jpmesh::export_mesh(.x) %>% 
                                            sf::st_as_text())) %>% 
    dplyr::mutate(geometry = sf::st_as_sfc(geometry)) %>% 
    sf::st_sf(crs = 4326)
}

#' Convert mapdeck add_grid elevation data.frame
var_uncount <- function(data, bar_var, scale = 100) {
  bar_var <- rlang::enquo(bar_var)
  
  data %>% 
    dplyr::mutate(var = !!bar_var / scale) %>% 
    dplyr::filter(!is.na(!!bar_var)) %>% 
    dplyr::select(var, geometry) %>% 
    sf::st_transform(crs = 6673) %>% 
    sf::st_centroid() %>% 
    sf::st_transform(crs = 4326) %>% 
    dplyr::mutate(
      longitude = sf::st_coordinates(geometry)[, 1],
      latitude = sf::st_coordinates(geometry)[, 2]) %>% 
    sf::st_set_geometry(NULL) %>% 
    tidyr::uncount(var) %>% 
    tibble::as_tibble()
}
