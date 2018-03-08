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
  if (use_manufacturing == TRUE) {
    if (length(use_manufacturing_sections) > 0) {
      temp.df <- dplyr::select(df, one_of(use_manufacturing_sections))
      temp <- bind_cols(temp, temp.df)
    } else {
      temp.df <- dplyr::select(df, matches("Use and Manufacturing"))
      temp <- bind_cols(temp, temp.df)
    }
    if (identification == TRUE) {
      if (length(pharm_bio_sections) > 0) {
        temp.df <- dplyr::select(df, one_of(identification_sections))
        temp <- bind_cols(temp, temp.df)
      } else {
        temp.df <- dplyr::select(df, matches("Identification"))
        temp <- bind_cols(temp, temp.df)
      }
    }
    if (safety == TRUE) {
      if (length(safety_sections) > 0) {
        temp.df <- dplyr::select(df, one_of(safety_sections))
        temp <- bind_cols(temp, temp.df)
      } else {
        temp.df <- dplyr::select(df, matches("Safety and Hazards"))
        temp <- bind_cols(temp, temp.df)
      }
    }
    if (toxicity == TRUE) {
      if (length(toxicity_sections) > 0) {
        temp.df <- dplyr::select(df, one_of(toxicity_sections))
        temp <- bind_cols(temp, temp.df)
      } else {
        temp.df <- dplyr::select(df, matches("Toxicity"))
        temp <- bind_cols(temp, temp.df)
      }
    }
    if (literature == TRUE) {
      if (length(literature_sections) > 0) {
        temp.df <- dplyr::select(df, one_of(literature_sections))
        temp <- bind_cols(temp, temp.df)
      } else {
        temp.df <- dplyr::select(df, matches("Literature"))
        temp <- bind_cols(temp, temp.df)
      }
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
