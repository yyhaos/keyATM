unloadNamespace("keyATM")
rm(list = ls())
library(dplyr)

# use release version
# install.packages("keyATM")
# library(keyATM)
# use source code
devtools::load_all("./")

library(quanteda)

data(data_corpus_inaugural, package = "quanteda")

data_corpus_inaugural <- head(data_corpus_inaugural, n = 58)

df <- data.frame(
    doc_id = docnames(data_corpus_inaugural),
    text = as.character(data_corpus_inaugural),
    docvars(data_corpus_inaugural), 
    stringsAsFactors = FALSE
)

write.csv(df, "inaugural_58.csv", row.names = FALSE)

vars <- docvars(data_corpus_inaugural)
head(vars)

data_tokens <- tokens(
    data_corpus_inaugural,
    remove_numbers = TRUE,
    remove_punct = TRUE,
    remove_symbols = TRUE,
    remove_separators = TRUE,
    remove_url = TRUE
) %>%
    tokens_tolower() %>%
    tokens_remove(
        c(
            stopwords("english"),
            "may", "shall", "can",
            "must", "upon", "with", "without"
        )
    ) %>%
    tokens_select(min_nchar = 3)

data_dfm <- dfm(data_tokens) %>%
    dfm_trim(min_termfreq = 5, min_docfreq = 2)
ncol(data_dfm) # the number of unique words

keyATM_docs <- keyATM_read(texts = data_dfm)

options <- {}
# options$iterations = 5
options$seed <- 122213
options$use_cache <- TRUE

out <- weightedLDA(
    docs              = keyATM_docs, # text input
    number_of_topics  = 5, # number of topics without keywords
    model             = "base", # select the model
    options           = list(seed = 250)
)

library(jsonlite)
write_json(out, "keyATM_out_4_r.json", pretty = TRUE, auto_unbox = TRUE)
topWords <- top_words(out)

writeLines(apply(topWords, 1, paste, collapse = "\t"), "keyATM_topWords_4_r.txt")
print(topWords)


# Run Base

# options <- {}
# # options$iterations = 5
# options$seed = 122213
# # options$use_cache <- FALSE
# out <- keyATM(
#     docs = keyATM_docs,
#     model = "dynamic", no_keyword_topics = 5, keywords = keywords, options = options
# )
# library(jsonlite)
# write_json(out, "keyATM_out_2_r.json", pretty = TRUE, auto_unbox = TRUE)
# topWords <- top_words(out)

# writeLines(apply(topWords, 1, paste, collapse = "\t"), "keyATM_topWords_2_r.txt")
print(topWords)

