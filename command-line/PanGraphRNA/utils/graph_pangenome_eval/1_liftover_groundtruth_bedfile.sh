#!/bin/bash
hisat2_path="/home/galaxy/miniconda3/envs/bio/bin/hisat2"
samtools_path="/home/galaxy/miniconda3/envs/bio/bin/samtools"
bedtools_path="/home/galaxy/miniconda3/envs/bio/bin/bedtools"
lifttools_path="/home/galaxy/liftOver"
bedtools_path="/home/galaxy/miniconda3/envs/bio/bin/bedtools"

ref_genome="No_input"
threads=20
output_dir=""
accession_name="No_input"
chain_file="No_input"


while getopts "R:t:o:c:a:h" arg
do
        case $arg in
        R)
            ref_genome=$OPTARG
                ;;
        t)  
            threads=$OPTARG
                ;;
        o)  
            output_dir=$OPTARG
                ;;
        c)
            chain_file=$OPTARG
                ;;
        a)  
            accession_name=$OPTARG
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
            echo "-o <string>: output directory."
            echo "    "
            echo "-c <string>: chain file."
            echo "    "
            echo "---------------------------------------------------------------------------"
            echo "    "
            echo "** Options **"
            echo "    "
            echo "-t <int>: number of threads, default: 20."
            echo "    "
            echo "-a <string>: accession name, default: No_input."
            echo "    "
            echo "-h: "
            echo "==========================================================================="
            exit 1
                ;;
        esac
done



for file in ${output_dir}/simreads/fastasim/*  ;do
    $lifttools_path -bedPlus=6 ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq_sort.bed $chain_file ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq_sort.lift.bed ${output_dir}/$(basename "$file")_${ref_genome##*/}_alignment_uniq_sort.unlift.bed
    touch ${output_dir}/sample_info
    echo -e "$(basename "$file")\tgroundtruth" >> ${output_dir}/sample_info

done