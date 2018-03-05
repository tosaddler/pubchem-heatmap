require(tidyverse)

PubChemCluster <- function(df) {
  names(df) <- as.vector(df$compound.id)
  df <- dplyr::select(df, -compound.id, -cactvs.info)
  return(df)
}

FinalizeDF <- function(df) {
  names(df) <- as.vector(df$compound.id)
  df <- dplyr::select(df, -compound.id, -cactvs.info)
  return(df)
}
