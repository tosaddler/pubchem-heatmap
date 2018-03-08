SelectSections <- function(df,
                           pharm_bio,
                           pharm_bio_sections,
                           use_manufacturing,
                           use_manufacturing_sections,
                           identification,
                           identification_sections,
                           safety,
                           safety_sections,
                           toxicity,
                           toxicity_sections,
                           literature,
                           literature_sections,
                           bio_path,
                           bio_path_sections) {
  temp <- dplyr::select(df, compound.id, name.info, cactvs.info)
  if (pharm_bio == TRUE) {
    if (length(pharm_bio_sections) > 0) {
      temp.df <- dplyr::select(df, one_of(pharm_bio_sections))
      temp <- bind_cols(temp, temp.df)
    } else {
      temp.df <- dplyr::select(df, matches("Pharmacology and Biochemistry"))
      temp <- bind_cols(temp, temp.df)
    }
  }
  return(temp)
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
