Generate.WordcloudDF <- function(df) {
  temp <- paste(text.temp, collapse = " ")

  temp_corpus <- Corpus(VectorSource(temp))

  toSpace <- content_transformer(function (x, pattern) gsub(pattern, " ", x))

  temp_corpus <- tm_map(temp_corpus, content_transformer(tolower))
  temp_corpus <- tm_map(temp_corpus, removeNumbers)
  temp_corpus <- tm_map(temp_corpus, removeWords, stopwords("english"))
  temp_corpus <- tm_map(temp_corpus, removePunctuation)
  temp_corpus <- tm_map(temp_corpus, stripWhitespace)

  temp_corpus <- tm_map(temp_corpus, removeWords, c("approximately", "administered", "authors", "days", "dose", "fate", "following", "found", "group", "highest", "hours", "levels", "nature", "present", "respectively", "samples", "similar", "via"))

  dtm <- TermDocumentMatrix(temp_corpus)
  m <- as.matrix(dtm)
  v <- sort(rowSums(m), decreasing = TRUE)
  d <- data.frame(word = names(v), freq=v)
}

