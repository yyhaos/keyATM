library(keyATM)
library(quanteda)
library(jsonlite)

data(keyATM_data_bills)
bills_keywords <- keyATM_data_bills$keywords
bills_dfm <- keyATM_data_bills$doc_dfm
keyATM_docs <- keyATM_read(bills_dfm)

for (i in 1:5) {
  out <- keyATM(
    docs = keyATM_docs,
    model = "base",
    no_keyword_topics = 5,
    keywords = bills_keywords
  )

  theta <- out$theta
  write_json(theta, paste0("theta_", i, ".json"), pretty = TRUE, auto_unbox = TRUE)

  topWords = top_words(out)

  writeLines(apply(topWords, 1, paste, collapse = "\t"), paste0("keyATM_topWords_r_", i, ".txt"))
}
