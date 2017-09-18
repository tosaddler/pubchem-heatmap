library(shiny)
library(shinyHeatmaply)

shinyUI(fluidPage(

  titlePanel("PubChem Data Density Heatmap"),

  sidebarLayout(
    sidebarPanel(
      textAreaInput("chemid", "Input PubChem CIDs", value = "6618\n1983\n120228"),
      checkboxGroupInput("categories", "Select categories", c("Pharmacology and Biochemistry", "Use and Manufacturing", "Identification", "Safety and Hazards", "Toxicity", "PubMed Citations", "Patents", "Biosystems and Pathways", "BioAssay Results"),
                         selected = c("Pharmacology and Biochemistry", "Use and Manufacturing", "Identification", "Safety and Hazards", "Toxicity")),
      actionButton("update", "Update")
    ),

    mainPanel(
      plotlyOutput("heatmap")
    )
  )
))
