library(keyATM)
library(quanteda)
library(jsonlite)

data(keyATM_data_bills)
bills_keywords <- keyATM_data_bills$keywords
bills_dfm <- keyATM_data_bills$doc_dfm
keyATM_docs <- keyATM_read(bills_dfm)

for (i in 1:1) {
  out <- keyATM(
    docs = keyATM_docs,
    model = "base",
    no_keyword_topics = 5,
    keywords = bills_keywords
  )

  theta <- out$theta
  write_json(theta, paste0("theta_", i, ".json"), pretty = TRUE, auto_unbox = TRUE)

  plot_topicprop(out, show_topic = 1:5)

  print(plot_topicprop(out, show_topic = 1:5))
}
