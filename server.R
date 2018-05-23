require(shiny)
require(shinyHeatmaply)
require(clusterSim)

source("lib/pubchem_parse.R")
source("lib/clustering.R")
source("lib/select_sections.R")
source("lib/event_data.R")

shinyServer(function(input, output) {

  CompoundsParse <- eventReactive(input$update, {
    compounds <- unlist(str_split(input$chemid, "\n"))
    df <- PubChemParse(chem.ids = compounds, db.bypass = input$bypass)
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

    df <- FinalizeDF(df, input$chem.names)

    if (input$normalization == "Only this data") {
      return(df <- data.Normalization(df, type = "n8"))
    } else { # Database average normalization will go here
      return(df)
    }
  })

  output$heatmap <-
    renderPlotly({

      if (input$clustering == TRUE) {
        heatmaply(finalFrame(),
                  dendrogram = "row",
                  RowV = df.dend,
                  row_dend_left = FALSE,
                  # margins = c(200, 200, NA, 0),
                  colors = Blues)
      } else {
        heatmaply(finalFrame(),
                  dendrogram = FALSE,
                  # margins = c(200, 200, NA, 0),
                  colors = Blues)
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

})
# colors = cool_warm
