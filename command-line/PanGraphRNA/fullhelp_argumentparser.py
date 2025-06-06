# -*- coding: utf-8 -*-
# Copyright 2022 Shang Xie.
# All rights reserved.
#
# This file is part of the CatMOD distribution and
# governed by your choice of the "CatMOD License Agreement"
# or the "GNU General Public License v3.0".
# Please see the LICENSE file that should
# have been included as part of this package.
"""Represent a full help argument parser and execute.

What's here:

Loads the relevant script modules and executes the script.
----------------------------------------------------------

Classes:
  - ScriptExecutor

Identical to the built-in argument parser.
------------------------------------------

Classes:
  - FullHelpArgumentParser

Smart formatter for allowing raw formatting in help
text and lists in the helptext.
---------------------------------------------------

Classes:
  - SmartFormatter

CatMOD argument parser functions.
----------------------------------

Classes:
  - CatMODArgs

Parse the sub-command line arguments.
-------------------------------------

Classes:
  - DPArgs
  - EFArgs
  - TrainArgs
  - PredictArgs
"""

from argparse import ArgumentParser, HelpFormatter
from importlib import import_module
from logging import getLogger
from os import getpid
from re import ASCII, compile
from sys import exit, stderr
from textwrap import wrap

from PanGraphRNA.sys_output import Output


logger = getLogger(__name__)  # pylint: disable=invalid-name


class ScriptExecutor(object):
    """Loads the relevant script modules and executes the script.

    This class is initialised in each of the argparsers for the relevant
    command, then execute script is called within their set_default function.

    Attributes:
      - command (str): Full commands.
      - subparsers: Subparsers for each subcommand.
      - output: Output info, warning and error.
    """

    def __init__(self, command: str, subparsers=None):
        """Initialize ScriptExecutor.
        Args:
          - command (str): Full commands.
          - subparsers: Subparsers for each subcommand.
        """
        self.command = command.lower()
        self.subparsers = subparsers
        self.output = Output()

    def import_script(self):
        """Only import a script's modules when running that script."""
        # cmd = os.path.basename(sys.argv[0])
        src = 'PanGraphRNA'
        mod = '.'.join((src, self.command.lower()))
        module = import_module(mod)
        script = getattr(module, self.command.title().replace('_', ''))
        return script

    def execute_script(self, arguments):
        """Run the script for called command."""
        self.output.info(f'Executing: {self.command}. PID: {getpid()}')
        logger.debug(f'Executing: {self.command}. PID: {getpid()}')
        try:
            script = self.import_script()
            process = script(arguments)
            process.process()
        except KeyboardInterrupt:  # pylint: disable=try-except-raise
            raise
        except SystemExit:
            pass
        except Exception:  # pylint: disable=broad-except
            logger.exception('Got Exception on main handler:')
            logger.critical(
                'An unexpected crash has occurred. '
                'Crash report written to logfile. '
                'Please verify you are running the latest version of PanGraphRNA '
                'before reporting.')
        finally:
            exit()


class FullHelpArgumentParser(ArgumentParser):
    """Identical to the built-in argument parser.

    On error it prints full help message instead of just usage information.
    """

    def error(self, message: str):
        """Print full help messages."""
        self.print_help(stderr)
        args = {'prog': self.prog, 'message': message}
        self.exit(2, f'{self.prog}: error: {message}\n')


class SmartFormatter(HelpFormatter):
    """Smart formatter for allowing raw formatting.

    Mainly acting in help text and lists in the helptext.

    To use: prefix the help item with 'R|' to overide
    default formatting. List items can be marked with 'L|'
    at the start of a newline.

    Adapted from: https://stackoverflow.com/questions/3853722
    """

    def __init__(self, prog: str,
                 indent_increment: int = 2,
                 max_help_position: int = 24,
                 width=None):
        """Initialize SmartFormatter.

        Args:
          - prog (str): Program name.
          - indent_increment (int): Indent increment. default 2.
          - max_help_position (int): Max help position. default 24.
          - width: Width.
        """
        super().__init__(prog, indent_increment, max_help_position, width)
        self._whitespace_matcher_limited = compile(r'[ \r\f\v]+', ASCII)

    def _split_lines(self, text: str, width):
        if text.startswith('R|'):
            text = self._whitespace_matcher_limited.sub(' ', text).strip()[2:]
            output = []
            for txt in text.splitlines():
                indent = ''
                if txt.startswith('L|'):
                    indent = '    '
                    txt = '  - {}'.format(txt[2:])
                output.extend(wrap(
                    txt, width, subsequent_indent=indent))
            return output
        return HelpFormatter._split_lines(self, text, width)


class PanGraphRNAArgs(object):
    """PanGraphRNA argument parser functions.

    It is universal to all commands.
    Should be the parent function of all subsequent argparsers.

    Attributes:
      - global_arguments: Global arguments.
      - argument_list: Argument list.
      - optional_arguments: Optional arguments.
      - parser: Parser.
    """

    def __init__(self, subparser, command: str,
                 description: str = 'default', subparsers=None):
        """Initialize CatmodArgs.

        Args:
          - subparser: Subparser.
          - command (str): Command.
          - description (str): Description. default 'default'.
          - subparsers: Subparsers.
        """
        self.global_arguments = self.get_global_arguments()
        self.argument_list = self.get_argument_list()
        self.optional_arguments = self.get_optional_arguments()
        if not subparser:
            return
        self.parser = self.create_parser(subparser, command, description)
        self.add_arguments()
        script = ScriptExecutor(command, subparsers)
        self.parser.set_defaults(func=script.execute_script)

    @staticmethod
    def get_argument_list():
        """Put the arguments in a list so that they are accessible."""
        argument_list = []
        return argument_list

    @staticmethod
    def get_optional_arguments():
        """Put the arguments in a list so that they are accessible.

        This is used for when there are sub-children.
        (e.g. convert and extract) Override this for custom arguments.
        """
        argument_list = []
        return argument_list

    @staticmethod
    def get_global_arguments():
        """Arguments that are used in ALL parts of CatMOD.

        DO NOT override this!
        """
        global_args = []
        global_args.append({'opts': ('-v', '--version'),
                            'action': 'version',
                            'version': 'PanGraphRNA v1.0'})
        return global_args

    @staticmethod
    def create_parser(subparser, command: str, description: str):
        """Create the parser for the selected command."""
        parser = subparser.add_parser(
            command,
            help=description,
            description=description,
            epilog='Questions and feedback: '
                   'https://github.com/cma2015/PanGraphRNA',
            formatter_class=SmartFormatter)
        return parser

    def add_arguments(self):
        """Parse the arguments passed in from argparse."""
        options = (self.global_arguments + self.argument_list +
                   self.optional_arguments)
        for option in options:
            args = option['opts']
            kwargs = {key: option[key]
                      for key in option.keys() if key != 'opts'}
            self.parser.add_argument(*args, **kwargs)


class SRAArgs(PanGraphRNAArgs):
    """."""

    @staticmethod
    def get_argument_list():
        """Put the arguments in a list so that they are accessible."""
        argument_list = []
        argument_list.append({
            'opts': ('-s', '--software_path'),
            'dest': 'software',
            'required': True,
            'type': str,
            'help': 'fastq-dump folder path.'
        })
        argument_list.append({
            'opts': ('-i', '--input'),
            'dest': 'input',
            'required': True,
            'type': str,
            'help': 'input folder path.'})
        argument_list.append({
            'opts': ('-m', '--minread'),
            'dest': 'minread',
            'default': 20,
            'type': int,
            'help': 'The minimum reads length, default is 20.'})
        argument_list.append({
            'opts': ('-o', '--output'),
            'dest': 'output',
            'required': True,
            'type': str,
            'help': 'output folder path.'})
        return argument_list


class QCArgs(PanGraphRNAArgs):
    """."""

    @staticmethod
    def get_argument_list():
        """Put the arguments in a list so that they are accessible."""
        argument_list = []
        argument_list.append({
            'opts': ('-s', '--software_path'),
            'dest': 'software',
            'required': True,
            'type': str,
            'help': 'fastp folder path.'
        })
        argument_list.append({
            'opts': ('-m', '--minread'),
            'dest': 'minread',
            'default': 20,
            'type': int,
            'help': 'The minimum reads length, default is 20.'})
        argument_list.append({
            'opts': ('-q', '--quality_value'),
            'dest': 'quality_value',
            'default': 15,
            'type': int,
            'help': 'The quality value that a base is qualified, default is 15.'})
        argument_list.append({
            'opts': ('-f', '--fastq_type'),
            'dest': 'fastq_type',
            'required': True,
            'type': str,
            'choices': ['single', 'paired'],
            'help': 'Single-end or paired-end reads, [single, paired].'})
        argument_list.append({
            'opts': ('-R', '--single_file'),
            'dest': 'single_file',
            'type': str,
            'help': 'The single-end fastq. Required if single-end reads.'})
        argument_list.append({
            'opts': ('-R1', '--paired_file1'),
            'dest': 'paired_file1',
            'type': str,
            'help': 'The paired-end fastq R1. Required if paired-end reads.'})
        argument_list.append({
            'opts': ('-R2', '--paired_file2'),
            'dest': 'paired_file2',
            'type': str,
            'help': 'The paired-end fastq R2. Required if paired-end reads.'})
        argument_list.append({
            'opts': ('-sa', '--single_adapter'),
            'dest': 'single_adapter',
            'type': str,
            'help': 'The single-end adapter sequence.'})
        argument_list.append({
            'opts': ('-pA', '--paired_adapter1'),
            'dest': 'paired_adapter1',
            'type': str,
            'help': 'The paired-end adapter sequence1.'})
        argument_list.append({
            'opts': ('-pa', '--paired_adapter2'),
            'dest': 'paired_adapter2',
            'type': str,
            'help': 'The paired-end adapter sequence2.'})
        argument_list.append({
            'opts': ('-t', '--threads'),
            'dest': 'threads',
            'default': 15,
            'type': int,
            'help': 'Worker thread number, default is 15.'})
        argument_list.append({
            'opts': ('-o', '--output'),
            'dest': 'output',
            'required': True,
            'type': str,
            'help': 'output folder path.'})
        argument_list.append({
            'opts': ('-n', '--name'),
            'dest': 'name',
            'required': True,
            'type': str,
            'help': 'output file name path.'})
        return argument_list


class GPCArgs(PanGraphRNAArgs):
    """."""

    @staticmethod
    def get_argument_list():
        """Put the arguments in a list so that they are accessible."""
        argument_list = []
        argument_list.append({
            'opts': ('-bcf', '--bcf_path'),
            'dest': 'bcf_path',
            'required': True,
            'type': str,
            'help': 'bcftools folder path.'
        })
        argument_list.append({
            'opts': ('-hisat2', '--hisat2_path'),
            'dest': 'hisat2_path',
            'required': True,
            'type': str,
            'help': 'hisat2 folder path.'
        })
        argument_list.append({
            'opts': ('-rpath', '--r_path'),
            'dest': 'r_path',
            'required': True,
            'type': str,
            'help': 'R folder path.'
        })
        argument_list.append({
            'opts': ('-f', '--fasta'),
            'dest': 'fasta',
            'required': True,
            'type': str,
            'help': 'Input reference genome file.'})
        argument_list.append({
            'opts': ('-i', '--vcf'),
            'dest': 'vcf',
            'required': True,
            'type': str,
            'help': 'Input VCF file containing variant information.'})
        argument_list.append({
            'opts': ('-m', '--method'),
            'dest': 'method',
            'required': True,
            'type': str,
            'choices': ['Individual', 'Subpopulation', 'Population'],
            'help': 'Select method to construct graph pangenome, [Individual, Subpopulation, Population].'})
        argument_list.append({
            'opts': ('-a', '--accession'),
            'dest': 'accession',
            'type': str,
            'help': 'Input accession name available in the VCF file to specify the variant information. Required if -m Individual.'})
        argument_list.append({
            'opts': ('-al', '--accession_list'),
            'dest': 'accession_list',
            'type': str,
            'help': 'Input accession name list (TXT file) available in the VCF file to specify the variant information. Required if -m Subpopulation.'})
        argument_list.append({
            'opts': ('-g', '--gtf'),
            'dest': 'gtf',
            'type': str,
            'help': 'Input the gtf file.'})
        argument_list.append({
            'opts': ('-t', '--threads'),
            'dest': 'threads',
            'default': 15,
            'type': int,
            'help': 'Worker thread number, default is 15.'})
        argument_list.append({
            'opts': ('-o', '--output'),
            'dest': 'output',
            'required': True,
            'type': str,
            'help': 'output folder path.'})
        argument_list.append({
            'opts': ('-n', '--name'),
            'dest': 'name',
            'required': True,
            'type': str,
            'help': 'output file name path.'})

        return argument_list


class AlignmentArgs(PanGraphRNAArgs):
    """."""

    @staticmethod
    def get_argument_list():
        """Put the arguments in a list so that they are accessible."""
        argument_list = []
        argument_list.append({
            'opts': ('-hisat2', '--hisat2_path'),
            'dest': 'hisat2_path',
            'required': True,
            'type': str,
            'help': 'hisat2 folder path.'
        })
        argument_list.append({
            'opts': ('-perl', '--perl_path'),
            'dest': 'perl_path',
            'required': True,
            'type': str,
            'help': 'perl folder path.'
        })
        argument_list.append({
            'opts': ('-index', '--index_path'),
            'dest': 'index_path',
            'required': True,
            'type': str,
            'help': 'index files path.'})
        argument_list.append({
            'opts': ('-strand', '--strand_info'),
            'dest': 'strand_info',
            'required': True,
            'type': str,
            'choices': ['unstranded', 'RF', 'FR', 'R', 'F'],
            'help': 'specify strand-specific information (unstranded)'})
        argument_list.append({
            'opts': ('-f', '--fastq_type'),
            'dest': 'fastq_type',
            'required': True,
            'type': str,
            'choices': ['single', 'paired'],
            'help': 'Single-end or paired-end reads, [single, paired].'})
        argument_list.append({
            'opts': ('-R', '--single_file'),
            'dest': 'single_file',
            'type': str,
            'help': 'The single-end fastq. Required if single-end reads.'})
        argument_list.append({
            'opts': ('-R1', '--paired_file1'),
            'dest': 'paired_file1',
            'type': str,
            'help': 'The paired-end fastq R1. Required if paired-end reads.'})
        argument_list.append({
            'opts': ('-R2', '--paired_file2'),
            'dest': 'paired_file2',
            'type': str,
            'help': 'The paired-end fastq R2. Required if paired-end reads.'})
        argument_list.append({
            'opts': ('-m', '--min_intron_length'),
            'dest': 'min_intron_length',
            'default': 20,
            'type': int,
            'help': 'minimum intron length (20).'})
        argument_list.append({
            'opts': ('-M', '--max_intron_length'),
            'dest': 'min_intron_length',
            'default': 500000,
            'type': int,
            'help': 'maximum intron length (500000).'})
        argument_list.append({
            'opts': ('-mis', '--mismatch'),
            'dest': 'mismatch',
            'default': "9,3",
            'type': str,
            'help': 'max and min penalties for mismatch; lower qual = lower penalty <9,3>.'})
        argument_list.append({
            'opts': ('-u', '--unique'),
            'dest': 'unique',
            'default': "no",
            'type': str,
            'choices': ['yes', 'no'],
            'help': 'Extract uniquely mapped reads, default is yes.'})
        argument_list.append({
            'opts': ('-t', '--threads'),
            'dest': 'threads',
            'default': 15,
            'type': str,
            'help': 'Worker thread number, default is 15.'})
        argument_list.append({
            'opts': ('-samtools', '--samtools_path'),
            'dest': 'samtools_path',
            'type': str,
            'help': 'samtools folder path, required if -u yes.'})
        argument_list.append({
            'opts': ('-o', '--output'),
            'dest': 'output',
            'required': True,
            'type': str,
            'help': 'output folder path.'})
        argument_list.append({
            'opts': ('-n', '--name'),
            'dest': 'name',
            'required': True,
            'type': str,
            'help': 'output file name path.'})
        return argument_list

class AlignmentStatisticsArgs(PanGraphRNAArgs):
    """."""
    @staticmethod
    def get_argument_list():
        argument_list = []
        argument_list.append({
            'opts': ('-input', '--input_path'),
            'dest': 'input_path',
            'required': True,
            'type': str,
            'help': 'Input alignment summary files list(contains path) in TXT format.'})
        argument_list.append({
            'opts': ('-o', '--output'),
            'dest': 'output',
            'required': True,
            'type': str,
            'help': 'output folder path.'})
        argument_list.append({
            'opts': ('-n', '--name'),
            'dest': 'name',
            'required': True,
            'type': str,
            'help': 'output file name path.'})
        return argument_list
    
class ExpressionQuantificationArgs(PanGraphRNAArgs):
    """."""
    @staticmethod
    def get_argument_list():
        argument_list = []
        argument_list.append({
            'opts': ('-input', '--input_path'),
            'dest': 'input_path',
            'required': True,
            'type': str,
            'help': 'Input RNA-Seq alignment results (BAM file) list.'})
        argument_list.append({
            'opts': ('-samtools', '--samtools_path'),
            'dest': 'samtools_path',
            'required': True,
            'type': str,
            'help': 'samtools folder path.'})
        argument_list.append({
            'opts': ('-stringtie', '--stringtie_path'),
            'dest': 'stringtie_path',
            'required': True,
            'type': str,
            'help': 'stringtie folder path.'})
        argument_list.append({
            'opts': ('-rpath', '--r_path'),
            'dest': 'r_path',
            'required': True,
            'type': str,
            'help': 'R folder path.'
        })
        argument_list.append({
            'opts': ('-o', '--output'),
            'dest': 'output',
            'required': True,
            'type': str,
            'help': 'output folder path.'})
        argument_list.append({
            'opts': ('-t', '--threads'),
            'dest': 'threads',
            'default': 15,
            'type': int,
            'help': 'Worker thread number, default is 15.'})
        return argument_list

class DifferentialExpressionArgs(PanGraphRNAArgs):
    """."""
    @staticmethod
    def get_argument_list():
        argument_list = []
        argument_list.append({
            'opts': ('-input', '--input_path'),
            'dest': 'input_path',
            'required': True,
            'type': str,
            'help': 'Input read count matrix path.'})
        argument_list.append({
            'opts': ('-rpath', '--r_path'),
            'dest': 'r_path',
            'required': True,
            'type': str,
            'help': 'R folder path.'
        })
        argument_list.append({
            'opts': ('-c', '--CG'),
            'dest': 'CG',
            'type': int,
            'default': 3,
            'help': 'The number of CG (Control Group).'})
        argument_list.append({
            'opts': ('-e', '--EG'),
            'dest': 'EG',
            'type': int,
            'default': 3,
            'help': 'The number of EG (Experimental Group).'})
        argument_list.append({
            'opts': ('-o', '--output'),
            'dest': 'output',
            'required': True,
            'type': str,
            'help': 'output folder path.'})
        argument_list.append({
            'opts': ('-n', '--name'),
            'dest': 'name',
            'required': True,
            'type': str,
            'help': 'output file name path.'})
        return argument_list

class QuantitativeTraitLocusArgs(PanGraphRNAArgs):
    """."""
    @staticmethod
    def get_argument_list():
        argument_list = []
        argument_list.append({
            'opts': ('-vg', '--variation_genotype'),
            'dest': 'variation_genotype',
            'required': True,
            'type': str,
            'help': 'Input variation genotype file (TXT file).'})
        argument_list.append({
            'opts': ('-vcoordinate', '--variation_coordinate'),
            'dest': 'variation_coordinate',
            'required': True,
            'type': str,
            'help': 'Input variation coordinate file (TXT file).'})
        argument_list.append({
            'opts': ('-vcovariates', '--variation_covariates'),
            'dest': 'variation_covariates',
            'required': True,
            'type': str,
            'help': 'Input variation covariates file (TXT file).'})
        argument_list.append({
            'opts': ('-gem', '--gene_expression'),
            'dest': 'gene_expression',
            'required': True,
            'type': str,
            'help': 'Input gene expression file (TXT file).'})
        argument_list.append({
            'opts': ('-gc', '--gene_coordinate'),
            'dest': 'gene_coordinate',
            'required': True,
            'type': str,
            'help': 'Input gene coordinate file (TXT file).'})
        argument_list.append({
            'opts': ('-fdr', '--FDR'),
            'dest': 'FDR',
            'default': 0.05,
            'type': float,
            'help': 'Threshold of False Discovery Rate (FDR).'})
        argument_list.append({
            'opts': ('-rpath', '--r_path'),
            'dest': 'r_path',
            'required': True,
            'type': str,
            'help': 'R folder path.'
        })
        argument_list.append({
            'opts': ('-o', '--output'),
            'dest': 'output',
            'required': True,
            'type': str,
            'help': 'output folder path.'})
        return argument_list