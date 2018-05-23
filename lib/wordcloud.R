ClickValue <- function(df, d) {
  section <- names(df)[d$x[[1]]]
  compound_name <- rownames(df)[d$y[[1]]]
  return(paste("Compound:", compound_name,
               "| Section:", section))
}
