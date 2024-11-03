<div align='center' >
<p><font size='70'><strong>PanGraphRNA User Manual</strong></font></p>
<font size='100'>(version 1.0)</font>
</div>

- PanGraphRNA is an efficient, flexible and web-based Galaxy platform that can be easily used to construct graph pangenomes from genetic variations at individual, subpopulation, and population levels. It can assist researchers to select appropriate graph pangenomes using various performance metrics for both real and simulation experiments. 
- Currently, PanGraphRNA is composed of four functional modules: **Graph Pangenome Preparation Module, Construction Module, Evaluation Module, and Application Moudule**.
- PanGraphRNA was powered with an advanced  packaging technology, which enables compatibility and portability.
- PanGraphRNA project is hosted on [https://github.com/cma2015/PanGraphRNA](https://github.com/cma2015/PanGraphRNA)
- PanGraphRNA docker image is available at [https://hub.docker.com/r/malab/pangraphrna](https://hub.docker.com/r/malab/pangraphrna)

## Graph Pangenome Application Module

This module performs several applications of graph pangenomes, including differential expression analysis and expression-based QTL analysis.

| **Tools**                       | **Description**                                              | **Input**                                       | **Output**                                        | **Time (test data)**         | **Reference**                                                |
| ------------------------------- | ------------------------------------------------------------ | ----------------------------------------------- | ------------------------------------------------- | ---------------------------- | ------------------------------------------------------------ |
| **Expression Quantification** | Perform expression quantification for read-genome alignment result | Alignment result in BAM format and annotation file in GTF format | Gene read count matrix in TXT format and gene expression quantification matrix in TXT format | ~5 mins                      | <a href="https://github.com/gpertea/stringtie" target="_blank">StringTie</a> |
| **Differential Expression Analysis**               | Perform differential expression analysis | Gene read count matrix in CSV format                 | Information of differentially expressed genes in CSV format                    | ~5 mins | <a href="https://github.com/thelovelab/DESeq2" target="_blank">DESeq2</a> |
| **Quantitative Trait Locus Identification**               | Perform identification of expression quantitative trait locus | Variation files and gene expression matrix in TXT format                  | Identification of expression quantitative trait locus in RData and TXT format                    | ~10 mins | <a href="https://github.com/andreyshabalin/MatrixEQTL" target="_blank">MatrixEQTL</a> |


## Expression Quantification

In this function, an fast and highly efficient tool **StringTie** (Pertea, M., _et al_., 2015) is used for gene expression quantification. See [https://github.com/gpertea/stringtie](https://github.com/gpertea/stringtie) for details.

#### Input

-   **Input RNA-Seq alignment result:** Input read-genome alignment results in BAM format
-   **Input annotation file:** Input annotation file (GTF file) of reference genome file used for constructing the primary path of graph pangenome
  
#### Parameters

-   **Threads:** The number of threads used for parallel computation (Default: 10)

#### Output

-   **Gene read count matrix in TXT format**
-   **Gene expression quantification matrix in TXT format**

![[Figure4_1.jpg]]

## Differential Expression Analysis

In this function, a statistical tool **DESeq2** (Love, MI., _et al_., 2014) is integrated for perform differential gene expression analysis. See [https://bioconductor.org/packages/release/bioc/html/DESeq2.html](https://bioconductor.org/packages/release/bioc/html/DESeq2.html) for details.

#### Input

-  **Input read count matrix:** Input gene read count matrix in CSV format
  
#### Output

-   **Information of differentially expressed genes in CSV format**

![[Figure4_2.jpg]]

## Quantitative Trait Locus Identification

In this function, a fast eQTL analysis tool **MatrixEQTL** (Shabalin, AA., _et al_., 2012) is integrated for perform identification of expression quantitative trait locus. See [http://www.bios.unc.edu/research/genomic_software/Matrix_eQTL](http://www.bios.unc.edu/research/genomic_software/Matrix_eQTL) for details.

#### Input

-   **Input variation genotype file:** Input variation genotype file in TXT format
-   **Input variation coordinate file:** Input variation coordinate file in TXT format
-   **Input variation covariates file:** Input variation covariates file in TXT format
-   **Input gene expression matrix file:** Input gene expression matrix file in TXT format
-   **Input gene coordinate file:** Input gene coordinate file in TXT format
  
#### Parameters

-   **Threshold of False Discovery Rate:** Results exceeding the False Discovery Rate threshold (default: 0.05) will be filtered out

#### Output

-   **Identification of expression quantitative trait locus in RData and TXT format**

![[Figure4_3.jpg]]
