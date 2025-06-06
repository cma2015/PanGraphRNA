#!/bin/bash

hisat2_path="/home/galaxy/miniconda3/envs/bio/bin/hisat2"
samtools_path="/home/galaxy/miniconda3/envs/bio/bin/samtools"
bedtools_path="/home/galaxy/miniconda3/envs/bio/bin/bedtools"
ref_genome="No_input"
vcf_file="No_input"
threads=20
output_dir=""
accession_name="No_input"
min_intron_length=20
max_intron_length=500000
mismatch="9,3"
unique="yes"
index_type="individual"
index_path="No_input"

while getopts "R:v:t:o:a:i:x:m:U:T:h" arg
do
        case $arg in
        R)
            ref_genome=$OPTARG
                ;;
        v) 
            vcf_file=$OPTARG
                ;;
        t)  
            threads=$OPTARG
                ;;
        o)  
            output_dir=$OPTARG
                ;;
        a)  
            accession_name=$OPTARG
                ;;
        i)  
            min_intron_length=$OPTARG
                ;;
        x)  
            max_intron_length=$OPTARG
                ;;
        m)  
            mismatch=$OPTARG
                ;;
        U)  
            unique=$OPTARG
                ;;
        T)  
            index_type=$OPTARG
                ;;
        h)  
            echo "    "
            echo "==========================================================================="
            echo "    "
            echo "Hisat2 alignment v1.0 usage:"
            echo "    "
            echo "** Required **"
            echo "    "
            echo "-R <string>: reference genome."
            echo "    "
            echo "-v <string>: vcf file."
            echo "    "
            echo "-o <string>: output directory."
            echo "    "
            echo "---------------------------------------------------------------------------"
            echo "    "
            echo "** Options **"
            echo "    "
            echo "-t <int>: number of threads, default: 20."
            echo "    "
            echo "-a <string>: accession name, default: No_input."
            echo "    "
            echo "-i <int>: minimum intron length, default: 20."
            echo "    "
            echo "-x <int>: maximum intron length, default: 500000."
            echo "    "
            echo "-m <string>: mismatch, default: 9,3."
            echo "    "
            echo "-U <string>: unique reads, default: yes."
            echo "    "
            echo "-T <string>: index type, default: individual.{"individual","population", "subpopulation"}"
            echo "-h: "
            echo "==========================================================================="
            exit 1
                ;;
        esac
done



if [ $ref_genome == "No_input" ] || [ $vcf_file == "No_input" ] || [ $output_dir == "" ]; then
    echo "Please provide the required arguments."
    exit 1
fi
if [ $index_type == "individual" ]; then
    index_path=${ref_genome%.*}_${vcf_file##*/}_${accession_name}
elif [ $index_type == "population" ]; then
    index_path=${ref_genome%.*}_${vcf_file##*/}
elif [ $index_type == "subpopulation" ]; then
    index_path=${ref_genome%.*}_${vcf_file##*/}_${accession_name##*/}
else
    echo "Please provide the correct index type."
    exit 1
fi

for file in ${output_dir}/simreads/fastasim/*  ;do
    $hisat2_path -p $threads -x $index_path -f $file --min-intronlen $min_intron_length --max-intronlen $max_intron_length --mp $mismatch  --summary-file ${output_dir}/$(basename "$file")_${ref_genome##*/}_summary.txt -S ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment.sam

    $samtools_path view -H ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment.sam > ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq.sam &&
    grep -w "NH:i:1" ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment.sam >> ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq.sam &&
    $samtools_path view -@ $threads -bS ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq.sam > ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq.bam &&
    rm ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq.sam &&
    $samtools_path sort -@ $threads ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq.bam -o ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq_sort.bam &&
    rm ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq.bam &&

    $bedtools_path bamtobed -i ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq_sort.bam -cigar > ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq_sort.bed &&
    $bedtools_path bamtobed -i ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq_sort.bam | cut -f 4 | awk 'BEGIN{OFS="\t"}{print $1,"unique"}' - > ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_mapped.txt &&
    $samtools_path view -F 0x4 ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment.sam | grep -w -v "NH:i:1" | cut -f 1 | awk  'BEGIN{OFS="\t"}{print $1,"multi"}' - >> ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_mapped.txt &&
    $samtools_path view -f 0x4 ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment.sam | cut -f 1 | awk  'BEGIN{OFS="\t"}{print $1,"unmap"}' - >> ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_mapped.txt
done
