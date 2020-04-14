# pubchem-heatmap

This Shiny application is used to view data density of compounds on [PubChem](https://pubchem.ncbi.nlm.nih.gov). After inputting compound IDs (CIDs) and selecting which sections of content you would like to compare, this app will parse the information from PubChem and display a heatmap of data density for the selected compounds.

# Planned Features

- Cluster similar compounds with the dendrogram feature of heatmaply
- Wordclouds by selecting individual compounds and sections

# Installing database drivers
https://db.rstudio.com/best-practices/drivers/

# Creating PostgreSQL Docker Container for caching

```
docker run -d \
    --name pubchem-postgres \
    -e POSTGRES_PASSWORD=pubchem-heatmap \
    -e POSTGRES_USER=pubchem \
    -e POSTGRES_DB=postgres \
    -p 5432:5432 \
    postgres
```