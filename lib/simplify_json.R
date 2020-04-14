UseTOCHeading <- function(x) {
  print("wait")
  toc_names <- sapply(x, function(x) {x$TOCHeading})
  x <- lapply(x, function(x) {x[which(names(x) %in% c("Section"))]})
  names(x) <- toc_names
  return(x)
}

SimplifySection <- function(x) {
  toc_names <- sapply(x, function(x) {x$TOCHeading})
}
