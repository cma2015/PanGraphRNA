from logging import getLogger
from pathlib import Path
import re, csv, sys, os, glob, warnings, itertools
from PanGraphRNA.sys_output import Output
import subprocess
from math import ceil
from optparse import OptionParser
from operator import itemgetter

script_path = os.path.join(os.getcwd(), __file__)
script_dir = os.path.dirname(script_path)
logger = getLogger(__name__)  # pylint: disable=invalid-name
RE_GENE_ID=re.compile('gene_id "([^"]+)"')
RE_GENE_NAME=re.compile('gene_name "([^"]+)"')
RE_TRANSCRIPT_ID=re.compile('transcript_id "([^"]+)"')
RE_COVERAGE=re.compile('cov "([\-\+\d\.]+)"')
RE_STRING=re.compile(re.escape("MSTRG"))
RE_GFILE=re.compile('\-G\s*(\S+)') #assume filepath without spaces..
def is_transcript(x):
  return len(x)>2 and x[2]=="transcript"

def getGeneID(s, ctg, tid):
  r=RE_GENE_ID.search(s)
  #if r: return r.group(1)
  rn=RE_GENE_NAME.search(s)
  #if rn: return ctg+'|'+rn.group(1)
  if r:
    if rn: 
      return r.group(1)+'|'+rn.group(1)
    else:
      return r.group(1)
  return tid

def getCov(s):
  r=RE_COVERAGE.search(s)
  if r:
    v=float(r.group(1))
    if v<0.0: v=0.0
    return v
  return 0.0

def is_overlap(x,y): #NEEDS TO BE INTS!
  return x[0]<=y[1] and y[0]<=x[1]


def t_overlap(t1, t2): #from badGenes: chromosome, strand, cluster, start, end, (e1start, e1end)...
    if t1[0] != t2[0] or t1[1] != t2[1] or t1[5]<t2[4]: return False
    for i in range(6, len(t1)):
        for j in range(6, len(t2)):
            if is_overlap(t1[i], t2[j]): return True
    return False

class ExpressionQuantification(object):
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
            Path(f'{self.output_str}/gene_exp').mkdir()
            Path(f'{self.output_str}/trans_exp').mkdir()
            
    def expression_quantification(self):
        input_path = self.args.input
        output_path = self.args.output
        r_path = self.args.r_path
        samtools_path = self.args.samtools_path
        stringtie_path = self.args.stringtie_path
        annotation_file = self.args.annotation_file
        threads  = str(self.args.threads)

        args = [
            f'{script_dir}/utils/5.quantification.sh',
            '-i', input_path,
            '-s', samtools_path,
            '-S', stringtie_path,
            '-t', threads,
            '-o', output_path,
            '-r', r_path,
            '-G', annotation_file,
            '-W',f'{script_dir}/utils'
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
            self.output.error(f"Can not found file {script_dir}/utils/5.quantification.sh")

    def process(self):
        self.check_directory()
        self.output.info('Starting Alignment Statistics Process.')
        self.expression_quantification()
        self.output.info('Completed Alignment Statistics Process.')
