from logging import getLogger
from pathlib import Path
from multiprocessing import cpu_count, Pool

from PanGraphRNA.sys_output import Output
import subprocess


logger = getLogger(__name__)  # pylint: disable=invalid-name

class QualityControl(object):
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
        if self.args.single_adapter and self.args.fastq_type != 'single':
            self.output.error("The --single_adapter parameter can only be used together with --fastq_type single")
            exit()
        if self.args.single_file and self.args.fastq_type != 'single':
            self.output.error("The --single_file parameter can only be used together with --fastq_type single")
            exit()
        
        if self.args.paired_adapter1 and self.args.fastq_type != 'paired':
            self.output.error("The --paired_adapter1 parameter can only be used together with --fastq_type paired")
            exit()
        if self.args.paired_adapter2 and self.args.fastq_type != 'paired':
            self.output.error("The --paired_adapter2 parameter can only be used together with --fastq_type paired")
            exit()
        if self.args.paired_adapter1 and not self.args.paired_adapter2:
            self.output.error("The --paired_adapter2 parameter must be used together with --paired_adapter1")
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
        
    def check_directory(self):
        """Check output directory."""
        self.output.info('Checking output directory.')
        self.output_str = self.args.output
        self.output_path = Path(self.output_str)
        if not self.output_path.is_dir():
            self.output.info('Creating output directory.')
            self.output_path.mkdir()
    def quality_control(self):
        software_path = self.args.software
        output_path = self.args.output
        minread = str(self.args.minread)
        threads = str(self.args.threads)
        q_vaul = str(self.args.quality_value)
        name = str(self.args.name)
        file = ""
        file_R1 = ""
        file_R2 = ""
        adapter = ""
        adapter_R1 = ""
        adapter_R2 = ""
        script_path = f'{software_path}/fastp'
        if self.args.fastq_type == 'single':
            file = self.args.single_file
            if self.args.single_adapter:
                adapter = self.args.single_adapter
                try:
                    subprocess.run([script_path, '-w', threads, 
                                '-q', q_vaul, '-l', minread, '-i', file, '-a', adapter,
                                '-o', f'{output_path}/{name}_clean.fq.gz', '-h', f'{output_path}/{name}.html', 
                                '-j', f'{output_path}/{name}.json'],
                        capture_output=True,
                        text=True, 
                        check=True)
                except subprocess.CalledProcessError as e:
                    self.output.error(e.stderr)
            else:
                try:
                    subprocess.run([script_path, '-w', threads, 
                                '-q', q_vaul, '-l', minread, '-i', file,
                                '-o', f'{output_path}/{name}_clean.fq.gz', '-h', f'{output_path}/{name}.html', 
                                '-j', f'{output_path}/{name}.json'],
                        capture_output=True,
                        text=True, 
                        check=True)
                except subprocess.CalledProcessError as e:
                    self.output.error(e.stderr)
        else:
            file_R1 = self.args.paired_file1
            file_R2 = self.args.paired_file2
            if self.args.paired_adapter1:
                adapter_R1 = self.args.paired_adapter1
                adapter_R2 = self.args.paired_adapter2
                try:
                    subprocess.run([script_path, '-w', threads, 
                                '-q', q_vaul, '-l', minread, 
                                '-i', file_R1, '-o', f'{output_path}/{name}_clean_R1.fq.gz',
                                '-I', file_R2, '-O', f'{output_path}/{name}_clean_R2.fq.gz',
                                '-a', adapter_R1, '-A', adapter_R2,
                                '-h', f'{output_path}/{name}.html', 
                                '-j', f'{output_path}/{name}.json'],
                        capture_output=True,
                        text=True, 
                        check=True)
                except subprocess.CalledProcessError as e:
                    self.output.error(e.stderr)
            else:
                try:
                    subprocess.run([script_path, '-w', threads, 
                                '-q', q_vaul, '-l', minread, 
                                '-i', file_R1, '-o', f'{output_path}/{name}_clean_R1.fq.gz',
                                '-I', file_R2, '-O', f'{output_path}/{name}_clean_R2.fq.gz',
                                '--detect_adapter_for_pe',
                                '-h', f'{output_path}/{name}.html', 
                                '-j', f'{output_path}/{name}.json'],
                        capture_output=True,
                        text=True, 
                        check=True)
                except subprocess.CalledProcessError as e:
                    self.output.error(e.stderr)
        
    def process(self):
        self.check_args()
        self.check_directory()
        self.output.info('Starting Quality Control Process.')
        self.quality_control()
        self.output.info('Completed Quality Control Process.')
