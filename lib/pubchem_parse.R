require(tidyverse)
require(jsonlite)
require(stringr)
require(data.tree)
require(clusterSim)
require(data.table)
require(RPostgres)
require(data.table)
require(RCurl)
require(config)

source("lib/pubchem_sections.R", local = TRUE)
source("lib/postgresql_rename.R", local = TRUE)
source("lib/postgresql_initialize.R", local = TRUE)

options(stringsAsFactors = FALSE)

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
                         "/JSON/?response_type=save")
}

PubChemJSON <- function(chem_url) {
  chem_json <- read_json(chem_url)
}

PubChemTree <- function(chem_json) {
  chem_tree <- FromListSimple(chem_json)
}

PubChemScrape <- function(compound.tree, db, db.bypass = FALSE) {
  pubchem.sections <- PubChemSections()

  chem.id <- compound.tree$Record$RecordNumber

  compound.name <- compound.tree$Record$RecordTitle

  # Simplifying to the section we need, other section contains references
  compound.tree <- compound.tree$Record$Section

  # Initialize temporary data frame to pull info from each section
  compound.temp <- data.frame(compound.id = as.numeric(chem.id),
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

  compound.temp <- dplyr::select(compound.temp, -contains(".text"))

  if (!db.bypass) {
    compound.db <- DFCountsToDB(compound.temp)
    dbWriteTable(conn = db,
                 name = "pubchem_counts",
                 value = compound.db,
                 row.names = FALSE,
                 append = TRUE
    )
  }

  if (!db.bypass) {
    compound.text <- DFRawToDB(compound.text)
    dbWriteTable(conn = db,
                 name = "pubchem_text",
                 value = compound.text,
                 row.names = FALSE,
                 append = TRUE
    )
  }

  return(compound.temp)
}

PubChemParse <- function(chem.ids, db.bypass = FALSE, updateProgress = NULL) {
  if (!db.bypass) {
    cf <- config::get("dbconnection")
    tryCatch({db <- dbConnect(drv = dbDriver(cf$driver),
                    dbname   = cf$database,
                    host     = cf$server,
                    port     = cf$port,
                    user     = cf$uid,
                    password = cf$pwd)
    if(!dbExistsTable(db, "pubchem_counts")) {
      InitializePostgresTable(db, "pubchem_counts")
    }},
    error = function(err) {
      db <<- NULL
      db.bypass <<- TRUE
      print(paste("db.bypass is", as.character(db.bypass)))
    })
  } else {
    db <- NULL
  }
  print(paste("db.bypass is", as.character(db.bypass)))
  master <- data.frame()

  for (i in 1:length(chem.ids)) {
    if (is.function(updateProgress)) {
      updateProgress(value = (i / length(chem.ids)),
                     detail = paste("Compound", i, "of", length(chem.ids)))
    }

    if (!db.bypass) {
      if (as.logical(dbGetQuery(db, paste("SELECT EXISTS(SELECT 1 FROM pubchem_counts WHERE compound_id =", chem.ids[[i]], ');')))) {
            compound.temp <- dbGetQuery(db, paste('SELECT * FROM pubchem_counts',
                                            'WHERE compound_id = ', chem.ids[[i]], ';'))
            compound.temp <- DBToDFCounts(compound.temp)
      } else {
        compound_url <- PubChemURL(chem.ids[[i]])
        compound_json <- PubChemJSON(compound_url)
        compound_tree <- PubChemTree(compound_json)
        compound.temp <- PubChemScrape(compound_tree, db, db.bypass)
      }

    } else {
      compound_url <- PubChemURL(chem.ids[[i]])
      compound_json <- PubChemJSON(compound_url)
      compound_tree <- PubChemTree(compound_json)
      compound.temp <- PubChemScrape(compound_tree, db, db.bypass)
    }
    master <- bind_rows(master, compound.temp)
  }

  if (!db.bypass) {
    dbDisconnect(db)
  }
  return(master)
}
