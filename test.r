
# Cache: keyATM_fit.rds
unloadNamespace("keyATM")
rm(list = ls())
devtools::load_all("./")

library(quanteda)

data(keyATM_data_bills)
bills_keywords <- keyATM_data_bills$keywords

bills_dfm <- keyATM_data_bills$doc_dfm  # quanteda dfm object

dfm_mat <- convert(keyATM_data_bills$doc_dfm, to = "data.frame")
save(dfm_mat, file = "dfm_mat.rda")

keyATM_docs <- keyATM_read(bills_dfm)

# print(keyATM_docs)
# library(jsonlite)
# write_json(keyATM_docs, "keyATM_docs_r.json", pretty = TRUE, auto_unbox = TRUE)

# stop("1")
# keyATM Base
options = {}
# options$iterations = 5
options$seed = 12223
out <- keyATM(docs = keyATM_docs, model = "base", no_keyword_topics = 5, keywords = bills_keywords, options = options)
library(jsonlite)
write_json(out, "keyATM_out_r.json", pretty = TRUE, auto_unbox = TRUE)
topWords = top_words(out)

writeLines(apply(topWords, 1, paste, collapse = "\t"), "keyATM_topWords_r.txt")

print(topWords)

#      1_Education        2_Law     3_Health      4_Drug      Other_1
# 1  education [✓]      law [✓]   health [✓]    drug [✓]   management
# 2         school       action   public [✓]      person     wildlife
# 3    educational    court [✓]         care     control         land
# 4          local         code subparagraph information      project
# 5    student [✓]       person      purpose      report      coastal
# 6       eligible     district       follow application conservation
# 7          grant        crime    amendment   substance     national
# 8      child [✓]        civil          add       abuse         fish
# 9           high  enforcement      respect       grant       system
# 10      describe attorney [✓]      library      submit       refuge
#          Other_2     Other_3        Other_4     Other_5
# 1       facility        term       congress    research
# 2  administrator     require         report    national
# 3        network  commission          house      center
# 4       advisory        date representative    director
# 5          water    security           date  technology
# 6          study  electronic         senate    activity
# 7          party information        veteran development
# 8           work    congress         period       grant
# 9          level       issue      committee   establish
# 10      contract        mean         follow information

# run 10 minites
# > print(head(out))
# $keyword_k
# [1] 4

# $no_keyword_topics
# [1] 5

# $V
# [1] 3325

# $N
# [1] 140

# $model
# [1] "base"

# $theta
#         1_Education        2_Law   3_Health      4_Drug     Other_1
#   [1,] 0.2585175580 0.0001649052 0.13597108 0.048798030 0.058275276
#   [2,] 0.1482793646 0.0014539214 0.09657884 0.104159111 0.004010776
#   [3,] 0.0309955771 0.0079374225 0.03772216 0.083616398 0.089151231
#   [4,] 0.0437772867 0.0461342393 0.06535461 0.047194245 0.130565648
#   [5,] 0.5072251797 0.0002195786 0.08325292 0.012956207 0.054013465
#   [6,] 0.2795812923 0.0112487361 0.18509719 0.309271590 0.043970814
#   ...
#   [140,] 0.0263334919 0.0015770499 0.19442666 0.117961658 0.283320122
#             Other_2      Other_3      Other_4      Other_5
#   [1,] 0.0100460413 0.1846280143 1.849602e-01 0.1186388847
#   [2,] 0.2768721662 0.1306039846 4.938287e-03 0.2331035466
#   [3,] 0.0525380802 0.2996275705 3.698840e-02 0.3614231604
#   [4,] 0.0002222643 0.1527818543 2.979418e-01 0.2160280798
#   [5,] 0.0043598566 0.1737052239 4.213840e-03 0.1600537324
#   [6,] 0.0111684703 0.0767124597 1.961124e-04 0.0827533341
#   ...
#   [140,] 0.2206140776 0.0569772481 3.748949e-04 0.0984147926

# weightedLDA
# out2 <- weightedLDA(docs = keyATM_docs, model = "base", number_of_topics = 5)
print(top_topics(out))
# A tibble: 140 × 2
#    Rank1       Rank2
#    <chr>       <chr>
#  1 1_Education Other_2
#  2 Other_3     3_Health
#  3 Other_2     Other_3
#  4 Other_3     Other_2
#  5 1_Education Other_2
#  6 4_Drug      1_Education
#  7 3_Health    Other_2
#  8 Other_5     Other_3
#  9 Other_5     Other_1
# 10 Other_1     3_Health
# # ℹ 130 more rows
print(top_docs(out))
#    1_Education 2_Law 3_Health 4_Drug Other_1 Other_2 Other_3 Other_4 Other_5
# 1           46    90      104     55      10      61      91      50       9
# 2           60    86      136     12      15      66       2      40     120
# 3           45    81       99     27      77      97     105      47     117
# 4          125    24       37    137      19      92      20      88      33
# 5            5    85      133     87      32      93       4     130      23
# 6          131    56       21     48      75      14     138      41       8
# 7            1   115      111     73      39     113     112     108      43
# 8          103   101       11      6      65     122     121      52      51
# 9           96    30        7     88     139      22      34     134      58
# 10          38    89      128     26     126      70      28      29      22

print(plot_modelfit(out))