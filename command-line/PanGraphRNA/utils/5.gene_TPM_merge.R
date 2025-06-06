#!/usr/bin/env Rscript
args <- commandArgs(T)

workdir <- args[1]

setwd(workdir)

library(dplyr)

# 设置原始 GTF 文件夹路径
file_dir <- "gene_exp"

# 列出文件夹中的 GTF 文件
gtf_files <- list.files(file_dir, full.names = TRUE)

# 针对每个 GTF 文件进行处理
for (gtf_file in gtf_files) {
  # 读取 GTF 文件
  gtf_data <- read.delim(gtf_file, header = TRUE, stringsAsFactors = FALSE)
  
  # 去除基因 ID 中的前缀 "gene:"
  gtf_data$Gene.ID <- sub("gene:", "", gtf_data$Gene.ID)
  
  # 按照基因 ID 分组，并对 TPM 值进行求和
  merged_data <- gtf_data %>%
    group_by(Gene.ID) %>%
    summarise(TPM = sum(TPM, na.rm = TRUE)) %>%
    ungroup()
  
  # 输出处理后的结果为 .merged.mat 文件
  output_file <- sub(".gtf", ".merged.mat", gtf_file)
  write.table(merged_data, file = output_file, sep = "\t", quote = FALSE, row.names = FALSE)
}


file_dir <- "gene_exp"
expfile <- "geneTPM_merged.txt"

gtf_files <- list.files(file_dir) 
gtf_files <- gtf_files[grep("merged.mat",gtf_files)]
sample_id <- sub("_tr.*gz","",gtf_files)
gtf_files <- file.path(file_dir,gtf_files)
onegtf <- read.delim(gtf_files[1],header = T,stringsAsFactors = F)
onegtf$Gene.ID <- sub("gene:","",onegtf$Gene.ID)
gene_idall <- unique(onegtf$Gene.ID)
expmat <- sapply(gtf_files,function(ff){
  # cat(ff,"\t")
  onegtf <- read.delim(ff,header = T,stringsAsFactors = F)
  onegtf$Gene.ID <- sub("gene:","",onegtf$Gene.ID)
  onegtf <- onegtf[order(onegtf$Gene.ID,onegtf$TPM,decreasing = T),]
  onegtf <- onegtf[!duplicated(onegtf$Gene.ID),]
  rownames(onegtf) <- onegtf$Gene.ID
  onegtf[gene_idall,"TPM"]
})
dimnames(expmat) <- list(gene_idall,sample_id)
write.table(expmat,file =expfile,sep = "\t",quote = F )
