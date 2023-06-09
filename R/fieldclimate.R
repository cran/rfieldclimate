#' Create authentication headers
#' @rdname fc_request
#' @param method request method
#' @param path request path (required)
#' @param public_key public key.
#'  Read by default from env variable `FC_PUBLIC_KEY`
#' @param private_key private key.
#'  Read by default from env variable `FC_PRIVATE_KEY`
#' @return an object of type "request" as returned by [httr::add_headers()].
#' @seealso https://api.fieldclimate.com/v2/docs/#authentication-hmac
#' @export
#' @examples
#' fc_headers(path = "/user", public_key = "invalid", private_key = "invalid")
fc_headers <- function(method = c("GET", "PUT", "POST", "DELETE"),
    path = NULL,
    public_key = Sys.getenv("FC_PUBLIC_KEY"),
    private_key = Sys.getenv("FC_PRIVATE_KEY")) {

  stopifnot(!is.null(public_key))
  stopifnot(!is.null(private_key))

  if (nchar(public_key) == 0)
    stop("public_key missing. Is the environment variable 'FC_PUBLIC_KEY' set?")

  if (nchar(private_key) == 0)
    stop("private_key missing.Is the environment variable 'FC_PUBLIC_KEY' set?")

  stopifnot(!is.null(path))
  method <- match.arg(method)

  date <- format(lubridate::now("GMT"), format = "%a, %d %b %Y %H:%M:%S GMT")
  msg <- paste0(method, path, date, public_key)
  signature <- digest::hmac(key = private_key, object = msg, algo = "sha256")
  auth <- paste0("hmac ", public_key, ":", signature)
  httr::add_headers(Date = date, Authorization = auth)
}


#' general request function
#' @rdname fc_request
#' @param body request body named list. Will be passed to [httr::VERB()] and
#'   form-encoded.
#' @param verbose logical, should the request be printed?
#' @param timeout number of seconds to wait for a response before giving up.
#' @return a list with the parsed response.
#' @description authentication is done via hmac, see [fc_headers()].
#' @export
#' @examples
#' \dontrun{
#' fc_request("GET", "/user")
#' }
fc_request <- function(method = c("GET", "PUT", "POST", "DELETE"),
    path = NULL,
    body = NULL,
    public_key = Sys.getenv("FC_PUBLIC_KEY"),
    private_key = Sys.getenv("FC_PRIVATE_KEY"),
    verbose = FALSE,
    timeout = 10) {

  stopifnot(!is.null(path))
  method <- match.arg(method)

  api <- "https://api.fieldclimate.com/v2"
  qurl <- httr::modify_url(api, path = path)

  headers <- fc_headers(method = method, path = path, public_key = public_key,
    private_key = private_key)
  if (verbose)
    message(method, " ", qurl)
  resp <- try(httr::VERB(verb = method, url = qurl, headers, body = body,
                     encode = "form", httr::timeout(timeout)))

  if (inherits(resp, "try-error")) {
    warning("API-Error: ",  attr(resp, "condition")$message)
    return(NULL)
  }


  if (httr::status_code(resp) == 204) {
    warning("No data for specified time period.")
    return(NULL)
  }

  parsed <- resp %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(simplifyVector = FALSE)

  if (httr::http_error(resp)) {
    stop(
      sprintf(
        "fieldclimate API request failed [%s]\n%s",
        httr::status_code(resp),
        parsed$message
      ),
      call. = FALSE
    )
  }

  return(parsed)
}

#' Ping fieldclimate API
#' @param timeout number of seconds to wait for a response before giving up.
#' @return a logical whether the API is reachable or not.
#' @export
#' @examples
#' \dontrun{
#' fc_ping()
#' }
fc_ping <- function(timeout = 2) {
  api <- "https://api.fieldclimate.com/v2"
  resp <- try(httr::GET(url = api, httr::timeout(timeout)))

  if (inherits(resp, "try-error")) {
    message("API-Error: ",  attr(resp, "condition")$message)
    return(FALSE)
  }

  return(TRUE)
}