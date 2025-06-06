# -*- coding: utf-8 -*-

"""CatMOD is a .

This is a rough draft of the author's analysis of ***.
We will continue to add applications until we felt ready to say OK, and
we will release an official version through pip and bioconda.

"""

from sys import exit, version_info

from PanGraphRNA import fullhelp_argumentparser
from PanGraphRNA.sys_output import Output

# version control
if version_info[0] == 3 and version_info[1] >= 9:
    pass
else:
    output = Output()
    output.error('This program requires at least python3.9')
    exit()


def main():
    """Create subcommands and execute."""
    parser = fullhelp_argumentparser.FullHelpArgumentParser()
    subparser = parser.add_subparsers()
    fullhelp_argumentparser.SRAArgs(
        subparser,
        'sra2fastq',
        """In this function, wrapped fastq-dump function implemented in SRA Toolkit. 
        See http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?view=software for details.""")
    fullhelp_argumentparser.QCArgs(
        subparser,
        'quality_control',
        """In this function, one existing NGS tool fastp (Chen et al., 2018) is integrated to check sequencing reads quality and obtain high-quality reads, respectively.""")
    fullhelp_argumentparser.GPCArgs(
        subparser,
        'graph_pangenome_constructor',
        """In this function, an ultrafast and memory-efficient tool HISAT2 (Kim, D., et al., 2019) is integrated for constructing graph pangenomes. 
        See https://daehwankimlab.github.io/hisat2/manual for details.""")
    fullhelp_argumentparser.AlignmentArgs(
        subparser,
        'align',
        """In this function, an ultrafast and memory-efficient tool HISAT2 (Kim, D., et al., 2019) is integrated for aligning sequencing reads. 
        See https://daehwankimlab.github.io/hisat2/manual for details.""")
    fullhelp_argumentparser.AlignmentStatisticsArgs(
        subparser,
        'alignment_satistics',
        """In this function, PanGraphRNA can count uniquely mapped reads, multiply mapped reads and calculate alignment rates among multiple read-genome alignment results.""")
    fullhelp_argumentparser.ExpressionQuantificationArgs(
        subparser,
        'expression_quantification',
        """In this function, an fast and highly efficient tool StringTie (Pertea, M., et al., 2015) is used for gene expression quantification. See https://github.com/gpertea/stringtie for details.""")
    fullhelp_argumentparser.DifferentialExpressionArgs(
        subparser,
        'differential_expression',
        """In this function, a statistical tool DESeq2 (Love, MI., et al., 2014) is integrated for perform differential gene expression analysis. See https://bioconductor.org/packages/release/bioc/html/DESeq2.html for details.""")
    fullhelp_argumentparser.QuantitativeTraitLocusArgs(
        subparser,
        'quantitative_trait_locus',
        """In this function, a fast eQTL analysis tool MatrixEQTL (Shabalin, AA., et al., 2012) is integrated for perform identification of expression quantitative trait locus. See http://www.bios.unc.edu/research/genomic_software/Matrix_eQTL for details.""")

    def bad_args(args):
        """Print help on bad arguments."""
        parser.print_help()
        exit()

    parser.set_defaults(func=bad_args)
    arguments = parser.parse_args()
    arguments.func(arguments)


if __name__ == '__main__':
    main()