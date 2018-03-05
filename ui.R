library(shiny)
library(shinyHeatmaply)

# https://shiny.rstudio.com/articles/dynamic-ui.html
# This page describes how to dynamically update UI elements

shinyUI(
  fluidPage(

    titlePanel("PubChem Data Density Heatmap"),

    sidebarLayout(
      sidebarPanel(
        tabsetPanel(
          tabPanel("Input and Categories",
            HTML("<br>"),
            textAreaInput(      inputId  =   "chemid",
                                label    =   "Input PubChem CIDs",
                                value    =   "6618\n1983\n120228"),

            actionButton(       inputId  =   "update",
                                label    =   "Update"),

            HTML("<br><br>"),

            checkboxGroupInput( inputId  =   "categories",
                                label    =   "Select categories",
                                choices  = c("Pharmacology and Biochemistry",
                                             "Use and Manufacturing",
                                             "Identification",
                                             "Safety and Hazards",
                                             "Toxicity",
                                             "PubMed Citations",
                                             "Patents",
                                             "Biosystems and Pathways",
                                             "BioAssay Results"),
                                selected = c("Pharmacology and Biochemistry",
                                             "Use and Manufacturing",
                                             "Identification",
                                             "Safety and Hazards",
                                             "Toxicity"))
          ),

          tabPanel("Options",
             HTML("<br>"),
             radioButtons(       inputId  =   "normalization",
                                 label    =   "Normalization:",
                                 choices  = c("Only this data",
                                              "Database averages")),

             checkboxInput(      inputId  =   "clustering",
                                 label    =   "Cluster compounds",
                                 value    =   TRUE),

             checkboxInput(      inputId  =   "bypass",
                                 label    =   "Bypass database",
                                 value    =   TRUE)

          )
        )
      ),

      mainPanel(
        plotlyOutput("heatmap")
      )
    )
  )
)
