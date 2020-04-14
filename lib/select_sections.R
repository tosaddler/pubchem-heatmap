SelectSections <- function(df,
                           pharm_bio,
                           pharm_bio_sections,
                           use_manufacturing,
                           use_man_sections,
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

  temp <- dplyr::select(df, compound.id, name.info)

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
    if (length(use_man_sections) > 0) {
      temp.df <- dplyr::select(df, one_of(use_man_sections))
      temp <- bind_cols(temp, temp.df)
    } else {
      temp.df <- dplyr::select(df, `Use and Manufacturing`)
      temp <- bind_cols(temp, temp.df)
    }
  }

  if (identification == TRUE) {
    if (length(identification_sections) > 0) {
      temp.df <- dplyr::select(df, one_of(identification_sections))
      temp <- bind_cols(temp, temp.df)
    } else {
      temp.df <- dplyr::select(df, `Identification`)
      temp <- bind_cols(temp, temp.df)
    }
  }

  if (safety == TRUE) {
    if (length(safety_sections) > 0) {
      temp.df <- dplyr::select(df, one_of(safety_sections))
      temp <- bind_cols(temp, temp.df)
    } else {
      temp.df <- dplyr::select(df, `Safety and Hazards`)
      temp <- bind_cols(temp, temp.df)
    }
  }

  if (toxicity == TRUE) {
    if (length(toxicity_sections) > 0) {
      temp.df <- dplyr::select(df, one_of(toxicity_sections))
      temp <- bind_cols(temp, temp.df)
    } else {
      temp.df <- dplyr::select(df, `Toxicity`)
      temp <- bind_cols(temp, temp.df)
    }
  }

  if (literature == TRUE) {
    if (length(literature_sections) > 0) {
      temp.df <- dplyr::select(df, one_of(literature_sections))
      temp <- bind_cols(temp, temp.df)
    } else {
      temp.df <- dplyr::select(df, `Literature`)
      temp <- bind_cols(temp, temp.df)
    }
  }

  if (bio_path == TRUE) {
    if (length(bio_path_sections) > 0) {
      temp.df <- dplyr::select(df, one_of(bio_path_sections))
      temp <- bind_cols(temp, temp.df)
    } else {
      temp.df <- dplyr::select(df, `Biomolecular Interactions and Pathways`)
      temp <- bind_cols(temp, temp.df)
    }
  }

  return(temp)
}

FinalizeDF <- function(df, chem.names, chem.name.length) {
  if (chem.names == TRUE) {
    row.names(df) <- str_trunc(as.vector(df$name.info), chem.name.length)
  } else {
    row.names(df) <- as.vector(df$compound.id)
  }
  df <- dplyr::select(df, -compound.id, -name.info)
  return(df)
}
