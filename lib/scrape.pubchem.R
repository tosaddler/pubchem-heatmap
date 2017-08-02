options(stringsAsFactors = FALSE)

scrape.pubchem <- function(cid){
  
  ## change Phantom.js scrape file
  website <- paste0("https://www.pubchem.ncbi.nlm.nih.gov/compound/", cid)
  lines <- readLines("lib/scrape_final.js")
  lines[7] <- paste0("page.open('", website, "', function (status) {")
  writeLines(lines, "scrape_final.js")
    
  system("lib/phantomjs lib/scrape_final.js")
}