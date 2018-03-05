library(shiny)
library(shinyHeatmaply)

source("lib/pubchem_parse.R")
source("lib/clustering.R")

shinyServer(function(input, output) {

    CompoundsParse <- eventReactive(input$update, {
        compounds <- unlist(str_split(input$chemid, "\n"))
        df <- PubChemParse(chem.ids = compounds, NULL, db.bypass = input$bypass)
        if (input$clustering == TRUE) {
          df <- PubChemCluster(df)
        } else {
          df <- FinalizeDF(df)
        }
        return(df)
    })

    output$heatmap <-
        renderPlotly({
            df <- CompoundsParse()
            heatmaply(df, dendrogram = FALSE, margins = c(200, 200, NA, 0), colors = Blues)
        })
})
# colors = cool_warm
