#!/bin/bash
hisat2_path="/home/galaxy/miniconda3/envs/bio/bin/hisat2"
samtools_path="/home/galaxy/miniconda3/envs/bio/bin/samtools"
ref_genome="No_input"
vcf_file="No_input"
threads=20
output_dir=""
pair="pair"
strand_info="unstranded"
accession_name="No_input"
min_intron_length=20
max_intron_length=500000
mismatch="9,3"
left_reads="No_input"
right_reads="No_input"
single_reads="No_input"
unique="yes"
index_type="individual"
index_path="No_input"
while getopts "R:v:t:o:p:s:a:i:x:m:l:r:u:U:T:h" arg
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
        p)
            pair=$OPTARG
                ;;
        s)
            strand_info=$OPTARG
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

if [ $ref_genome == "No_input" ] || [ $vcf_file == "No_input" ] || [ $left_reads == "No_input" ] || [ $right_reads == "No_input" ] || [ $output_dir == "" ]; then
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

if [ $pair == "pair" ]; then
    phredval=$(cat $left_reads | /home/galaxy/miniconda3/envs/bio/bin/perl /galaxy/server/tools/alignment/0_fastq_phred.pl - | grep -o "Phred.." | sed "s/Phred//");
    echo $phredval
    
    if [ ${strand_info} != "unstranded" ]; then
        strand_info="--rna-strandness ${strand_info}"
    else
        strand_info=""
    fi
    $hisat2_path -p $threads -x $index_path -1 $left_reads -2 $right_reads --phred$phredval --min-intronlen $min_intron_length --max-intronlen $max_intron_length --mp $mismatch  --summary-file ${output_dir}/summary.txt -S ${output_dir}/alignment.sam $strand_info
fi
if [ $pair == "single" ]; then
    phredval=$(cat $single_reads | /home/galaxy/miniconda3/envs/bio/bin/perl /galaxy/server/tools/alignment/0_fastq_phred.pl - | grep -o "Phred.." | sed "s/Phred//");
    if [ ${strand_info} != "unstranded" ]; then
        strand_info="--rna-strandness ${strand_info}"
    else
        strand_info=""
    fi
    $hisat2_path -p $threads -x $index_path -U $single_reads --phred$phredval --min-intronlen $min_intron_length --max-intronlen $max_intron_length --mp $mismatch  --summary-file ${output_dir}/summary.txt -S ${output_dir}/alignment.sam $strand_info
fi

if [ $unique == "yes" ]; then
    $samtools_path view -H ${output_dir}/alignment.sam > ${output_dir}/alignment_unique.sam &&
    grep -w "NH:i:1" ${output_dir}/alignment.sam >> ${output_dir}/alignment_unique.sam &&
    $samtools_path view -@ $threads -bS ${output_dir}/alignment_unique.sam > ${output_dir}/alignment_unique.bam &&
    $samtools_path sort -@ $threads ${output_dir}/alignment_unique.bam -o ${output_dir}/alignment_unique_sorted.bam &&
    mv ${output_dir}/alignment_unique_sorted.bam ${output_dir}/alignment_output.bam
else
    $samtools_path view -@ $threads -bS ${output_dir}/alignment.sam > ${output_dir}/alignment_output.bam
fi
