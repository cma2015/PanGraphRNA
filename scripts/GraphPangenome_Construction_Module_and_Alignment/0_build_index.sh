#!/bin/bash
index_type="individual"
index_path="No_input"
accession_name="No_input"
vcf_file="No_input"
tmp_dir="No_input"
threads=10
ref_genome="No_input"


while getopts "R:T:a:v:o:t:h" arg
do
        case $arg in
        R)
            ref_genome=$OPTARG
                ;;
        T)
            index_type=$OPTARG
                ;;
        a)
            accession_name=$OPTARG
                ;;
        v)
            vcf_file=$OPTARG
                ;;
        o)
            tmp_dir=$OPTARG
                ;;
        t)
            threads=$OPTARG
                ;;
        h)
            echo "    "
            echo "==========================================================================="
            echo "    "
            echo "Usage: $0 -R ref_genome -T index_type -a accession_name -v vcf_file -o output -t threads"
            echo "    "
            echo "==========================================================================="
            echo "    "
            exit 1
            ;;
        esac
done

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

if [ ! -f "${index_path}.1.ht2" ]; then 
    /home/galaxy/miniconda3/envs/bio/bin/hisat2-build -p $threads $ref_genome --snp $tmp_dir/tmp_line.snp --haplotype $tmp_dir/tmp_line.rmdup.haplotype $index_path
fi 
