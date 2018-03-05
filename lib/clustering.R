require(tidyverse)

ClusterCompounds <- function(df) {
  # df.dend <-
  # return(df.dend)
  return(df)
}

FinalizeDF <- function(df, chem.names) {
  if (chem.names == TRUE) {
    row.names(df) <- as.vector(df$name.info)
  } else {
    row.names(df) <- as.vector(df$compound.id)
  }
  df <- dplyr::select(df, -compound.id, -cactvs.info, -name.info)
  return(df)
}
