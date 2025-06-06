#!/usr/bin/env Rscript
args <- commandArgs(T)

workdir <- args[1]
tmpinfo <- args[2]
graph_name <- args[3]



setwd(workdir)
datainfor  <- read.table(paste0(tmpinfo),stringsAsFactors = F)[,1:2]
colnames(datainfor) <- c("sampleID","genome")
rownames(datainfor) <- datainfor$sampleID
sampleID <- datainfor$sampleID
genome_set <- c(basename(graph_name))
stats_mat <- data.frame(matrix(0,nrow=length(genome_set),ncol=10))
rownames(stats_mat) <- genome_set
colnames(stats_mat) <- c("sampleID","genome","readsum","multi_to_unique","multi_to_unmap",
                         "unique_to_multi","unique_to_unmap",
                         "unmap_to_multi","unmap_to_unique","diff_unique")
ss <- ""
all_stats <- NULL

for( ss in sampleID){
  cat(ss,"\n")
  ll <- datainfor[ss,"genome"]
  map_selfmat <- data.table::fread(paste0(ss,"_",datainfor[ss,"genome"],"_alignment_mapped.txt"),
                                   header = F)
  one_stats <- stats_mat
  one_stats$sampleID <- ss
  one_stats[,2] <- genome_set
  one_stats[,3] <- nrow(map_selfmat)
  ###### error rate calculate
  gg <- ""
  for( gg in genome_set ){
    gg1 <- gg #ifelse(grepl("graph",gg),paste0("graph_",ll),gg)
    map_graphmat <- data.table::fread(paste0(ss,"_",gg1,"_alignment_mapped.txt"),
                                      header = F)
    colnames(map_selfmat) <- colnames(map_graphmat) <- c("readID","type")
    merge_mat <- merge(map_selfmat,map_graphmat,by="readID")
    merge_mat <- merge_mat[merge_mat$type.x != merge_mat$type.y,]
    merge_mat <- split(merge_mat$readID,paste0(merge_mat$type.x,"_to_",merge_mat$type.y))
    merge_mat <- sapply(merge_mat,length)
    one_stats[gg,names(merge_mat)] <- merge_mat

  }
  rm(map_selfmat,map_graphmat)
  ########## diff unique
  map_selfbed <- data.table::fread(paste0(ss,"_",
                                          datainfor[ss,"genome"],"_alignment_uniq_sort.lift.bed"),
                                   header = F)
  map_selfbed$mid <- (map_selfbed[,2] + map_selfbed[,3])/2
  for(gg in genome_set){
    gg1 <- gg #ifelse(grepl("graph",gg),paste0("graph_",ll),gg)
    map_graphbed <- data.table::fread(paste0(ss,"_",gg1,"_alignment_uniq_sort.bed"),
                                      header = F)
    map_graphbed$mid <- (map_graphbed[,2] + map_graphbed[,3])/2

    merge_bed <- merge(map_selfbed[,c(4,7)],map_graphbed[,c(4,7)],by="V4")
    merge_bed$diff <- abs(merge_bed$mid.y - merge_bed$mid.x)

    one_stats[gg,"diff_unique"] <- length(which(merge_bed$diff > 1))
  }

  all_stats <- rbind(all_stats,one_stats)
  rm(map_selfbed,merge_bed,map_graphbed)
  gc()
}

write.csv(all_stats,file = "compare_readtype_amongGenomes.csv",row.names = F )
