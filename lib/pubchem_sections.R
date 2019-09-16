PubChemSections <- function() {
  sections <- list( `Pharmacology and Biochemistry` =
                      c("Pharmacology",
                        "Absorption, Distribution and Excretion",
                        "Metabolism/Metabolites",
                        "Biological Half-Life",
                        "Mechanism of Action"),
                    `Use and Manufacturing` =
                      c("Methods of Manufacturing",
                        "Consumption"),
                    `Identification` =
                      c("Analytic Laboratory Methods",
                        "Clinical Laboratory Methods"),
                    `Safety and Hazards` =
                      list(`Hazards Identification` =
                             c("GHS Classification",
                               "Health Hazard",
                               "Fire Hazard",
                               "Explosion Hazard",
                               "Fire Potential",
                               "Skin, Eye, and Respiratory Irritations"),
                           `Safety and Hazard Properties` =
                             c("Flammability",
                               "Physical Dangers",
                               "Chemical Dangers",
                               "OSHA Standards",
                               "NIOSH Recommendations"),
                           `First Aid Measures` =
                             c("First Aid",
                               "Inhalation First Aid",
                               "Skin First Aid",
                               "Eye First Aid",
                               "Ingestion First Aid"),
                           `Fire Fighting Measures` =
                             c("Fire Fighting"),
                           `Accidental Release Measures` =
                             c("Isolation and Evacuation",
                               "Spillage Disposal",
                               "Disposal Methods",
                               "Other Preventative Measures"),
                           `Handling and Storage` =
                             c("Nonfire Spill Response",
                               "Safe Storage",
                               "Storage Conditions"),
                           `Exposure Control and Personal Protection` =
                             c("REL",
                               "PEL",
                               "REL-TWA",
                               "IDLH",
                               "Threshold Limit Values",
                               "Inhalation Risk",
                               "Effects of Short Term Exposure",
                               "Effects of Long Term Exposure",
                               "Personal Protection",
                               "Respirator Recommendations",
                               "Fire Prevention",
                               "Explosion Prevention",
                               "Exposure Prevention",
                               "Inhalation Prevention",
                               "Skin Prevention",
                               "Eye Prevention",
                               "Ingestion Prevention",
                               "Protective Equipment and Clothing"),
                           `Stability and Reactivity` =
                             c("Air and Water Reactions",
                               "Reactive Group",
                               "Reactivity Profile",
                               "Reactivities and Incompatabilities"),
                           `Transport Information` =
                             c("DOT Label",
                               "Emergency Response"),
                           `Regulatory Information` =
                             c("DOT Emergency Response Guide")),
                    `Toxicity` =
                      list(`Toxicological Information` =
                             c("Heptatoxicity",
                               "Exposure Routes",
                               "Symptoms",
                               "Inhalation Symptoms",
                               "Skin Symptoms",
                               "Eye Symptoms",
                               "Ingestion Symptoms",
                               "Target Organs",
                               "Interactions",
                               "Toxicity Summary",
                               "Antidote and Emergency Treatment",
                               "Human Toxicity Excerpts",
                               "Non-Human Toxicity Excerpts",
                               "Human Toxicity Values",
                               "Non-Human Toxicity Values",
                               "Ecotoxicity Values",
                               "Populations at Special Risk",
                               "Protein Binding"),
                           `Ecological Information` =
                             c("Environmental Fate/Exposure Summary",
                               "Artificial Sources",
                               "Environmental Fate",
                               "Biodegredation",
                               "Abiotic Degredation",
                               "Bioconcentration",
                               "Soil Adsorption/Mobility",
                               "Volatilization from Water/Soil",
                               "Water Concentrations",
                               "Effluents Concentrations",
                               "Milk Concentrations",
                               "Probable Routes of Human Exposure",
                               "Body Burdens"))
  )
  return(sections)
}
