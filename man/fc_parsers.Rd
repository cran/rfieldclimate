% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parsers.R
\name{fc_parse_data}
\alias{fc_parse_data}
\alias{fc_parse_stations}
\title{parse data into long data.frame}
\usage{
fc_parse_data(obj)

fc_parse_stations(obj)
}
\arguments{
\item{obj}{stations object as returned by e.g. \code{\link[=fc_get_user_stations]{fc_get_user_stations()}}}
}
\value{
a data.frame with parsed data.

a data.frame with parsed station data.
}
\description{
parse data into long data.frame

parse stations into data.frame
}
\examples{
\dontrun{
stations <- fc_get_user_stations()
obj <- fc_get_data_range(
  station_id = stations[[1]]$station_name,
  data_group = "raw",
  from = as.integer(as.POSIXct(Sys.time() - 60*60*24)),
  to =  as.integer(as.POSIXct(Sys.time())))
fc_parse_data(obj)
}
\dontrun{
stations <- fc_get_user_stations()
fc_parse_stations(stations)
}
}
