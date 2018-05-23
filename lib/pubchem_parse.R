require(tidyverse)
require(jsonlite)
require(stringr)
require(data.tree)
require(clusterSim)
require(data.table)
require(RPostgreSQL)
require(data.table)
require(RCurl)
require(config)

source("lib/pubchem_sections.R", local = TRUE)
source("lib/postgresql_rename.R", local = TRUE)

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

PubChemScrape <- function(chem.id, db, db.bypass = FALSE) {

  pubchem.sections <- PubChemSections()

  # Import JSON for compound
  compound.url <- paste0("https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/",
                         chem.id,
                         "/JSON/?response_type=save$response_basename=CID_",
                         chem.id)

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
  compound.temp <- data.frame(compound.id = as.numeric(chem.id),
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
  pubmed.citations <- jsonlite::fromJSON(getURL(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={%22select%22:[%22pmid%22,%22articlepubdate%22,%22articletitle%22,%22articlejourname%22],%22collection%22:%22pubmed%22,%22where%22:{%22ands%22:[{%22cid%22:%22", chem.id, "%22}]},%22order%22:[%22articlepubdate,desc%22],%22start%22:1,%22limit%22:1}")))
  pubmed.citations <- pubmed.citations$SDQOutputSet$totalCount

  nature.ref <- jsonlite::fromJSON(getURL(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query=%7b%22select%22:%5b%22pmid%22%5d,%22collection%22:%22springernature%22,%22where%22:%7b%22ands%22:%5b%7b%22cid%22:%22", chem.id, "%22%7d%5d%7d,%22order%22:%5b%22scorefloat,desc%22%5d,%22start%22:1,%22limit%22:10%7d")))
  nature.ref <- nature.ref$SDQOutputSet$totalCount

  metabolite.ref <- jsonlite::fromJSON(getURL(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={%22select%22:[%22articletitle%22,%22articlejourname%22,%22articlepubdate%22,%22pmid%22,%22url%22,%22openaccess%22],%22collection%22:%22springernature%22,%22where%22:{%22ands%22:[{%22cid%22:%22", chem.id, "%22}]},%22order%22:[%22scorefloat,desc%22],%22start%22:1,%22limit%22:5}")))
  metabolite.ref <- metabolite.ref$SDQOutputSet$totalCount

  lit.total <- sum(pubmed.citations, metabolite.ref, nature.ref)

  compound.temp <- data.frame(compound.temp,
                              `Literature` = lit.total,
                              `PubMed Citations` = pubmed.citations,
                              `Metabolite References` = metabolite.ref,
                              `Springer Nature References` = nature.ref,
                              check.names = FALSE)

  # Biomolecular Pathways
  biosystems.pathways <- jsonlite::fromJSON(getURL(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={%22select%22:[%22bsid%22,%22bsname%22],%22collection%22:%22biosystem%22,%22where%22:{%22ands%22:[{%22cid%22:%22", chem.id, "%22}]},%22order%22:[%22relevancescore,desc%22],%22start%22:1,%22limit%22:5}")))
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

PubChemParse <- function(chem.ids, db.bypass = FALSE) {
  if (!db.bypass) {
    cf <- config::get("dbconnection")
    db <- dbConnect(drv      = dbDriver(cf$driver),
                    dbname   = cf$database,
                    host     = cf$server,
                    port     = cf$port,
                    user     = cf$uid,
                    password = cf$pwd)
  } else {
    db <- NULL
  }

  master <- data.frame()

  for (i in 1:length(chem.ids)) {

    if (!db.bypass) {
      if (as.logical(dbGetQuery(db, paste("SELECT EXISTS(SELECT 1 FROM pubchem_counts WHERE compound_id =", chem.ids[[i]], ');')))) {
            compound.temp <- dbGetQuery(db, paste('SELECT * FROM pubchem_counts',
                                            'WHERE compound_id = ', chem.ids[[i]], ';'))
            compound.temp <- DBToDFCounts(compound.temp)
      } else {
        compound.temp <- PubChemScrape(chem.ids[[i]], db, db.bypass)
      }

    } else {
      compound.temp <- PubChemScrape(chem.ids[[i]], db, db.bypass)
    }

    master <- bind_rows(master, compound.temp)
  }

  if (!db.bypass) {
    dbDisconnect(db)
  }
  return(master)
}
