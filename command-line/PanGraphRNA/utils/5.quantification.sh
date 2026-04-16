#!/bin/bash

input_list="No_input"
samtools_path="No_input"
stringtie_path="No_input"
r_path="No_input"
threads=15
output_dir=""
while getopts "i:s:S:t:r:o:G:W:h" arg
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
        G)
            gtf_file=$OPTARG
                ;;
        W)
            tool_path=$OPTARG
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

mkdir -p ${output_dir}/gene_exp
mkdir -p ${output_dir}/trans_exp

cat $input_list | while read line
do
    base_name=`basename $line | sed 's/\.[^.]*$//'`
    
    ${samtools_path}/samtools sort -@ $threads $line > ${base_name}_sorted.bam
    output_tmp=${output_dir%/}
    ${stringtie_path}/stringtie -e -p $threads -G ${gtf_file} -A ${output_tmp}/gene_exp/${base_name}_gene.gtf -o ${output_tmp}/trans_exp/${base_name}_trans.gtf ${base_name}_sorted.bam
done

${r_path}/Rscript ${tool_path}/5.gene_TPM_merge.R ${output_dir} &&

ls ${output_dir}/trans_exp/ > ${output_dir}/aa  &&
ls ${output_dir}/trans_exp|sed 's/_tri.*//g'|paste - ${output_dir}/aa > ${output_dir}/prepDE_input.txt
cd ${output_dir}/trans_exp  &&
current_dir=`pwd`
python ${tool_path}/5.prepDE.py3 -i ${current_dir}/../prepDE_input.txt -g ${current_dir}/../readcount_gene_stringtie.csv -t ${current_dir}/../readcount_trans_stringtie.csv
cd ../

output_tmp=${output_dir%/}
rm ${output_tmp}/aa
rm ${output_tmp}/prepDE_input.txt