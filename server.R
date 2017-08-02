library(shiny)
library(shinyHeatmaply)

source("lib/pubchem.parse.R")

shinyServer(function(input, output) {
    
    compounds.parse <- reactive({
        compounds <- unlist(str_split(input$chemid, "\n"))
        df <- pubchem.parse(vec_chemid = compounds)
        df
    })
    
    output$heatmap <- renderPlotly({
        df <- compounds.parse()
        heatmaply(df, dendrogram = FALSE, margins = c(200, 200, NA, 0), colors = cool_warm)
    })
    
})
