#!/bin/bash

num=$1
dir=$2
exon_gtf=$3
accession_name=$4
readnum=$5

mkdir -p ${dir}/simreads/paramfile
mkdir -p ${dir}/simreads/paramfile/bedfile
mkdir -p ${dir}/simreads/paramfile/profile
mkdir -p ${dir}/simreads/paramfile/parfile
mkdir -p ${dir}/simreads/fastasim
mkdir -p ${dir}/simreads/genome/${accession_name}

mv ${dir}/${accession_name}.fa ${dir}/simreads/genome/${accession_name}
/home/galaxy/miniconda3/envs/bio/bin/python /galaxy/server/tools/graph_pangenome_eval/0_fa_chr_split.py ${dir}/simreads/genome/${accession_name}/${accession_name}.fa ${dir}/simreads/genome/${accession_name}
for((i=1;i<=$1;i++))
do
    echo -e "${accession_name}\t${i}" >> ${dir}/simlist
    cat >> ${dir}/simreads/paramfile/${accession_name}_rep${i}_${readnum}.par <<EOF
REF_FILE_NAME   ${exon_gtf}
GEN_DIR         ${dir}/simreads/genome/${accession_name}


# create a fastq file
FASTA           YES
## Expression
NB_MOLECULES    2000000
TSS_MEAN        50
POLYA_SCALE     200
POLYA_SHAPE     1.5

## Fragmentation
FRAG_SUBSTRATE  DNA
FRAG_METHOD     NB
FRAG_NB_LAMBDA  600
FRAG_NB_M       5

# Reverse Transcription
RTRANSCRIPTION  YES
RT_MOTIF        default
RT_PRIMER RH
RT_LOSSLESS YES
RT_MIN 400
RT_MAX 5000

## PCR / Filtering
PCR_DISTRIBUTION  default
GC_MEAN NaN
FILTERING NO

# Sequencing
READ_NUMBER     ${readnum}
READ_LENGTH     100
PAIRED_END      NO
UNIQUE_IDS      YES

EOF
done

        