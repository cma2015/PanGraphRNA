#!/usr/bin/env Rscript
args <- commandArgs(T)

workdir <- args[1]
graph_file <- args[2]
readnum <- args[3]

library(dplyr)
setwd(workdir)
denovo_sample <- read.table("simlist",stringsAsFactors = F)
colnames(denovo_sample) <- c("accession","rep")

graph_name <- basename(graph_file)
junction_eval_denovo <- NULL
#1:nrow(denovo_sample)
for(ii in c(1:nrow(denovo_sample))){
  ss <- paste0(denovo_sample$accession[ii],"_rep",denovo_sample$rep[ii])
  print(paste0(ss,readnum) )

  correct_bed <- data.table::fread(paste0("simreads/paramfile/bedfile/",ss,"_",readnum,".bed.gz"),
                                   stringsAsFactors = F)[,c(1:4,6,11)]
  colnames(correct_bed) <- c("chr","start","end","readID","strand","junC")
  
  for(gg in graph_name ){
    

    newmap_bed <- data.table::fread(paste0(ss,"_",readnum,".fasta_",gg,"_alignment_uniq_sort.bed"),
                                      stringsAsFactors = F)[,c(1:4,6,7)]
      
    
    colnames(newmap_bed) <- c("chr","start","end","readID","strand","junC")
    correct_bed$junC[grep(",",correct_bed$junC)] <- "P"
    correct_bed$junC <- ifelse(correct_bed$junC == "P","P","N")
    newmap_bed$junC[grep("N",newmap_bed$junC)] <- "P"
    newmap_bed$junC <- ifelse(newmap_bed$junC == "P","P","N")
    merge_map <- merge(newmap_bed,correct_bed,by="readID")
    # same_chr <- which(merge_map$chr.x == merge_map$chr.y & merge_map)
    merge_map <- merge_map %>% mutate(diffm=abs(end.y + start.y - end.x -start.x)/2,
                                      maptype=paste0(junC.y,junC.x),
                                      difftype=ifelse(diffm >0.5,1,0)    ) 
    # aa <- merge_map %>% filter(chr.x==chr.y & strand.x == strand.y &diffs != diffe & diffm == 0)
    merge_map$maptype <- factor(merge_map$maptype,levels = c("NN","NP","PN","PP"),
                                labels = c("TN","FP","FN","TP"))
    
    count_diff <- table(merge_map[merge_map$difftype == 0,]$maptype)
    names(count_diff) <- paste0(names(count_diff),".diff0")
    junction_eval_denovo <- rbind(junction_eval_denovo,
                                  c(sampleID=ss,
                                    genome=gg,
                                    allnum=nrow(correct_bed),
                                    uniqnum=nrow(newmap_bed),
                                    diff0=length(which(merge_map$diffm <= 0.5)),
                                    orinum=length(which(correct_bed$junC == "P")),
                                    mapnum=length(which(newmap_bed$junC == "P")),
                                    table(merge_map$maptype),
                                    count_diff
                                  )
    )
  }  
  write.csv(junction_eval_denovo,file = "evalue_graphgenome_simreads.csv",quote = F,row.names = F)
  
}

uniqmap_eval <- read.csv("evalue_graphgenome_simreads.csv",stringsAsFactors = F)
uniqmap_eval <- data.frame(uniqmap_eval,stringsAsFactors = F)
uniqmap_eval[,3:ncol(uniqmap_eval)] <- apply(uniqmap_eval[,3:ncol(uniqmap_eval)],2,as.numeric)
uniqmap_eval$recall <- round(uniqmap_eval$diff0/uniqmap_eval$allnum * 100,2 )
uniqmap_eval$precision <- round(uniqmap_eval$diff0/uniqmap_eval$uniqnum * 100,2 ) 
uniqmap_eval$uniqrate <- round(uniqmap_eval$uniqnum/uniqmap_eval$allnum *100,2)

uniqmap_eval$F1score <- 2*uniqmap_eval$recall*uniqmap_eval$precision/(uniqmap_eval$recall+uniqmap_eval$precision)

write.csv(uniqmap_eval,file = "evalue_graphgenome_F1score.csv",quote = F,row.names = F)
