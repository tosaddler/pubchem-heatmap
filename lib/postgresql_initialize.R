InitializePostgresTable <- function(db, table_name) {
  if (table_name == "pubchem_counts") {
    dbGetQuery(db,
                  "CREATE TABLE pubchem_counts
                (
                  compound_id int NOT NULL,
                  name_info text,
                  pharmacology_and_biochemistry integer,
                  pharmacology integer,
                  absoprption_distribution_excretion integer,
                  metabolism_metabolites integer,
                  biological_half_life integer,
                  mechanism_of_action integer,
                  use_and_manufacturing integer,
                  methods_of_manufacturing integer,
                  consumption integer,
                  identification integer,
                  analytic_lab_methods integer,
                  clinical_lab_methods integer,
                  safety_hazards integer,
                  hazards_identification integer,
                  safety_hazards_prop integer,
                  first_aid_measures integer,
                  fire_fighting_measures integer,
                  accidental_release_measures integer,
                  handling_storage integer,
                  exposure_control_and_pp integer,
                  stability_reactivity integer,
                  transport_info integer,
                  regulatory_info integer,
                  toxicity integer,
                  tox_info integer,
                  eco_info integer,
                  literature integer,
                  pubmed_citations integer,
                  metabolite_references integer,
                  nature_references integer,
                  bio_interactions_pathways integer,
                  biosystems_pathways integer
                );

                ALTER TABLE pubchem_counts ADD CONSTRAINT compound_id
                PRIMARY KEY (compound_id);")
  } else if (table_name == "pubchem_text") {
      dbGetQuery(db, "CREATE TABLE pubchem_text
                  (
                    compound_id INT REFERENCES pubchem_counts(compound_id),
                    pharmacology_text TEXT,
                    absorption_distribution_excretion_text TEXT,
                    metabolism_metabolites_text TEXT,
                    biological_half_life_text TEXT,
                    mechanism_of_action_text TEXT,
                    methods_of_manufacturing_text TEXT,
                    consumption_text TEXT,
                    analytic_lab_methods_text TEXT,
                    clinical_lab_methods_text TEXT,
                    hazards_identification_text TEXT,
                    safety_hazards_prop_text TEXT,
                    first_aid_measures_text TEXT,
                    fire_fighting_measures_text TEXT,
                    accidental_release_measures_text TEXT,
                    handling_storage_text TEXT,
                    exposure_control_and_pp_text TEXT,
                    stability_reactivity_text TEXT,
                    transport_info_text TEXT,
                    regulatory_info_text TEXT,
                    tox_info_text TEXT,
                    eco_info_text TEXT
                  );")
    }
  }
