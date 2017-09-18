library(shiny)
library(shinyHeatmaply)

source("lib/pubchem.parse.R")

shinyServer(function(input, output) {
    
    compounds.parse <- eventReactive(input$update, {
        compounds <- unlist(str_split(input$chemid, "\n"))
        df <- pubchem.parse(vec_chemid = compounds, vec_index = input$categories)
        df
    })
    
    output$heatmap <- 
        renderPlotly({
            df <- compounds.parse()
            heatmaply(df, dendrogram = FALSE, margins = c(200, 200, NA, 0), colors = Blues)
        })
})
# colors = cool_warm