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

# vars
library(dplyr)
vars %>%
    as_tibble() %>%
    mutate(Period = case_when(
        Year <= 1899 ~ "18_19c",
        TRUE ~ "20_21c"
    )) %>%
    mutate(Party = case_when(
        Party == "Democratic" ~ "Democratic",
        Party == "Republican" ~ "Republican",
        TRUE ~ "Other"
    )) %>%
    select(Party, Period) -> vars_selected
print(table(vars_selected))

vars_selected %>%
    mutate(
        Party = factor(Party,
            levels = c("Other", "Republican", "Democratic")
        ),
        Period = factor(Period,
            levels = c("18_19c", "20_21c")
        )
    ) -> vars_selected
print(head(model.matrix(~ Party + Period, data = vars_selected)))

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

keywords <- list(
    Government     = c("laws", "law", "executive"),
    Congress       = c("congress", "party"),
    Peace          = c("peace", "world", "freedom"),
    Constitution   = c("constitution", "rights"),
    ForeignAffairs = c("foreign", "war")
)
options <- {}
# options$iterations = 5
options$seed <- 122213
options$use_cache <- TRUE

out <- keyATM(
    docs = keyATM_docs,
    no_keyword_topics = 5,
    keywords = keywords,
    model = "covariates",
    model_settings = list(
        covariates_data = vars_selected,
        covariates_formula = ~ Party + Period
    ),
    options = options
)

library(jsonlite)
write_json(out, "keyATM_out_3_r.json", pretty = TRUE, auto_unbox = TRUE)
topWords <- top_words(out)

writeLines(apply(topWords, 1, paste, collapse = "\t"), "keyATM_topWords_3_r.txt")
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

