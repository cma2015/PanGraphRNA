from Bio import SeqIO
import sys
def fa_chr_split(fa_file, out_dir):
    with open(fa_file, 'r') as f:
        for record in SeqIO.parse(f, 'fasta'):
            with open(f'{out_dir}/{record.id}.fa', 'w') as out:
                SeqIO.write(record, out, 'fasta')

fa_chr_split(sys.argv[1], sys.argv[2])