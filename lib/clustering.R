require(tidyverse)

ClusterCompounds <- function(df) {
  # row.names(df) <- as.vector(df$compound.id)
  # df <- dplyr::select(df, -compound.id, -cactvs.info)
  return(df)
}

FinalizeDF <- function(df, chem.names) {
  if (chem.names == TRUE) {
    row.names(df) <- as.vector(df$compound.name)
  } else {
    row.names(df) <- as.vector(df$compound.id)
  }
  df <- dplyr::select(df, -compound.id, -cactvs.info, -compound.name)
  return(df)
}
