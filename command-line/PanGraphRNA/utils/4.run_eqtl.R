#!/usr/bin/env Rscript
args <- commandArgs(T)

workdir <- args[1]
var_genotype <- args[2]
var_loc <- args[3]
var_covariates <- args[4]
gene_expression_matrix <- args[5]
gene_loc <- args[6]
FDR_threshold <- args[7]

setwd(workdir)
# Matrix eQTL by Andrey A. Shabalin
# http://www.bios.unc.edu/research/genomic_software/Matrix_eQTL/
# 
# Be sure to use an up to date version of R and Matrix eQTL.

# source("Matrix_eQTL_R/Matrix_eQTL_engine.r");
library(MatrixEQTL)

## Location of the package with the data files.

## Settings

# Linear model to use, modelANOVA, modelLINEAR, or modelLINEAR_CROSS
useModel = modelLINEAR; # modelANOVA, modelLINEAR, or modelLINEAR_CROSS

# Genotype file name
SNP_file_name = var_genotype;
snps_location_file_name = var_loc;


# Gene expression file name
expression_file_name = gene_expression_matrix;
gene_location_file_name= gene_loc;

# Covariates file name
# Set to character() for no covariates
covariates_file_name = var_covariates;#character() 

# Output file name
output_file_name_cis = tempfile();
output_file_name_tra = tempfile();
# Only associations significant at this level will be saved
pvOutputThreshold_cis = 2e-2;
pvOutputThreshold_tra = 2e-2;

# Error covariance matrix
# Set to numeric() for identity.
errorCovariance = numeric();
# errorCovariance = read.table("Sample_Data/errorCovariance.txt");

# Distance for local gene-SNP pairs
cisDist = 1e5;
## Load genotype data
snps = SlicedData$new();
snps$fileDelimiter = "\t";      # the TAB character
snps$fileOmitCharacters = "NA"; # denote missing values;
snps$fileSkipRows = 1;          # one row of column labels
snps$fileSkipColumns = 1;       # one column of row labels
snps$fileSliceSize = 2000;      # read file in slices of 2,000 rows
snps$LoadFile(SNP_file_name);

## Load gene expression data

gene = SlicedData$new();
gene$fileDelimiter = "\t";      # the TAB character
gene$fileOmitCharacters = "NA"; # denote missing values;
gene$fileSkipRows = 1;          # one row of column labels
gene$fileSkipColumns = 1;       # one column of row labels
gene$fileSliceSize = 2000;      # read file in slices of 2,000 rows
gene$LoadFile(expression_file_name);

## Load covariates

cvrt = SlicedData$new();
cvrt$fileDelimiter = "\t";      # the TAB character
cvrt$fileOmitCharacters = "NA"; # denote missing values;
cvrt$fileSkipRows = 1;          # one row of column labels
cvrt$fileSkipColumns = 1;       # one column of row labels
if(length(covariates_file_name)>0) {
  cvrt$LoadFile(covariates_file_name);
}
## Run the analysis
snpspos = read.table(snps_location_file_name, header = TRUE, stringsAsFactors = FALSE);
genepos = read.table(gene_location_file_name, header = TRUE, stringsAsFactors = FALSE);

start_time <- Sys.time() 

me = Matrix_eQTL_main(
  snps = snps, 
  gene = gene, 
  cvrt = cvrt,
  output_file_name      = output_file_name_tra,
  pvOutputThreshold     = pvOutputThreshold_tra,
  useModel = useModel, 
  errorCovariance = errorCovariance, 
  verbose = TRUE, 
  output_file_name.cis  = output_file_name_cis,
  pvOutputThreshold.cis = pvOutputThreshold_cis,
  snpspos = snpspos, 
  genepos = genepos,
  cisDist = cisDist,
  pvalue.hist = TRUE,
  min.pv.by.genesnp = FALSE,
  noFDRsaveMemory = FALSE);
unlink(output_file_name_tra);
unlink(output_file_name_cis);
end_time <- Sys.time() 
## Results:
cat('Analysis done in: ', me$time.in.sec, ' seconds', '\n');
cat('Detected local eQTLs:', '\n');
# show(me$cis$eqtls)
cat('Detected distant eQTLs:', '\n');
# show(me$trans$eqtls)
## Make the histogram of local and distant p-values
me$cis$eqtls <- me$cis$eqtls[which(me$cis$eqtls$FDR < FDR_threshold),]
me$trans$eqtls <- me$trans$eqtls[which(me$trans$eqtls$FDR < FDR_threshold),]
save(me,file = "eqtl_res.RData")
write.table(me$cis$eqtls,"cis_eqtl_res_matrix.txt",sep = "\t",quote = F,row.names = F)
write.table(me$trans$eqtls,"trans_eqtl_res_matrix.txt",sep = "\t",quote = F,row.names = F)



