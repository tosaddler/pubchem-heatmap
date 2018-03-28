require(tidyverse)
require(jsonlite)
require(stringr)
require(data.tree)
require(clusterSim)
require(data.table)
require(RPostgreSQL)
require(data.table)
source("lib/pubchem_sections.R")

options(stringsAsFactors = FALSE)

CollapseTextVector <- function(vec) {
  vec <- paste(vec, sep = " ", collapse = " ")
  vec <- str_replace_all(vec, "\\<.*?\\>", "")
  return(vec)
}

ScrapeSection <- function(section.node, subsection.heading) {
  subsection <- tryCatch({
    temp <- Clone(section.node$Climb(TOCHeading = subsection.heading)$Information)
    temp$Get("StringValue", filterFun = function(x) {x$level == 2})
  }, error = function(err) {
    print(paste("ScrapeSection: subsection", subsection.heading, "does not exist for compound"))
    ""
  })
  subsection.text <- CollapseTextVector(subsection)
  subsection <- str_count(subsection.text, "\\S+")
  df <- data.frame(subsection, subsection.text)
  names(df) <- c(subsection.heading, paste0(subsection.heading, ".text"))
  return(df)
}

GetSectionNode <- function(parent.node, section.heading) {
  section.node <- tryCatch({
    parent.node$Climb(TOCHeading = section.heading)$Section
  }, error = function(err) {
    print(paste('Error: Section', section.heading, 'does not exist for compound'))
    Node$new("blankNode")
  })
  return(section.node)
}

JoinTempDF <- function(main.df, temp.df) {
  if (length(main.df) == 0) {
    main.df <- temp.df
  } else {
    main.df <- bind_cols(main.df, temp.df)
  }
  return(main.df)
}

DbSafeNames = function(names) {
    names = gsub('[^a-z0-9]+','_',tolower(names))
    names = make.names(names, unique = TRUE, allow_ = TRUE)
    names = gsub('.','_',names, fixed = TRUE)
    names
}

PubChemParse <- function(chem.ids, db, db.bypass = FALSE) {

  master <- data.frame()

  pubchem.sections <- PubChemSections()

  # TODO(tosaddler): If database entry exists and is up-to-date, then
  # pull those compounds and add them to the master data frame.

  # TODO(tosaddler): Remove the pulled compounds from chem.ids.

  for (i in 1:length(chem.ids)) {

    if (db.bypass == FALSE) {
      compound.temp <- dbGetQuery(db, paste('SELECT * FROM pubchem_raw_counts',
                                            'WHERE chem_id = "', chem.ids[[i]], '";'))

    } else {

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

      # Pulling compound name
      compound.name <- compound.tree$Climb(TOCHeading = "Names and Identifiers")$Section$`1`$Information$`1`$StringValue

      # Pulling CACTVS String for clustering
      chem.phys.prop <- compound.tree$Climb(TOCHeading = "Chemical and Physical Properties")$Section
      computed.prop <- chem.phys.prop$Climb(TOCHeading = "Computed Properties")$Information$`1`$Table$Row
      cactvs <- computed.prop$Get(attribute = "BinaryValue")
      cactvs <- cactvs[!is.na(cactvs)]
      names(cactvs) <- "cactvs.info"

      # Initialize temporary data frame to pull info from each section
      compound.temp <- data.frame(compound.id = as.numeric(chem.ids[[i]]),
                                  name.info   = compound.name,
                                  cactvs.info = cactvs)

      for (j in 1:length(pubchem.sections)) {

        section.temp <- data.frame()

        section.node <- GetSectionNode(compound.tree, names(pubchem.sections)[[j]])

        for (k in 1:length(pubchem.sections[[j]])) {

          if (class(pubchem.sections[[j]]) == "list") {
            subsection.node <- GetSectionNode(section.node,
                                              names(pubchem.sections[[j]])[[k]])
            subsection.temp <- data.frame()

            for (l in 1:length(pubchem.sections[[j]][[k]])) {
              temp.df <- ScrapeSection(subsection.node,
                                               pubchem.sections[[j]][[k]][[l]])
              subsection.temp <- JoinTempDF(subsection.temp, temp.df)
            }

            subsection.count <- dplyr::select(subsection.temp, -contains(".text"))
            subsection.total <- data.frame(rowSums(subsection.count))
            subsection.text <-  dplyr::select(subsection.temp, contains(".text"))
            subsection.text <- CollapseTextVector(subsection.text[1, ])
            subsection.temp <- data.frame(subsection.total, subsection.text)
            names(subsection.temp) <- c(names(pubchem.sections[[j]])[[k]],
                                        paste0(names(pubchem.sections[[j]])[[k]], ".text"))
          } else {
            subsection.temp <- ScrapeSection(section.node, pubchem.sections[[j]][[k]])
          }

          section.temp <- JoinTempDF(section.temp, subsection.temp)
        }

        section.count <- dplyr::select(section.temp, -contains(".text"))
        section.total <- data.frame(rowSums(section.count))
        names(section.total) <- names(pubchem.sections)[[j]]

        compound.temp <- data.frame(compound.temp, section.total, section.temp, check.names = FALSE)
      }



      # Literature Sections
      pubmed.citations <-    nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22pmid%22%5D,%22collection%22:%22pubmed%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]], "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22articlepubdate%22%5D%7D%5D")))
      metabolite.ref <-      nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%7B%22download%22:%5B%22cid%22,%22pmid%22,%22reference%22%5D,%22collection%22:%22hmdb%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]], "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D")))
      nature.ref <-          nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%7B%22download%22:%5B%22articletitle%22,%22articlejourname%22,%22articlepubdate%22,%22pmid%22,%22url%22,%22openaccess%22%5D,%22collection%22:%22springernature%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]], "%22%7D%5D%7D,%22order%22:%5B%22scorefloat,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D")))

      lit.total <- sum(pubmed.citations, metabolite.ref, nature.ref)

      literature <- data.frame(`Literature` = lit.total,
                               `PubMed Citations` = pubmed.citations,
                               `Metabolite References` = metabolite.ref,
                               `Springer Nature References` = nature.ref)

      compound.temp <- bind_cols(compound.temp, literature)

      # patent.identifiers <-  nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22patentid%22%5D,%22collection%22:%22patent%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]],"%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22patentsubmdate%22,%22patentgrantdate%22%5D%7D%5D")))

      # Biomolecular Pathways
      biosystems.pathways <- nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%7B%22download%22:%5B%22bsid%22%5D,%22collection%22:%22biosystem%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]],"%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D")))
      bio.path <- data.frame(`Biomolecular Interactions and Pathways` = biosystems.pathways,
                             `Biosystems and Pathways` = biosystems.pathways)

      compound.temp <- bind_cols(compound.temp, bio.path)
      #
      # bioassay.results <-    nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22activity%22%5D,%22collection%22:%22bioactivity%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]], "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22activity%22,%22acvalue%22,%22sid%22%5D%7D%5D")))

      # TODO Insert function to write completed table to database
      if (db.bypass == FALSE) {
        compound.text <- dplyr::select(compound.temp, contains(".text"))

        dbWriteTable(conn = db,
                     name = "pubchem_text",
                     value = compound.text,
                     row.names = FALSE,
                     append = TRUE
                    )
      }

      compound.temp <- dplyr::select(compound.temp, -contains(".text"))

      if (db.bypass == FALSE) {
        dbWriteTable(conn = db,
                     name = "pubchem_raw_counts",
                     value = compound.temp,
                     row.names = FALSE,
                     append = TRUE
        )
      }
    }

    master <- bind_rows(master, compound.temp)
  }

  return(master)
}
