#!/usr/bin/env Rscript
args <- commandArgs(T)

input_reads_count_file <- args[1]
CG_num <- args[2]
EG_num <- args[3]
output1 <- args[4]
output2 <- args[5]
output3 <- args[6]

# 加载DESeq2工具
library(DESeq2)

# 读入原始计数矩阵数据
readcount_matrix <- as.matrix(read.csv(input_reads_count_file,row.names="gene_id"))
# 查看部分数据
head(readcount_matrix)

# 过滤不表达或低表达基因（如若有tpm表达矩阵文件，可设置表达值阈值获得表达基因ID列表，根据此列表过滤不表达或低表达基因）
readcount_matrix <- readcount_matrix[rowMeans(readcount_matrix)>1,]

# 设置分组信息，此处表示三个对照组（CG：control group）和三个实验组（EG：experimental group），与原始矩阵列信息相对应，每一行对应一个样本
condition <- factor(c(rep("DS",CG_num),rep("WW",EG_num)))
condition <- relevel(condition, ref = "WW")
group_info <- data.frame(row.names=colnames(readcount_matrix), condition)



# 创建DESeqDataSet矩阵
DEA_data <- DESeqDataSetFromMatrix(countData = readcount_matrix, colData = group_info, design = ~ condition)
# 查看矩阵信息
head(DEA_data)

# 标准化处理
DEA_norm <- DESeq(DEA_data)

# 查看结果
DEA_result <- results(DEA_norm)
summary(DEA_result)

# 格式转化
DEA_result_matrix <- data.frame(DEA_result, stringsAsFactors = FALSE, check.names = FALSE)
# 基于p值log2FoldChange值进行排序
DEA_result_matrix <- DEA_result_matrix[order(DEA_result_matrix$pvalue, DEA_result_matrix$log2FoldChange, decreasing = c(FALSE, TRUE)), ]

# 根据实验需求基于p值（pvalue）或q值（padj）阈值，log2FoldChange阈值鉴定差异表达基因
DEG_up <- DEA_result_matrix[which(DEA_result_matrix$log2FoldChange >= 1 & DEA_result_matrix$pvalue < 0.05),]      # 表达量显著上升的基因
DEG_down <- DEA_result_matrix[which(DEA_result_matrix$log2FoldChange <= -1 & DEA_result_matrix$pvalue < 0.05),]    # 表达量显著下降的基因
DEG_total <- rbind(DEG_up,DEG_down)

# 输出差异表达基因信息
# write.csv(DEG_total,"N76382_Sha_Asia_readcount_gene_stringtie.csv_DEG_total.csv")
# write.csv(DEG_up,"N76382_Sha_Asia_readcount_gene_stringtie.csv_DEG_up.csv")
# write.csv(DEG_down,"N76382_Sha_Asia_readcount_gene_stringtie.csv_DEG_down.csv")

write.csv(DEG_total,output1)
write.csv(DEG_up,output2)
write.csv(DEG_down,output3)