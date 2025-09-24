unloadNamespace("keyATM")
rm(list = ls())
# use release version
install.packages("keyATM")
library(keyATM)
# use source code
# devtools::load_all("./") 

library(quanteda)
library(magrittr)
data(data_corpus_inaugural, package = "quanteda")
data_corpus_inaugural <- head(data_corpus_inaugural, n = 58)

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
summary(keyATM_docs)

dfm_mat <- convert(data_dfm, to = "data.frame")
save(dfm_mat, file = "dfm_mat_2.rda")

keywords <- list(
    Government     = c("laws", "law", "executive"),
    Congress       = c("congress", "party"),
    Peace          = c("peace", "world", "freedom"),
    Constitution   = c("constitution", "rights"),
    ForeignAffairs = c("foreign", "war")
)
# Run HMM

options <- {}
# options$iterations = 5
options$seed = 122213
# options$use_cache <- FALSE
out <- keyATM(
    docs = keyATM_docs,
    model = "dynamic", no_keyword_topics = 5, keywords = keywords, options = options
)
library(jsonlite)
write_json(out, "keyATM_out_2_r.json", pretty = TRUE, auto_unbox = TRUE)
topWords <- top_words(out)

writeLines(apply(topWords, 1, paste, collapse = "\t"), "keyATM_topWords_2_r.txt")



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
