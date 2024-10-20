#!/bin/bash

IFS=',' read -r -a array1 <<< "$2"
IFS=',' read -r -a array2 <<< "$3"
echo -e "sampleID\tuniq_reads\tmulti_reads\treads_sum\tmapping_rate" >  $1
for ((i=0; i<${#array1[@]}; i++)); do

    output_reads_sum=$( grep "reads; of these:" ${array1[i]} | sed 's/ reads; of these://g' )
    ifpair=`grep -c  "aligned concordantly" ${array1[i]}`
    if [ ${ifpair} -ne '0' ];then
        # Uniq reads
        reads_sum=$(expr $output_reads_sum \* 2)
        uniq_reads_1=$( grep "aligned concordantly exactly 1 time" ${array1[i]} | sed -r 's/ \(.+//g' | sed 's/ //g' )
        uniq_reads_2=$( grep "aligned discordantly 1 time" ${array1[i]} | sed -r 's/ \(.+//g' | sed 's/ //g' )
        uniq_reads_3=$( grep "aligned exactly 1 time" ${array1[i]} | sed -r 's/ \(.+//g' | sed 's/ //g' )
        uniq_reads=$( expr $uniq_reads_1 \* 2 + $uniq_reads_2 \* 2 + $uniq_reads_3 )
        # Multiple-mapped reads
        multi_reads_1=$( grep "aligned concordantly >1 times" ${array1[i]} | sed -r 's/ \(.+//g' | sed 's/ //g' )
        multi_reads_2=$( grep "aligned >1 times" ${array1[i]} | sed -r 's/ \(.+//g' | sed 's/ //g' )
        multi_reads=$( expr $multi_reads_1 \* 2 + $multi_reads_2 )
    else 
        reads_sum=${output_reads_sum}
        uniq_reads=$( grep "aligned exactly 1 time" ${array1[i]} | sed -r 's/ \(.+//g' | sed 's/ //g' )
        multi_reads=$( grep "aligned >1 times" ${array1[i]} | sed -r 's/ \(.+//g' | sed 's/ //g' )
    fi

    # Mapping-rate
    mapping_rate=$( grep "overall alignment rate" ${array1[i]} | sed 's/overall alignment rate//g' | sed 's/ //g')
    echo -e "${array2[i]}\t${uniq_reads}\t${multi_reads}\t${reads_sum}\t${mapping_rate}" >>  $1
done