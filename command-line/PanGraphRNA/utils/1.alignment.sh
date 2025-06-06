#!/bin/bash
hisat2_path="No_input"
perl_path="No_input"
samtools_path="No_input"
threads=15
output_dir=""
pair="paired"
strand_info="unstranded"
accession_name="No_input"
min_intron_length=20
max_intron_length=500000
mismatch="9,3"
left_reads="No_input"
right_reads="No_input"
single_reads="No_input"
unique="yes"
index_path="No_input"
output_name=""

while getopts "t:o:p:s:i:x:m:l:r:u:U:n:P:H:I:T:h" arg
do
        case $arg in
        t)
            threads=$OPTARG
                ;;
        o)
            output_dir=$OPTARG
                ;;
        p)
            pair=$OPTARG
                ;;
        s)
            strand_info=$OPTARG
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
        l)
            left_reads=$OPTARG
                ;;
        r)
            right_reads=$OPTARG
                ;;
        u)
            single_reads=$OPTARG
                ;;
        U)  
            unique=$OPTARG
                ;;
        n)  
            output_name=$OPTARG
                ;;
        P)
            perl_path=$OPTARG
                ;;
        H)
            hisat2_path=$OPTARG
                ;;
        I)
            index_path=$OPTARG
                ;;
        T)
            samtools_path=$OPTARG
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
            echo "-l <string>: left reads."
            echo "    "
            echo "-r <string>: right reads."
            echo "    "
            echo "-o <string>: output directory."
            echo "    "
            echo "---------------------------------------------------------------------------"
            echo "    "
            echo "** Options **"
            echo "    "
            echo "-t <int>: number of threads, default: 20."
            echo "    "
            echo "-p <string>: type of sequencing: ( pair or single ), default: pair."
            echo "    "
            echo "-s <string>: strand-specific RNA-Seq reads orientation, default: unstranded."
            echo "             if paired_end: RF or FR;"
            echo "             if single_end: F or R."
            echo "    "
            echo "-a <string>: accession name, default: No_input."
            echo "    "
            echo "-i <int>: minimum intron length, default: 20."
            echo "    "
            echo "-x <int>: maximum intron length, default: 500000."
            echo "    "
            echo "-m <string>: mismatch, default: 9,3."
            echo "    "
            echo "-u <string>: single reads."
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

if [ $pair == "paired" ]; then
    phredval=$(cat $left_reads | ${perl_path}/perl ./0_fastq_phred.pl - | grep -o "Phred.." | sed "s/Phred//");
    echo $phredval
    
    if [ ${strand_info} != "unstranded" ]; then
        strand_info="--rna-strandness ${strand_info}"
    else
        strand_info=""
    fi
    ${hisat2_path}/hisat2 -p $threads -x $index_path -1 $left_reads -2 $right_reads --phred$phredval --min-intronlen $min_intron_length --max-intronlen $max_intron_length --mp $mismatch  --summary-file ${output_dir}/${output_name}_summary.txt -S ${output_dir}/${output_name}_alignment.sam $strand_info
fi
if [ $pair == "single" ]; then
    phredval=$(cat $single_reads | ${perl_path}/perl ./0_fastq_phred.pl - | grep -o "Phred.." | sed "s/Phred//");
    if [ ${strand_info} != "unstranded" ]; then
        strand_info="--rna-strandness ${strand_info}"
    else
        strand_info=""
    fi
    ${hisat2_path}/hisat2 -p $threads -x $index_path -U $single_reads --phred$phredval --min-intronlen $min_intron_length --max-intronlen $max_intron_length --mp $mismatch  --summary-file ${output_dir}/${output_name}_summary.txt -S ${output_dir}/${output_name}_alignment.sam $strand_info
fi

if [ $unique == "yes" ]; then
    $samtools_path/samtools view -H ${output_dir}/${output_name}_alignment.sam > ${output_dir}/${output_name}_alignment_unique.sam &&
    grep -w "NH:i:1" ${output_dir}/${output_name}_alignment.sam >> ${output_dir}/${output_name}_alignment_unique.sam &&
    $samtools_path/samtools view -@ $threads -bS ${output_dir}/${output_name}_alignment_unique.sam > ${output_dir}/${output_name}_alignment_unique.bam &&
    $samtools_path/samtools sort -@ $threads ${output_dir}/${output_name}_alignment_unique.bam -o ${output_dir}/${output_name}_alignment_unique_sorted.bam &&
    rm -rf ${output_dir}/${output_name}_alignment.sam &&
    rm -rf ${output_dir}/${output_name}_alignment_unique.sam &&
    rm -rf ${output_dir}/${output_name}_alignment_unique.bam
else
    $samtools_path/samtools view -@ $threads -bS ${output_dir}/${output_name}_alignment.sam > ${output_dir}/${output_name}_alignment_output.bam
    rm -rf ${output_dir}/${output_name}_alignment.sam
fi
