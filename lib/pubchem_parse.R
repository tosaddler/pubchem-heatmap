require(tidyverse)
require(jsonlite)
require(stringr)
require(data.table)
require(clusterSim)
require(data.table)

CollapseTextVector <- function(vec) {
  vec <- paste(vec, sep = " ", collapse = " ")
  vec <- str_replace_all(vec, "\\<.*?\\>", "")
  return(vec)
}

ScrapeSection <- function(section.node, subsection.heading) {
  subsection <- tryCatch({
    return(section.node$Climb(TOCHeading = subsection.heading)$Information$Get("StringValue"))
  }, error = function(err) {
    print(paste("ScrapeSection: ", err))
    return("")
  })
  subsection <- subsection[!is.na(subsection)]
  subsection.text <- CollapseTextVector(subsection)
  subsection <- str_count(subsection.text, "\\S+")
  df <- data.frame(subsection, subsection.text)
  names(df) <- c(subsection.heading, paste0(subsection.heading, ".text"))
  return(df)
}

CreateSectionsList <- function() {
  sections <- list(`Pharmacology and Biochemistry` =
                         c("Pharmacology",
                           "Absorption, Distribution and Excretion"),
                     `Use and Manufacturing` =
                         c("Methods of Manufacturing",
                           "Consumption"))
  return(sections)
}

PubChemParse <- function(chem.ids) {

  master <- data.frame()

  pubchem.sections <- CreateSectionsList()

  # TODO(tosaddler): Put function here that checks if there is a database
  # entry for the compounds.

  # TODO(tosaddler): If database entry exists and is up-to-date, then
  # pull those compounds and add them to the master data frame.

  # TODO(tosaddler): Remove the pulled compounds from chem.ids.

  for (i in 1:length(chem.ids)) {

    # Initialize temporary data frame to pull info from each section
    compound.temp <- data.frame(compound.id = as.numeric(chem.ids[[i]]))

    # Import JSON for compound
    compound.url <- paste0("https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/",
                           chem.ids[i],
                           "/JSON/?response_type=save$response_basename=CID_",
                           chem.ids[i])

    compound.tree <- compound.url %>%
                      read_json() %>%
                      FromListSimple()

    # Simplifying to the section we need, other section contains references
    compound.tree <- compound.tree$Record$Section

    for (j in 1:length(pubchem.sections)) {

      section.node <- compound.tree$Climb(TOCHeading = names(pubchem.sections)[[j]])$Section

      # section.node <- tryCatch({
      #   return(compound.tree$Climb(TOCHeading = names(pubchem.sections)[[j]])$Section)
      # }, error = function(err) {
      #   print(paste("Error: Section does not exist."))
      #   return(Node$new("blankNode"))
      # })

      for (k in 1:length(pubchem.sections[[j]])) {
        temp.section <- ScrapeSection(section.node, pubchem.sections[[j]][[k]])
        compound.temp <- bind_cols(compound.temp, temp.section)
      }
    }

    # Literature Sections
    # pubmed_citations <-    nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22pmid%22%5D,%22collection%22:%22pubmed%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", i, "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22articlepubdate%22%5D%7D%5D")))
    # patent_identifiers <-  nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22patentid%22%5D,%22collection%22:%22patent%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", i,"%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22patentsubmdate%22,%22patentgrantdate%22%5D%7D%5D")))
    # biosystems_pathways <- nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%7B%22download%22:%5B%22bsid%22%5D,%22collection%22:%22biosystem%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", i,"%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D")))
    # bioassay_results <-    nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22activity%22%5D,%22collection%22:%22bioactivity%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", i, "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22activity%22,%22acvalue%22,%22sid%22%5D%7D%5D")))

    # TODO Insert function to write completed table to database

    master <- bind_rows(master, compound.temp)
  }

  master <- data.Normalization(master, type = "n8")

  # row.names(master) <- chem.ids

  return(master)
}
