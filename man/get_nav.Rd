% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nc.R
\name{get_nav}
\alias{get_nav}
\title{Retrieve navigation information needed for subsetting based upon a
bounding box.}
\usage{
get_nav(
  x,
  bb = c(xmin = -77, ymin = 36.5, xmax = -42.5, ymax = 56.7),
  time = 1
)
}
\arguments{
\item{x}{ncdf4 object}

\item{bb}{either a named 4 element vector \verb{(xmin, ymin, xmax, ymax)} or a
spatial object (sf or stars) from which a bounding box can be determined.}

\item{time}{either an index or time value for retrieval}
}
\value{
navigation list including
\itemize{
\item start - the starting indices need for \code{ncvar_get()}
\item count - the counts needed for \code{ncvar_get()}
\item bb - a 4 element vector of the enclosing bounding box (actual)
\item res the actual resolution
\item bb_ - the requested bounding box
\item time_ - the requested time
}
}
\description{
Retrieve navigation information needed for subsetting based upon a
bounding box.
}
