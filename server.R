require(shiny)
require(heatmaply)
require(clusterSim)
library(pool)
library(odbc)

source("lib/pubchem_parse.R")
source("lib/clustering.R")
source("lib/select_sections.R")
source("lib/event_data.R")

db_config <- config::get("dbconnection")

db_pool <- dbPool(odbc::odbc(),
                  Driver      = db_config$driver,
                  Database    = db_config$database,
                  Server      = db_config$host,
                  UID         = db_config$uid,
                  PWD         = db_config$pass,
                  Port        = db_config$port,
                  minSize     = 10,
                  maxSize     = Inf,
                  idleTimeout = 3600)

onStop(function() {
  poolClose(db_pool)
})

shinyServer(function(input, output) {

  CompoundsParse <- eventReactive(input$update, {
    compounds <- unlist(str_split(input$chemid, "\n"))

    # Create a Progress object
    progress <- shiny::Progress$new()
    progress$set(message = "Parsing compounds\n", value = 0)
    #Close the progress when this reactive exits (even if there is an error)
    on.exit(progress$close())

    # Create a callback function to update progress.
    # Each time this is called:
    # - If `value` is NULL, it will move the progress bar 1/5 of the remaining
    #   distance. If non-NULL, it will set the progress to that value.
    # - It also accepts optional detail text.
    updateProgress <- function(value = NULL, detail = NULL) {
      if (is.null(value)) {
        value <- progress$getValue()
        value <- value + (progress$getMax() - value) / 5
      }
      progress$set(value = value, detail = detail)
    }

    df <- PubChemParse(chem.ids = compounds,
                       db.bypass = input$bypass,
                       db_con = db_pool,
                       updateProgress = updateProgress)
    return(df)
  })

  finalFrame <- reactive({
    df <- CompoundsParse()

    if (input$clustering == TRUE) {
      df.dend <- ClusterCompounds(df)
    }

    df <- SelectSections(df,
                         input$pharm_bio,
                         input$pharm_bio_sections,
                         input$use_manufacturing,
                         input$use_man_sections,
                         input$identification,
                         input$identification_sections,
                         input$safety,
                         input$safety_sections,
                         input$toxicity,
                         input$toxicity_sections,
                         input$literature,
                         input$literature_sections,
                         input$bio_path,
                         input$bio_path_sections)

    df <- FinalizeDF(df, input$chem.names, input$chem.names.length)

    if (input$normalization == "Only this data") {
      return(data.Normalization(df, type = "n8"))
    } else { # Database average normalization will go here
      return(df)
    }
  })

  observeEvent(input$dimension, {
    output$heatmap <-
      renderPlotly({
        if (input$clustering == TRUE) {
          heatmaply(finalFrame(),
                    dendrogram = "row",
                    RowV = df.dend,
                    row_dend_left = FALSE) %>%
            layout(height = "100%")
        } else {
          df <- finalFrame()
          heatmaply(df,
                    dendrogram = "none",
                    colors = Blues,
                    height = 0.9 * as.numeric(input$dimension[2]))  %>%
              layout(
                    yaxis = list(side = input$chem.names.side),
                    orientation = "h",
                    legend = list(x = -1.02)
                    )
        }
  })

  output$click <- renderPrint({
    d <- event_data("plotly_click", "A")
    if (is.null(d)) "Click events appear here (double-click to clear)" else d
  })

  output$clickValue <- renderPrint({
    d <- event_data("plotly_click", "A")
    if (is.null(d)) {
      "Individual clicked cell displayed here"
    } else {
      ClickValue(finalFrame(), d)
    }
  })

  output$zoom <- renderPrint({
    d <- event_data("plotly_relayout", "A")
    if (is.null(d)) "Relayout events (i.e., zoom) appear here" else d
  })

  output$download <- downloadHandler(
    filename = function() {
      paste0("pubchem_heatmap_table", ".csv")
    },
    content = function(file) {
      write.csv(finalFrame(), file)
    }
  )

})
})
