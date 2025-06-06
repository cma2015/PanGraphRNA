#!/usr/bin/env Rscript
args <- commandArgs(T)


library(stringr)
type_seq <- c("deletion","insertion", "single")
names(type_seq) <- c("DEL","INS","SNP")
## rm duplicate id in haplotype
gg <- args[1]
workdir <- args[2] 
vcf_prefix <- args[3]
setwd(workdir)
add_snpinfor <- read.table(paste0(gg,".snp"),header = F,stringsAsFactors = F)
colnames(add_snpinfor)<- c("varID","type","chr","pos","alt")
add_snpinfor$newID <- paste0(add_snpinfor$chr,"_",add_snpinfor$pos+1)
haplotype_mat <- read.table(paste0(gg,".haplotype"),stringsAsFactors = F)
haplotype_mat$varnum  <- str_count(haplotype_mat$V5,vcf_prefix)
haplotype_mat$hID <- paste(haplotype_mat$V2,haplotype_mat$V3,haplotype_mat$V4,sep=".")
haplotype_mat <- haplotype_mat[order(haplotype_mat$hID,haplotype_mat$varnum),]
haplotype_mat <- haplotype_mat[which(haplotype_mat$varnum > 1 ),]
haplotype_mat <- haplotype_mat[!duplicated(haplotype_mat$hID,fromLast=T),]
haplotype_mat <- haplotype_mat[order(haplotype_mat$V2,haplotype_mat$V3,haplotype_mat$V4),]
# range_hap <- haplotype_mat$V4 -haplotype_mat$V3 +1
dupID <- add_snpinfor$varID[duplicated(add_snpinfor$newID,fromLast=T)]
htID <- haplotype_mat$V5
# for(ii in dupID){
#   htID <- gsub(paste0(ii,","),"",htID)
# }
dupID <- str_c( paste0(dupID,","), collapse="|")
htID <- str_replace_all(htID, dupID, ",")
haplotype_mat$V5 <- htID
varnum <- str_count(haplotype_mat$V5,vcf_prefix)
haplotype_mat <- haplotype_mat[which(varnum > 1),]
haplotype_mat <- haplotype_mat[str_order(haplotype_mat$hID,numeric =T),]
haplotype_mat$V1 <- paste0("ht",1:nrow(haplotype_mat))
write.table(haplotype_mat[,1:5],
            paste0(gg,".rmdup.haplotype"),row.names = F,
                                       col.names = F,quote = F,    sep = "\t")
