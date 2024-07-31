#' Retrieve coordinates and attributes
#'
#' The functions `get_lon` and `get_lat` return numeric vectors of pixel center locations.
#' `get_epoch` and `get_time` return (most likely) Date vectors, but support for
#' POSIXct in the future is possible. The function `get_res` returns a two element
#' numeric vector of resolution in x and y.
#'
#' @export
#' @param x ncdf4 object
#' @return numeric vector
get_lon <- function(x){
  x$dim$lon$vals
}

#' @export
#' @rdname get_lon
get_lat <- function(x){
  x$dim$lat$vals
}

#' @export
#' @rdname get_lon
get_epoch <- function(x){

  u = x$dim$time$units

  if (grepl("days", u, fixed = TRUE)){
      epoch = as.Date(u, format = "days since %Y-%m-%d 00:00:00")
  } else {
    stop("epoch unit not known - contact developer")
  }
  epoch
}

#' @export
#' @rdname get_lon
get_time <- function(x){

  epoch = get_epoch(x)

  if (inherits(epoch, "Date")){
    t = x$dim$time$vals + epoch
  } else {
    stop("epoch unit not known - contact developer")
  }
  t
}

#' @export
#' @rdname get_lon
get_res <- function(x){
  c(abs(diff(x$dim$lon$vals[1:2])),
    abs(diff(x$dim$lat$vals[1:2])))
}

#' @export
#' @rdname get_lon
get_varnames <- function(x){
  names(x$var)
}

#' @export
#' @rdname get_lon
get_dimnames <- function(x){
  names(x$dim)
}

#' Retrieve navigation information needed for subsetting based upon a
#' bounding box.
#'
#' @export
#' @param x ncdf4 object
#' @param bb either a named 4 element vector `(xmin, ymin, xmax, ymax)` or a
#'   spatial object (sf or stars) from which a bounding box can be determined.
#' @param time either an index or time value for retrieval
#' @return navigation list including
#'  * start - the starting indices need for `ncvar_get()`
#'  * count - the counts needed for `ncvar_get()`
#'  * bb - a 4 element vector of the enclosing bounding box (actual)
#'  * res the actual resolution
#'  * bb_ - the requested bounding box
#'  * time_ - the requested time
get_nav = function(x, bb = c(xmin = -77,   ymin = 36.5,
                             xmax = -42.5, ymax = 56.7),
                   time = 1){


  if (!inherits(bb, "numeric")) bb = sf::st_bbox(bb)

  closest_index = function(x, y){
    which.min(abs(x-y))
  }

  if (!inherits(time, "numeric")){
    tm = get_time(x)
    tix = findInterval(time, tm)
  } else {
    tix = time
  }

  lon = get_lon(x)
  left = max(c(closest_index(lon, bb[['xmin']]) - 1, 1))
  right = min(c(closest_index(lon, bb[['xmax']]) + 1, length(lon)))

  lat = get_lat(x)
  top = max(c(closest_index(lat, bb[['ymax']]) - 1, 1))
  bottom = min(c(closest_index(lat, bb[['ymin']]) + 1, length(lat)))

  res = get_res(x)
  half = res/2

  list(
      start = c(left, top, tix),
      count = c(right-left + 1, bottom - top + 1, length(tix)),
      bb = c(xmin = lon[left] - half[1],
              ymin = lat[bottom] - half[2],
              xmax = lon[right] + half[1],
              ymax = lat[top] + half[2]),
      res = res,
      bb_ = bb,
      time_ = time)
}


#' Retrieve a variable
#'
#' @export
#' @param x ncdf4 object
#' @param var chr, the name of the variable to retrieve
#' @param nav list, a navigation list from `get_nav`
#' @param form chr, one of 'matrix' or 'stars'
get_var = function(x, var = "chlor_a",
                   nav = get_nav(x),
                   form = c("matrix", "stars")[2]){

  stopifnot(var %in% names(x$var))

  m = ncdf4::ncvar_get(x, varid = var,
                       start = nav$start,
                       count = nav$count)
  if (tolower(form[1]) == 'stars'){
    m = stars::st_as_stars(sf::st_bbox(nav$bb, crs = 4326),
                           values = m,
                           nx = nav$count[1],
                           ny = nav$count[2]) |>
      rlang::set_names(var)
  }

  m
}


