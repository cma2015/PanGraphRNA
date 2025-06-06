from logging import getLogger
from pathlib import Path

from PanGraphRNA.sys_output import Output
import subprocess

import os

script_path = os.path.join(os.getcwd(), __file__)
script_dir = os.path.dirname(script_path)
logger = getLogger(__name__)  # pylint: disable=invalid-name

class AlignmentStatistics(object):
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
    def alignment_statistics(self):
        input_path = self.args.input_path
        output_path = self.args.output_path
        output_name = self.args.output_name
        args = [
            f'{script_dir}/utils/2.mapping_rate.sh',
            output_path,
            output_name,
            input_path
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
            self.output.error(f"Can not found file {script_dir}/utils/2.mapping_rate.sh")
        
    def process(self):
        self.check_directory()
        self.output.info('Starting Alignment Statistics Process.')
        self.alignment_statistics()
        self.output.info('Completed Alignment Statistics Process.')
