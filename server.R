require(shiny)
require(shinyHeatmaply)
require(clusterSim)

source("lib/pubchem_parse.R")
source("lib/clustering.R")

shinyServer(function(input, output) {

  CompoundsParse <- eventReactive(input$update, {
    compounds <- unlist(str_split(input$chemid, "\n"))
    df <- PubChemParse(chem.ids = compounds, NULL, db.bypass = input$bypass)
    return(df)
  })

  output$heatmap <-
    renderPlotly({
      df <- CompoundsParse()

      if (input$clustering == TRUE) {
        df.dend <- ClusterCompounds(df)
      }

      df <- FinalizeDF(df, input$chem.names)

      if (input$normalization == "Only this data") {
        df <- data.Normalization(df, type = "n8")
      } else { # Database average normalization will go here
        df <- df
      }

      if (input$clustering == TRUE) {
        heatmaply(df,
                  dendrogram = "row",
                  RowV = df.dend,
                  row_dend_left = FALSE,
                  # margins = c(200, 200, NA, 0),
                  colors = Blues)
      } else {
        heatmaply(df,
                  dendrogram = FALSE,
                  # margins = c(200, 200, NA, 0),
                  colors = Blues)
      }

    })
})
# colors = cool_warm
