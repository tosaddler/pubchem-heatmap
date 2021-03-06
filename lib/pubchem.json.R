require(tidyverse)
require(jsonlite)
require(stringr)
require(data.table)
require(clusterSim)

pubchem.parse <- function(vec_chemid, vec_index = c("Pharmacology and Biochemistry", "Use and Manufacturing", "Identification")) {
    master <- data.frame()
    vec_chem_names <- vector()
    vec_json <- c("Pharmacology and Biochemistry", "Use and Manufacturing", "Identification", "Safety and Hazards", "Toxicity")
    vec_csv <- c("PubMed Citations", "Patents", "Biosystems and Pathways", "BioAssay Results")

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

            vec_temp <- vector()

            # Subset desired section
            df_chem <- df[[j]]

            if (is.element(j, vec_json)) {
                if (j == "Pharmacology and Biochemistry" | j == "Use and Manufacturing" | j == "Identification") {
                    for (k in 1:length(df_chem$Section)) {
                        for (l in 1:length(df_chem$Section[[k]]$Information)) {
                            vec_temp <- c(vec_temp, df_chem$Section[[k]]$Information[[l]]$StringValue)
                        }
                    }
                } else if (j == "Safety and Hazards" | j == "Toxicity") {
                    for (k in 1:length(df_chem$Section)) {
                        for (l in 1:length(df_chem$Section[[k]]$Section)) {
                            for (m in 1:length(df_chem$Section[[k]]$Section[[l]]$Information)) {
                                vec_temp <- c(vec_temp, df_chem$Section[[k]]$Section[[l]]$Information[[m]]$StringValue)
                            }
                        }
                    }
                }

                vec_temp <- paste(vec_temp, sep = "", collapse = "")
                vec_temp <- str_replace_all(vec_temp, "\\<.*?\\>", "")
                vec_temp <- str_count(vec_temp, "\\S+")

            } else if (is.element(j, vec_csv)) {
                if (j == "PubMed Citations") {
                    df_csv <- fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22pmid%22%5D,%22collection%22:%22pubmed%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", i, "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22articlepubdate%22%5D%7D%5D"))
                } else if (j == "Patents") {
                    df_csv <- fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22patentid%22%5D,%22collection%22:%22patent%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", i,"%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22patentsubmdate%22,%22patentgrantdate%22%5D%7D%5D"))
                } else if (j == "Biosystems and Pathways") {
                    df_csv <- fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%7B%22download%22:%5B%22bsid%22%5D,%22collection%22:%22biosystem%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", i,"%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D"))
                } else if (j == "BioAssay Results") {
                    df_csv <- fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22activity%22%5D,%22collection%22:%22bioactivity%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", i, "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22activity%22,%22acvalue%22,%22sid%22%5D%7D%5D"))
                }
                vec_temp <- c(vec_temp, nrow(df_csv))
            }
            vec_temp <- as.data.frame(vec_temp)
            names(vec_temp) <- j
            if (length(df_temp) < 1) {
                df_temp <- vec_temp
            } else {
                df_temp <- bind_cols(df_temp, vec_temp)
            }
        }

        # TODO Put function to write scraped page to database.

        master <- bind_rows(master, df_temp)
    }

    # master <- as.data.frame(sapply(master, function(x) {str_count(x, "\\S+")}))

    master <- data.Normalization(master, type = "n8")

    row.names(master) <- vec_chem_names

    return(master)
}
