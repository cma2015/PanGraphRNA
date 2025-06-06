from logging import getLogger
from pathlib import Path

from PanGraphRNA.sys_output import Output
import subprocess

import os

script_path = os.path.join(os.getcwd(), __file__)
script_dir = os.path.dirname(script_path)
logger = getLogger(__name__)  # pylint: disable=invalid-name

class QuantitativeTraitLocus(object):
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

    def check_directory(self):
        """Check output directory."""
        self.output.info('Checking output directory.')
        self.output_str = self.args.output
        self.output_path = Path(self.output_str)
        if not self.output_path.is_dir():
            self.output.info('Creating output directory.')
            self.output_path.mkdir()
    def differential_expression(self):
        variation_genotype = self.args.variation_genotype
        variation_coordinate = self.args.variation_coordinate
        varitaion_covariates  = self.args.variation_covariates
        gene_expression = self.args.gene_expression
        gene_coordinate = self.args.gene_coordinate
        fdr = str(self.args.FDR)
        output_path = self.args.output_path
        r_path = self.args.r_path

        args = [
            f'{r_path}/Rscript',
            f'{script_dir}/utils/4.run_eqtl.R',
            output_path,
            variation_genotype,
            variation_coordinate,
            varitaion_covariates,
            gene_expression,
            gene_coordinate,
            fdr
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
            self.output.error(f"Can not found file {script_dir}/utils/4.run_eqtl.R")
        
    def process(self):
        self.check_directory()
        self.output.info('Starting Alignment Statistics Process.')
        self.differential_expression()
        self.output.info('Completed Alignment Statistics Process.')
