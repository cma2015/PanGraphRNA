from logging import getLogger
from pathlib import Path

from PanGraphRNA.sys_output import Output
import subprocess
import os

script_path = os.path.join(os.getcwd(), __file__)
script_dir = os.path.dirname(script_path)
logger = getLogger(__name__)  # pylint: disable=invalid-name

class Alignment(object):
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
        if self.args.single_file and self.args.fastq_type != 'single':
            self.output.error("The --single_file parameter can only be used together with --fastq_type single")
            exit()
        if self.args.single_file and self.args.fastq_type != 'single':
            self.output.error("The --single_file parameter can only be used together with --fastq_type single")
            exit()
        if self.args.fastq_type == 'single' and (self.args.strand_info == 'RF' or self.args.strand_info == 'FR'):
            self.output.error("The --fastq_type single parameter can not be used together with --strand_info RF  or --strand_info FR")
            exit()
        
        if self.args.paired_file1 and self.args.fastq_type != 'paired':
            self.output.error("The --paired_file1 parameter can only be used together with --fastq_type paired")
            exit()
        if self.args.paired_file2 and self.args.fastq_type != 'paired':
            self.output.error("The --paired_file2 parameter can only be used together with --fastq_type paired")
            exit()
        if self.args.paired_file1 and not self.args.paired_file2:
            self.output.error("The --paired_file2 parameter must be used together with --paired_file1")
            exit()
        if self.args.fastq_type == 'paired' and (self.args.strand_info == 'R' or self.args.strand_info == 'F'):
            self.output.error("The --fastq_type paired parameter can not be used together with --strand_info R  or --strand_info F")
            exit()

        if not self.args.samtools_path and self.args.unique == 'yes':
            self.output.error("The --samtools_path paired parameter must be used together with --unique yes")
            exit()
    def check_directory(self):
        """Check output directory."""
        self.output.info('Checking output directory.')
        self.output_str = self.args.output
        self.output_path = Path(f'{self.output_str}/tmp')
        if not self.output_path.is_dir():
            self.output.info('Creating output directory.')
            self.output_path.mkdir()
    def sra2fastq(self):
        hisat2_path = self.args.hisat2_path
        perl_path = self.args.perl_path
        index_path = self.args.index_path
        strand_info = self.args.strand_info
        fastq_type = self.args.fastq_type
        single_file = "No_input" if self.args.single_file is None else self.args.single_file
        paired_file1 = "No_input" if self.args.paired_file1 is None else self.args.paired_file1
        paired_file2 = "No_input" if self.args.paired_file2 is None else self.args.paired_file2
        min_intron_length = str(self.args.min_intron_length)
        max_intron_length = str(self.args.max_intron_length)
        mismatch = self.args.mismatch
        threads = str(self.args.threads)
        unique = self.args.unique
        output_path = self.args.output
        output_name = self.args.name
        samtools_path = self.args.samtools_path

        args = [
            f'{script_dir}/utils/1.alignment.sh',
            '-P', perl_path,
            '-H', hisat2_path,
            '-I', index_path,
            '-s', strand_info,
            '-p', fastq_type,
            '-u', single_file,
            '-l', paired_file1,
            '-r', paired_file2,
            '-i', min_intron_length,
            '-x', max_intron_length,
            '-m', mismatch,
            '-t', threads,
            '-U', unique,
            '-o', output_path,
            '-n', output_name,
            '-T', samtools_path
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
            self.output.error(f"Can not found file {script_dir}/utils/1.alignment.sh")

    def process(self):
        self.check_args()
        self.check_directory()
        self.output.info('Starting sra2fastq Process.')
        self.sra2fastq()
        self.output.info('Completed sra2fastq Process.')
