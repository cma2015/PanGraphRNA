#!/bin/bash

input_list="No_input"
samtools_path="No_input"
stringtie_path="No_input"
r_path="No_input"
threads=15
output_dir=""
while getopts "i:s:S:t:r:o:h" arg
do
        case $arg in
        i)
            input_list=$OPTARG
                ;;
        s)
            samtools_path=$OPTARG
                ;;
        S)
            stringtie_path=$OPTARG
                ;;
        t)
            threads=$OPTARG
                ;;
        r)
            r_path=$OPTARG
                ;;
        o)
            output_dir=$OPTARG
                ;;
        h)
            echo "    "
            echo "==========================================================================="
            echo "    "
            echo "Stringtie v1.0 usage:"
            echo "    "
            echo "** Required **"
            echo "    "
            echo "-i <string>: input list."
            echo "    "
            echo "-s <string>: samtools path."

        esac
done

cat $input_list | while read line
do
    ${samtools_path}/samtools sort -@ $threads $line > ${${line##*/}%.*}_sorted.bam
    ${stringtie_path}/stringtie -e -p $threads -A ${output_dir}/gene_exp/${${line##*/}%.*}_gene.gtf -o ${output_dir}/trans_exp/${${line##*/}%.*}_trans.gtf ${${line##*/}%.*}_sorted.bam
done

${r_path}/Rscript ./1_gene_TPM_merge.R ${output_dir} &&

ls ${output_dir}/trans_exp/ > ${output_dir}/aa  &&
ls ${output_dir}/trans_exp|sed 's/_tri.*//g'|paste - ${output_dir}/aa > ${output_dir}/prepDE_input.txt