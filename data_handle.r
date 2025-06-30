library(quanteda)
data(keyATM_data_bills)

# 提取 keywords，保存为简单 list
keywords <- keyATM_data_bills$keywords
print(keywords)
save(keywords, file = "keywords.rda")

# 提取 dfm -> 转为 matrix -> data.frame
dfm_mat <- convert(keyATM_data_bills$doc_dfm, to = "data.frame")
save(dfm_mat, file = "dfm_mat.rda")

# 或者导出为 csv，供 Python 使用
write.csv(dfm_mat, file = "dfm_mat.csv", row.names = FALSE)
