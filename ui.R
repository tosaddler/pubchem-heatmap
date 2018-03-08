library(shiny)
library(shinyHeatmaply)

# https://shiny.rstudio.com/articles/dynamic-ui.html
# This page describes how to dynamically update UI elements

shinyUI(
  navbarPage("pubchem-heatmap",
    tabPanel("Heatmap",
      fluidPage(
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

                checkboxInput(      inputId  =   "pharm_bio",
                                    label    =   "Pharmacology and Biochemistry",
                                    value    =   TRUE),

                conditionalPanel(  condition =  "input.pharm_bio == true",
                  checkboxGroupInput(inputId =   "pharm_bio_sections",
                                     label   =   NULL,
                                     choices = c("Pharmacology",
                                                 "Absorption, Distribution and Excretion",
                                                 "Metabolism/Metabolites",
                                                 "Biological Half-Life",
                                                 "Mechanism of Action"))
                ),

                checkboxInput(      inputId  =   "use_manufacturing",
                                    label    =   "Use and Manufacturing",
                                    value    =   TRUE),

                conditionalPanel(    condition = "input.use_manufacturing == true",
                  checkboxGroupInput(inputId   =   "use_man_sections",
                                     label   = NULL,
                                     choices = c("Methods of Manufacturing",
                                                 "Consumption"))
                ),

                checkboxInput(      inputId  =   "identification",
                                    label    =   "Identification",
                                    value    =   TRUE),

                conditionalPanel(   condition = "input.identification == true",
                  checkboxGroupInput(inputId =   "identification_sections",
                                     label   = NULL,
                                    choices = c("Analytic Laboratory Methods",
                                                "Clinical Laboratory Methods"))
                ),

                checkboxInput(      inputId  =   "safety",
                                    label    =   "Safety and Hazards",
                                    value    =   TRUE),

                conditionalPanel(   condition = "input.safety == true",
                  checkboxGroupInput(inputId =   "safety_sections",
                                     label   = NULL,
                                     choices = c("Hazards Identification",
                                                 "Safety and Hazard Properties",
                                                 "First Aid Measures",
                                                 "Accidental Release Measures",
                                                 "Handling and Storage",
                                                 "Exposure Control and Personal Protection",
                                                 "Stability and Reactivity",
                                                 "Regulatory Information"))
                ),

                checkboxInput(      inputId  =   "toxicity",
                                    label    =   "Toxicity",
                                    value    =   TRUE),

                conditionalPanel(   condition = "input.toxicity == true",
                  checkboxGroupInput(inputId =   "toxicity_sections",
                                    label   = NULL,
                                     choices = c("Toxicological Information",
                                                 "Ecological Information"))
                ),

                checkboxInput(      inputId  =   "literature",
                                    label    =   "Literature",
                                    value    =   TRUE),

                conditionalPanel(   condition = "input.literature == true",
                  checkboxGroupInput(inputId =   "literature_sections",
                                     label   = NULL,
                                     choices = c("PubMed Citations",
                                                 "Metabolite References",
                                                 "Springer Nature References"))
                ),

                checkboxInput(      inputId  =   "bio_path",
                                    label    =   "Biomolecular Interactions and Pathways",
                                    value    =   TRUE),

                conditionalPanel(   condition = "input.bio_path == true",
                  checkboxGroupInput( inputId =   "bio_path_sections",
                                      label   = NULL,
                                      choices = c("Biosystems and Pathways"))
                )

              ),

              tabPanel("Options",
                 HTML("<br>"),
                 radioButtons(       inputId  =   "normalization",
                                     label    =   "Normalization:",
                                     choices  = c("Only this data",
                                                  "Database averages")),

                 checkboxInput(      inputId  =   "clustering",
                                     label    =   "Cluster compounds",
                                     value    =   FALSE),

                 checkboxInput(      inputId  =   "bypass",
                                     label    =   "Bypass database",
                                     value    =   TRUE),

                 checkboxInput(      inputId  =   "chem.names",
                                     label    =   "Use compound names",
                                     value    =   TRUE)

              )
            )
          ),

          mainPanel(
            plotlyOutput("heatmap")
          )
        )
      )
    ),

    tabPanel("Wordcloud",
      fluidPage(
        sidebarLayout(
          sidebarPanel(

          ),

          mainPanel(

          )
        )
      )
    )
  )
)
