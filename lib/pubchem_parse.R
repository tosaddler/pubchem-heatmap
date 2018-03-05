require(tidyverse)
require(jsonlite)
require(stringr)
require(data.tree)
require(clusterSim)
require(data.table)

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

CreateSectionsList <- function() {
  sections <- list( `Pharmacology and Biochemistry` =
                        c("Pharmacology",
                          "Absorption, Distribution and Excretion",
                          "Metabolism/Metabolites",
                          "Biological Half-Life",
                          "Mechanism of Action"),
                    `Use and Manufacturing` =
                        c("Methods of Manufacturing",
                          "Consumption"),
                    `Identification` =
                        c("Analytic Laboratory Methods",
                          "Clinical Laboratory Methods")
                   )
  return(sections)
}

DbSafeNames = function(names) {
    names = gsub('[^a-z0-9]+','_',tolower(names))
    names = make.names(names, unique=TRUE, allow_=TRUE)
    names = gsub('.','_',names, fixed=TRUE)
    names
}



PubChemParse <- function(chem.ids, db, db.bypass = FALSE) {

  master <- data.frame()

  pubchem.sections <- CreateSectionsList()

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

      # Pulling CACTVS String for clustering
      chem.phys.prop <- compound.tree$Climb(TOCHeading = "Chemical and Physical Properties")$Section
      computed.prop <- chem.phys.prop$Climb(TOCHeading = "Computed Properties")$Information$`1`$Table$Row
      cactvs <- computed.prop$Get(attribute = "BinaryValue")
      cactvs <- cactvs[!is.na(cactvs)]
      names(cactvs) <- "cactvs.info"

      # Initialize temporary data frame to pull info from each section
      compound.temp <- data.frame(compound.id = as.numeric(chem.ids[[i]]), cactvs.info = cactvs)

      for (j in 1:length(pubchem.sections)) {

        # section.node <- compound.tree$Climb(TOCHeading = names(pubchem.sections)[[j]])$Section

        section.node <- tryCatch({
          compound.tree$Climb(TOCHeading = names(pubchem.sections)[[j]])$Section
        }, error = function(err) {
          print(paste('Error: Section', pubchem.sections[[j]], 'does not exist for compound', chem.ids[[i]]))
          Node$new("blankNode")
        })

        for (k in 1:length(pubchem.sections[[j]])) {
          temp.section <- ScrapeSection(section.node, pubchem.sections[[j]][[k]])
          compound.temp <- bind_cols(compound.temp, temp.section)
        }
      }



      # Literature Sections
      # pubmed.citations <-    nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22pmid%22%5D,%22collection%22:%22pubmed%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]], "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22articlepubdate%22%5D%7D%5D")))
      # metabolite.references <- nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%7B%22download%22:%5B%22cid%22,%22pmid%22,%22reference%22%5D,%22collection%22:%22hmdb%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]], "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D")))
      # patent.identifiers <-  nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22patentid%22%5D,%22collection%22:%22patent%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]],"%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22patentsubmdate%22,%22patentgrantdate%22%5D%7D%5D")))
      # biosystems.pathways <- nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%7B%22download%22:%5B%22bsid%22%5D,%22collection%22:%22biosystem%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]],"%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D")))
      # bioassay.results <-    nrow(fread(paste0("https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=jsonp&query=%5B%7B%22download%22:%5B%22activity%22%5D,%22collection%22:%22bioactivity%22,%22where%22:%7B%22ands%22:%5B%7B%22cid%22:%22", chem.ids[[i]], "%22%7D%5D%7D,%22order%22:%5B%22relevancescore,desc%22%5D,%22start%22:1,%22limit%22:1000000%7D,%7B%22histogram%22:%5B%22activity%22,%22acvalue%22,%22sid%22%5D%7D%5D")))

      # TODO Insert function to write completed table to database

      compound.text <- select(compound.temp, contains(".text"))

      dbWriteTable(conn = db,
                   name = "pubchem_text",
                   value = compound.text,
                   row.names = FALSE,
                   append = TRUE
                  )

      compound.temp <- select(compound.temp, !contains(".text"))
    }

    master <- bind_rows(master, compound.temp)
  }

  # master.text <- master %>%
  #                   select(contains(".text"))
  # master <-
  #
  # master <- data.Normalization(master, type = "n8")

  # row.names(master) <- chem.ids

  return(master)
}
