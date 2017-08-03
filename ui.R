library(shiny)
library(shinyHeatmaply)

shinyUI(fluidPage(

  titlePanel("PubChem Data Density Heatmap"),

  sidebarLayout(
    sidebarPanel(
      textAreaInput("chemid", "Input PubChem CIDs", value = "6618\n1983\n120228"),
      checkboxGroupInput("categories", "Select categories", c("Pharmacology and Biochemistry", "Use and Manufacturing", "Identification", "Safety and Hazards", "Toxicity"),
                         selected = c("Pharmacology and Biochemistry", "Use and Manufacturing", "Identification", "Safety and Hazards", "Toxicity"))
    ),

    mainPanel(
      plotlyOutput("heatmap")
    )
  )
))
