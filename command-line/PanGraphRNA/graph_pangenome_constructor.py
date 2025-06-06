from logging import getLogger
from pathlib import Path

from PanGraphRNA.sys_output import Output
import subprocess

import os

script_path = os.path.join(os.getcwd(), __file__)
script_dir = os.path.dirname(script_path)
logger = getLogger(__name__)  # pylint: disable=invalid-name

class GraphPangenomeConstructor(object):
    """The extract featres process.

    Attributes:
      - args: Arguments.
      - output: Output info, warning and error.
    """

    def __init__(self, arguments):
        """Initialize ExtractFeatures."""
        self.args = arguments
        self.output = Output()
        self.output.info(
            f'Initializing {self.__class__.__name__}: (args: {arguments}.')
        logger.debug(
            f'Initializing {self.__class__.__name__}: (args: {arguments}.')

    def check_args(self):
        """Check arguments."""
        if self.args.accession_list and self.args.method != "Subpopulation":
            self.output.error('The --accession_list parameter can only be used together with --method Subpopulation')
            exit()
        if self.args.accession and self.args.method != "Individual":
            self.output.error('The --accession parameter can only be used together with --method Individual')
            exit()
        
    def check_directory(self):
        """Check output directory."""
        self.output.info('Checking output directory.')
        self.output_str = self.args.output
        self.output_path = Path(f'{self.output_str}/tmp')
        if not self.output_path.is_dir():
            self.output.info('Creating output directory.')
            self.output_path.mkdir()
    
    def graph_pangenome_constructing(self):
        bcf_path = self.args.bcf_path
        hisat2_path = self.args.hisat2_path
        r_path = self.args.r_path
        ref_genome = self.args.fasta
        vcf_file = self.args.vcf
        method = self.args.method
        gtf_path = "No_input" if self.args.gtf is None else self.args.gtf
        accession_list = "No_input"  if self.args.accession_list is None else self.args.accession_list
        accession = "No_input" if self.args.accession is None else self.args.accession
        threads = str(self.args.threads)
        output_path = self.args.output
        output_name = self.args.name
        
        args = [
            f'{script_dir}/utils/0.prep_pangenome_construction.sh',
            '-B', bcf_path,
            '-H', hisat2_path,
            '-R', r_path,
            '-F', ref_genome,
            '-v', vcf_file,
            '-m', method,
            '-g', gtf_path,
            '-t', accession_list,
            '-a', accession,
            '-T', threads,
            '-o', output_path,
            '-n', output_name
        ]

        try:
            result = subprocess.run(
                args,
                capture_output=True,
                text=True, 
                check=True 
            )
        except subprocess.CalledProcessError as e:
            self.output.error(e.stderr)
        except FileNotFoundError:
            self.output.error(f"Can not found file {script_dir}/utils/0.prep_pangenome_construction.sh")

    def process(self):
        self.check_args()
        self.check_directory()
        self.output.info('Starting Graph Pangenome Constructing.')
        self.graph_pangenome_constructing()
        self.output.info('Completed Graph Pangenome Constructing.')
