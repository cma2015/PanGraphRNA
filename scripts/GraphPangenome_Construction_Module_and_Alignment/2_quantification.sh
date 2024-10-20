#!/bin/bash
dir=$1
fileone=$2
thread=$3
gtffile=$4

/home/galaxy/miniconda3/envs/bio/bin/samtools sort -@ $thread $fileone > ${dir}/${fileone##*/}_sorted.bam
/home/galaxy/miniconda3/envs/bio/bin/stringtie -e -p $thread -A ${dir}/gene_exp/${fileone##*/}_gene.gtf -G $gtffile -o ${dir}/trans_exp/${fileone##*/}_trans.gtf ${dir}/${fileone##*/}_sorted.bam