#' Read population count text file
#'
#' @file target file
#' @description Convert to meshcode
#' sf geometry.
pop_mesh <- function(file) {
  
  meshcode <- geometry <- NULL
  
  target_vars <- 
    c("meshcode",
      paste("population", 
            c("total", "man", "woman"),
            sep = "_"),
      "setai")
  
  
  checked <- 
    check_yr(file)
  
  if (checked == "before2015") {
    df <- 
      readr::read_csv(file = file, 
                    skip = 2,
                    col_names = target_vars,
                    col_types = "cdddd",
                    locale = readr::locale(encoding = "cp932"))
  }

  if (checked == "after2015") {
    df <- 
      readr::read_csv(file = file, 
                    skip = 2,
                    col_names = target_vars,
                    col_types = paste0("c___ddd", # 7 
                                       paste(rep("_", 21), collapse = ""),
                                       "d", # 29
                                       paste(rep("_", 16), collapse = "")),
                    locale = readr::locale(encoding = "cp932"))  
  }
  
  df %>% 
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

check_yr <- function(file) {
  
  checked <- 
    readr::read_lines(file, n_max = 1) %>% 
    stringr::str_count(",")
  
  ifelse(
    checked == 4L,
    "before2015",
    "after2015"
  )
}
