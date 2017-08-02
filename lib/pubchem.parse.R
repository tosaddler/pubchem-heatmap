require(tidyverse)
require(jsonlite)
require(stringr)

pubchem.parse <- function(vec_chemid, vec_index = c("Pharmacology and Biochemistry", "Use and Manufacturing", "Identification")) {
    master <- data.frame()
    vec_chem_names <- vector()
    
    for (i in 1:length(vec_chemid)) {
        
        # Bring in full JSON for compound
        df <- read_json(paste0("https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/", vec_chemid[i],
                               "/JSON/?response_type=save$response_basename=CID_", vec_chemid[i]))
        df <- df$Record$Section
        
        # Renaming list headers
        category_names <- vector()
        for (j in 1:length(df)) {
            category_names <- c(category_names, df[[j]]$TOCHeading)
        }
        names(df) <- category_names
        
        # Pulling compound names for heatmap
        vec_chem_names <- c(vec_chem_names, df$`Names and Identifiers`$Section[[1]]$Information[[1]]$StringValue)
        
        # Initialize temporary data frame to pull info from each section
        df_temp <- data.frame()
        
        # Loop through each desired section
        for (j in vec_index) {
            
            # Subset desired section
            df_chem <- df[[j]]
            
            # Initialize vector to subset individual information
            vec_temp <- vector()
            if (i == "Pharmacology and Biochemistry" | j == "Use and Manufacturing" | j == "Information") {
                for (k in 1:length(df_chem$Section)) {
                    for (l in 1:length(df_chem$Section[[k]]$Information)) {
                        vec_temp <- c(vec_temp, df_chem$Section[[k]]$Information[[l]]$StringValue)
                    }
                }
            } else {
                for (k in 1:length(df_chem$Section)) {
                    for (l in 1:length(df_chem$Section[[k]]$Information)) {
                        vec_temp <- c(vec_temp, df_chem$Section[[k]]$Information[[l]]$StringValue)
                    }
                }
            }
            
            
            vec_temp <- paste(vec_temp, sep = "", collapse = "")
            vec_temp <- str_replace_all(vec_temp, "\\<.*?\\>", "")
            vec_temp <- as.data.frame(vec_temp)
            
            names(vec_temp) <- j
            
            if (length(df_temp) < 1) {
                df_temp <- vec_temp
            } else {
                df_temp <- bind_cols(df_temp, vec_temp)
            }
        }
        master <- bind_rows(master, df_temp)
    }
    
    master <- as.data.frame(sapply(master, function(x) {str_count(x, "\\S+")}))
    
    row.names(master) <- vec_chem_names
    
    return(master)
}