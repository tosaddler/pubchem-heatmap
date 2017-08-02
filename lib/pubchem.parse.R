require(tidyverse)
require(jsonlite)
require(stringr)

pubchem.parse <- function(vec_chemid, vec_index = c("Pharmacology and Biochemistry", "Use and Manufacturing", "Identification")) {
    master <- data.frame()
    
    for (i in 1:length(vec_chemid)) {
        
        # Bring in full JSON for compound
        df <- read_json(paste0("https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/", vec_chemid[i],
                               "/JSON/?response_type=save$response_basename=CID_", vec_chemid[i]))
        df <- df$Record$Section
        
        # Renaming list headers
        category_names <- vector()
        for (i in 1:length(df)) {
            category_names <- c(category_names, df[[i]]$TOCHeading)
        }
        names(df) <- category_names
        
        # Initialize temporary data frame to pull info from each section
        df_temp <- data.frame()
        
        # Loop through each desired section
        for (i in vec_index) {
            
            # Subset desired section
            df_chem <- df[[i]]
            
            # Initialize vector to subset individual information
            vec_temp <- vector()
            if (i == "Pharmacology and Biochemistry" | i == "Use and Manufacturing" | i == "Information") {
                for (j in 1:length(df_chem$Section)) {
                    for (k in 1:length(df_chem$Section[[j]]$Information)) {
                        vec_temp <- c(vec_temp, df_chem$Section[[j]]$Information[[k]]$StringValue)
                    }
                }
            } else {
                for (j in 1:length(df_chem$Section)) {
                    for (k in 1:length(df_chem$Section[[j]]$Information)) {
                        vec_temp <- c(vec_temp, df_chem$Section[[j]]$Information[[k]]$StringValue)
                    }
                }
            }
            
            vec_temp <- paste(vec_temp, sep = "", collapse = "")
            vec_temp <- str_replace_all(vec_temp, "\\<.*?\\>", "")
            vec_temp <- as.data.frame(vec_temp)
            
            names(vec_temp) <- i
            
            if (length(df_temp) < 1) {
                df_temp <- vec_temp
            } else {
                df_temp <- bind_cols(df_temp, vec_temp)
            }
        }
        master <- bind_rows(master, df_temp)
    }
    return(master)
}