expected_mat <- function(start, end) {
  m <- cbind(start = as.integer(start), end = as.integer(end))
  dimnames(m) <- list(NULL, c("start", "end"))
  m
}

expected_captures <- function(match, ...) {
  groups <- list(...)
  provided <- names(groups)

  if (length(groups) > 0) {
    if (is.null(provided)) {
      names(groups) <- rep("", length(groups))
    } else {
      provided[is.na(provided)] <- ""
      names(groups) <- provided
    }
  }

  list(matches = match, captures = groups)
}
