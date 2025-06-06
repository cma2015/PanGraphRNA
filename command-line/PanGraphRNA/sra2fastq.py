from logging import getLogger
from pathlib import Path
from multiprocessing import cpu_count, Pool

import numpy as np

from rich.progress import Progress
from PanGraphRNA.sys_output import Output
import subprocess


logger = getLogger(__name__)  # pylint: disable=invalid-name

class Sra2Fastq(object):
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
    def sra2fastq(self):
        software_path = self.args.software
        input_path = self.args.input
        output_path = self.args.output
        minread = str(self.args.minread)
        files_list = [
            f for f in Path(input_path).glob('**/*.sra') if f.is_file()
        ]
        script_path = f'{software_path}/fastq-dump'
        with Progress() as progress:
            task = progress.add_task(
                f'[green]INFO    [cyan]Process {len(files_list)} SRA files...',
                total=len(files_list))
            
            for file in files_list:
                args = [
                    script_path,
                    file,
                    "-M", minread,
                    "--split-3",
                    "-O", output_path
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
                    self.output.error(f"Can not found file {script_path}")
                progress.advance(task)

    def process(self):
        self.output.info('Starting sra2fastq Process.')
        self.check_directory()
        self.sra2fastq()
        self.output.info('Completed sra2fastq Process.')
