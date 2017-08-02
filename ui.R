library(shiny)
library(shinyHeatmaply)

shinyUI(fluidPage(

  titlePanel("PubChem Data Density Heatmap"),

  sidebarLayout(
    sidebarPanel(
      textAreaInput("chemid", "Input PubChem CIDs")
    ),

    mainPanel(
      plotlyOutput("heatmap")
    )
  )
))
