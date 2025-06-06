#!/bin/bash
dir=$1
readnum=$2
simreads=$dir/simreads
exon_gtf=$3
accession_name=$4
flux="/home/galaxy/miniconda3/envs/bio/bin/flux-simulator"
liftover="/home/galaxy/liftOver"

source /home/galaxy/miniconda3/etc/profile.d/conda.sh
conda activate /home/galaxy/miniconda3/envs/bio/

cat ${dir}/simlist | while read row || [[ -n ${row} ]]
do 
    denovoid=`echo ${row}| awk '{print $1}'`
    line=${denovoid}_rep`echo ${row}| awk '{print $2}'`

    ${flux} -t simulator -x -l -s -p ${simreads}/paramfile/${line}_${readnum}.par
    ${liftover} -bedPlus=6 ${simreads}/paramfile/${line}_${readnum}.bed ${dir}/pseudo_${accession_name}toref.chain ${simreads}/paramfile/bedfile/${line}_${readnum}.bed ${simreads}/paramfile/bedfile/${line}_${readnum}_unlift.bed
    ${liftover} -bedPlus=6 ${simreads}/paramfile/bedfile/${line}_${readnum}.bed ${dir}/pseudo_${accession_name}toref.chain ${simreads}/paramfile/${line}_${readnum}_check.bed ${simreads}/paramfile/${line}_${readnum}_check_unlift.bed
    unmapcheck=`wc ${simreads}/paramfile/${line}_${readnum}_check_unlift.bed|awk '{print $1}'`

    if [ $unmapcheck -ne 0 ]
        then 
        awk 'FNR==NR{a[$4];next}!($4 in a ){print}' ${simreads}/paramfile/${line}_${readnum}_check_unlift.bed ${simreads}/paramfile/bedfile/${line}_${readnum}.bed > \
        ${simreads}/paramfile/bedfile/${line}_${readnum}_filter.bed
        mv ${simreads}/paramfile/bedfile/${line}_${readnum}_filter.bed ${simreads}/paramfile/bedfile/${line}_${readnum}.bed
    fi
    cut -f 4 ${simreads}/paramfile/bedfile/${line}_${readnum}.bed > ${simreads}/${line}_tmpid.txt
    /home/galaxy/miniconda3/envs/bio/bin/seqtk subseq ${simreads}/paramfile/${line}_${readnum}.fasta ${simreads}/${line}_tmpid.txt > ${simreads}/fastasim/${line}_${readnum}.fasta
    rm ${simreads}/paramfile/${line}_${readnum}.fasta ${simreads}/paramfile/${line}_${readnum}.bed \
    ${simreads}/paramfile/${line}_${readnum}.lib ${simreads}/paramfile/${line}_${readnum}_check_unlift.bed
    mv ${simreads}/paramfile/${line}_${readnum}.pro ${simreads}/paramfile/profile/${line}_${readnum}.pro
    mv ${simreads}/paramfile/${line}_${readnum}.par ${simreads}/paramfile/parfile/${line}_${readnum}.par
    rm ${simreads}/${line}_tmpid.txt
    rm ${simreads}/paramfile/bedfile/${line}_${readnum}_unlift.bed ${simreads}/paramfile/${line}_${readnum}_check.bed
    gzip -9 -f ${simreads}/paramfile/bedfile/${line}_${readnum}.bed &
done