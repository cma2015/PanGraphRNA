#!/bin/bash

bcftools_path=""
hisat2_path=""
R_path=""
fasta_file=""
method=""
accession_num=""
accession_txt=""
vcf_file=""
output_path=""
output_name=""
gtf_path="No_input"
threads=10

while getopts "B:H:R:F:m:a:t:v:o:n:g:T:W:h" arg
do
        case $arg in
        B)
            bcftools_path=$OPTARG
                ;;
        H)
            hisat2_path=$OPTARG
                ;;
        R)
            R_path=$OPTARG
                ;;
        F)
            fasta_file=$OPTARG
                ;;        
        m)
            method=$OPTARG
                ;;
        a)
            accession_num=$OPTARG
                ;;
        t)
            accession_txt=$OPTARG
                ;;
        v)
            vcf_file=$OPTARG
                ;;
        o)
            output_path=$OPTARG
               ;;
        n)
            output_name=$OPTARG
                ;;
        g)
            gtf_path=$OPTARG
                ;;
        T)
            threads=$OPTARG
                ;;
        W)
            tool_path=$OPTARG
                ;;
        h)
            exit 1
            ;;
        esac
done

if [ $gtf_path != "No_input" ]; then
    ${hisat2_path}/hisat2_extract_exons.py $gtf_path > ${output_path}/tmp/tmp.exon
    ${hisat2_path}/hisat2_extract_splice_sites.py $gtf_path > ${output_path}/tmp/tmp.ss
fi

if [ $method == "Individual" ]; then
    echo "run ${bcftools_path}/bcftools view --min-ac 1:nref --force-samples -s $accession_num $vcf_file | ${bcftools_path}/bcftools view -i 'GT!~"\." & GT!~"\0"' -Oz --output ${output_path}/tmp/tmp.vcf.gz"
    ${bcftools_path}/bcftools view --min-ac 1:nref --force-samples -s $accession_num $vcf_file | ${bcftools_path}/bcftools view -i 'GT!~"\." & GT!~"\0"' -Oz --output ${output_path}/tmp/tmp.vcf.gz &&
    echo "run ${hisat2_path}/hisat2_extract_snps_haplotypes_VCF.py $fasta_file ${output_path}/tmp/tmp.vcf.gz ${output_path}/tmp/tmp_line --non-rs --inter-gap 1024 --intra-gap 150"
    ${hisat2_path}/hisat2_extract_snps_haplotypes_VCF.py $fasta_file ${output_path}/tmp/tmp.vcf.gz ${output_path}/tmp/tmp_line --non-rs --inter-gap 1024 --intra-gap 150 &&
    echo "run ${R_path}/Rscript ${tool_path}/0.prep_haplotype.R tmp_line ${output_path}/tmp var"
    ${R_path}/Rscript ${tool_path}/0.prep_haplotype.R tmp_line ${output_path}/tmp var
elif [ $method == "Population" ]; then
    ${bcftools_path}/bcftools view --min-ac 5:nref $vcf_file | ${bcftools_path}/bcftools view -i 'GT!~"\." & GT!~"\0"' -Oz --output ${output_path}/tmp/tmp.vcf.gz &&
    ${hisat2_path}/hisat2_extract_snps_haplotypes_VCF.py $fasta_file ${output_path}/tmp/tmp.vcf.gz ${output_path}/tmp/tmp_line --non-rs --inter-gap 1024 --intra-gap 150 &&
    ${R_path}/Rscript ${tool_path}/0.prep_haplotype.R tmp_line ${output_path}/tmp var
elif [ $method == "Subpopulation" ]; then
    ${bcftools_path}/bcftools view --min-ac 3:nref --force-samples -S $accession_txt $vcf_file | ${bcftools_path}/bcftools norm -m+ | ${bcftools_path}/bcftools view -Oz -o ${output_path}/tmp/tmp.vcf.gz &&
    ${hisat2_path}/hisat2_extract_snps_haplotypes_VCF.py $fasta_file ${output_path}/tmp/tmp.vcf.gz ${output_path}/tmp/tmp_line --non-rs --inter-gap 1024 --intra-gap 150 &&
    ${R_path}/Rscript ${tool_path}/0.prep_haplotype.R tmp_line ${output_path}/tmp var
else
    echo "Please provide the correct index type."
    exit 1
fi


if  [ -f "${output_path}/tmp/tmp.ss" ]; then
    ${hisat2_path}/hisat2-build -p $threads $fasta_file --snp ${output_path}/tmp/tmp_line.snp --ss ${output_path}/tmp/tmp.ss --exon ${output_path}/tmp/tmp.exon --haplotype ${output_path}/tmp/tmp_line.rmdup.haplotype ${output_path}/${output_name}
else
    ${hisat2_path}/hisat2-build -p $threads $fasta_file --snp ${output_path}/tmp/tmp_line.snp --haplotype ${output_path}/tmp/tmp_line.rmdup.haplotype ${output_path}/${output_name}
fi

rm -rf ${output_path}/tmp