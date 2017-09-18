require(tidyverse)
require(jsonlite)
require(stringr)
require(data.table)

pubchem.dendrogram <- function(vec_chemid) {
    vec_chem_names <- vector()
    df_master <- data.frame()
    
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
        
        df <- df$`Chemical and Physical Properties`$Section
    }
}