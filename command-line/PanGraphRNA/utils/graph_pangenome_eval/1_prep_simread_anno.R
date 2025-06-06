args <- commandArgs(T)

workdir <- args[1]
exon_anno <- args[2]
accession_name <- args[3]
vcffile <- args[4]


setwd(workdir)
library(GenomicFeatures)
library(dplyr)

# filter gene -------------------------------------------------------------
library(dplyr)
gtfobj <- rtracklayer::import(exon_anno,format = "GTF")
gtfobj$len_ex <- width(gtfobj)

bed_to_grange <- function(bedMat,strand_if = F,base0=F){
  bedMat <- data.frame(bedMat,stringsAsFactors = F)
  bedMat[,2] <- as.numeric(bedMat[,2])
  bedMat[,3] <- as.numeric(bedMat[,3])
  if(base0){
    bedMat[,2] <- bedMat[,2]+1
  }
  if(strand_if){
    tmp_gr <- GRanges(seqnames =  Rle(bedMat[,1]), ranges = IRanges(start = bedMat[,2],width =bedMat[,3] - bedMat[,2]+1),
                      strand = Rle(bedMat[,4]))
    bedMat <- bedMat[,-4]
  }else{
    tmp_gr <- GRanges(seqnames =  Rle(bedMat[,1]), ranges = IRanges(start = bedMat[,2],width =bedMat[,3] - bedMat[,2]+1),
                      strand = Rle(strand(rep("*",nrow(bedMat)))))
  }
  
  if(ncol(bedMat) > 3){
    mcols(tmp_gr) <- bedMat[,4:ncol(bedMat)]
    colnames(mcols(tmp_gr)) <- colnames(bedMat)[4:ncol(bedMat)]
  }
  
  tmp_gr
}


for(vv in c(accession_name)){
  varobj <- read.delim(paste0(vcffile),
                       header = F,check.names = T,
                       comment.char="#")
  varobj$len <- abs(nchar(as.vector(varobj$V5)) - nchar(as.vector(varobj$V4)))
  varobj <- bed_to_grange(varobj[,c(1,2,2,3,11)])
  varobj$len[varobj$len == 0] <- varobj$len[varobj$len == 0] + 1
  overlap <- findOverlaps(gtfobj,varobj)

  overmat_trans  <- data.frame(transcript_id=gtfobj$transcript_id[queryHits(overlap)],
                               len=varobj$len[subjectHits(overlap)],stringsAsFactors = F)
  overmat_trans <- overmat_trans %>% group_by(transcript_id) %>%
    summarise(num=n(),lenvar=sum(len))
  overmat_trans <- overmat_trans[overmat_trans$lenvar > 1,]
  onegtf_obj <- gtfobj[gtfobj$transcript_id %in% overmat_trans$transcript_id,]
  rtracklayer::export(onegtf_obj,
                      paste0("exon_",vv,".gtf"),format = "GTF")
}