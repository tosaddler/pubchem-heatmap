require(tidyverse)
require(jsonlite)
require(stringr)
require(data.tree)
library(dbplyr)
require(clusterSim)
require(data.table)
require(RPostgres)
require(RCurl)
require(config)
library(pool)
library(DBI)


source("lib/pubchem_sections.R", local = TRUE)
source("lib/postgresql_rename.R", local = TRUE)
source("lib/postgresql_initialize.R", local = TRUE)

options(stringsAsFactors = FALSE)

`%notin%` <- Negate(`%in%`)

CollapseTextVector <- function(vec) {
  vec <- paste(vec, sep = " ", collapse = " ")
  vec <- str_replace_all(vec, "\\<.*?\\>", "")
  return(vec)
}

ScrapeSection <- function(section.node, subsection.heading) {
  subsection <- tryCatch({
    temp <- Clone(section.node$Climb(TOCHeading = subsection.heading)$Information)
    temp$Get("String", filterFun = function(x) {x$level == 5})
  }, error = function(err) {
    print(paste("ScrapeSection: subsection", subsection.heading, "does not exist for compound"))
    return("")
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
    main.df <- dplyr::bind_cols(main.df, temp.df)
  }
  return(main.df)
}

PubChemURL <- function(chem_id) {
  chem_url <- paste0("https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/",
                         chem_id,
                         "/JSON")
}

PubChemJSON <- function(chem_url) {
  chem_json <- read_json(chem_url)
}

PubChemTree <- function(chem_json) {
  chem_tree <- FromListSimple(chem_json)
}

PubChemScrape <- function(compound.tree) {
  pubchem.sections <- PubChemSections()

  chem.id <- compound.tree$Record$RecordNumber

  compound.name <- compound.tree$Record$RecordTitle

  # Simplifying to the section we need, other section contains references
  compound.tree <- compound.tree$Record$Section

  # Initialize temporary data frame to pull info from each section
  compound.temp <- data.frame(compound.id = as.character(chem.id),
                              name.info   = compound.name)

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
  pubmed.citations <- jsonlite::fromJSON(getURL(paste0('https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={"select":"*","collection":"pubmed","where":{"ands":[{"cid":"', chem.id, '"},{"pmidsrcs":"xref"}]},"order":["articlepubdate,desc"],"start":1,"limit":1,"width":1000000,"listids":0}')))
  pubmed.citations <- pubmed.citations$SDQOutputSet$totalCount

  nature.ref <- jsonlite::fromJSON(getURL(paste0('https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={"select":"*","collection":"springernature","where":{"ands":[{"cid":"', chem.id, '"}]},"order":["scorefloat,desc"],"start":1,"limit":1,"width":1000000,"listids":0}')))
  nature.ref <- nature.ref$SDQOutputSet$totalCount

  metabolite.ref <- jsonlite::fromJSON(getURL(paste0('https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={"select":"*","collection":"hmdb","where":{"ands":[{"cid":"', chem.id,'"}]},"order":["relevancescore,desc"],"start":1,"limit":1,"width":1000000,"listids":0}')))
  metabolite.ref <- metabolite.ref$SDQOutputSet$totalCount

  lit.total <- sum(pubmed.citations, metabolite.ref, nature.ref)

  compound.temp <- data.frame(compound.temp,
                              `Literature` = lit.total,
                              `PubMed Citations` = pubmed.citations,
                              `Metabolite References` = metabolite.ref,
                              `Springer Nature References` = nature.ref,
                              check.names = FALSE)

  # Biomolecular Pathways
  biosystems.pathways <- jsonlite::fromJSON(getURL(paste0('https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={"select":"*","collection":"pathway","where":{"ands":[{"cid":"', chem.id, '"},{"core":"1"}]},"order":["source,asc"],"start":1,"limit":1}')))
  biosystems.pathways <- biosystems.pathways$SDQOutputSet$totalCount
  compound.temp <- data.frame(compound.temp,
                              `Biomolecular Interactions and Pathways` = biosystems.pathways,
                              `Biosystems and Pathways` = biosystems.pathways,
                              check.names = FALSE)

  compound.text <- dplyr::select(compound.temp, `compound.id`, contains(".text"))

  compound.count <- dplyr::select(compound.temp, -contains(".text"))

  return(list("compound_counts" = compound.count,
              "compound_text" = compound.text))
}

PubChemParse <- function(chem.ids,
                         db.bypass = FALSE,
                         db_con = NULL,
                         updateProgress = NULL) {

  master_df <- data_frame()

  if (!db.bypass) {
    if(!dbExistsTable(db_con, "pubchem_counts")) {
      InitializePostgresTable(db_con, "pubchem_counts")
    }
    if(!dbExistsTable(db_con, "pubchem_text")) {
      InitializePostgresTable(db_con, "pubchem_text")
    }
    tryCatch({
      sql_get_compounds <- "SELECT * FROM pubchem_counts WHERE compound_id IN (?chems)"

      query <- sqlInterpolate(db_con, sql_get_compounds, chems = SQL(toString(chem.ids)))

      db_compounds <- dbGetQuery(db_con, query)

      db_compounds <- DBToDFCounts(db_compounds)

      db_compounds$compound.id <- as.character(db_compounds$compound.id)

      master_df <- db_compounds

      chem.ids <- chem.ids[chem.ids %notin% as.character(db_compounds$compound.id)]
    },
    error = function(err) {
      db_con <<- NULL
      db.bypass <<- TRUE
      print(paste("db.bypass is", as.character(db.bypass)))
    })
  } else {
    db_con <- NULL
  }
  print(paste("db.bypass is", as.character(db.bypass)))

  new_compound_counts <- data_frame()
  new_compound_text <- data.frame()
  if (length(chem.ids) > 0) {
    for (i in 1:length(chem.ids)) {
      if (is.function(updateProgress)) {
        updateProgress(value = (i / length(chem.ids)),
                       detail = paste("Compound", i, "of", length(chem.ids)))
      }
      compound_url <- PubChemURL(chem.ids[[i]])
      compound_json <- PubChemJSON(compound_url)
      compound_tree <- PubChemTree(compound_json)
      compound.temp <- PubChemScrape(compound_tree)

      if (!db.bypass) {
        tryCatch({dbWriteTable(conn = db_con,
                     name = "pubchem_counts",
                     value = DFCountsToDB(compound.temp$compound_counts),
                     append = TRUE)})
        tryCatch({dbWriteTable(conn = db_con,
                     name = "pubchem_text",
                     value = DFRawToDB(compound.temp$compound_text),
                     append = TRUE)})
      }



      if (nrow(new_compound_counts) < 1) {
        new_compound_counts <- compound.temp$compound_counts
      } else {
        new_compound_counts <- bind_rows(new_compound_counts,
                                       compound.temp$compound_counts)
      }

      if (nrow(new_compound_text) < 1) {
        new_compound_text <- compound.temp$compound_text
      } else {
        new_compound_text <- bind_rows(new_compound_text,
                                       compound.temp$compound_text)
      }

    }
  }



  master_df <- if(nrow(master_df) < 1) {
    master_df <- new_compound_counts
  } else {
    master_df <- bind_rows(master_df, new_compound_counts)
  }

  return(master_df)
}
