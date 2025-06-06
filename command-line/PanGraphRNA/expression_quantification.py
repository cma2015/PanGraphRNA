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
            
    def differential_expression(self):
        input_path = self.args.input_path
        output_path = self.args.output_path
        r_path = self.args.r_path
        samtools_path = self.args.samtools_path
        stringtie_path = self.args.stringtie_path
        threads  = self.args.threads

        args = [
            f'{script_dir}/utils/5.quantification.sh',
            '-i', input_path,
            '-s', samtools_path,
            '-S', stringtie_path,
            '-t', threads,
            '-o', output_path,
            '-r', r_path,            
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
        samples = []
        try:
            fin = open(f'{output_path}/prepDE_input.txt', 'r')
            for line in fin:
                if line[0] != '#':
                    lineLst = tuple(line.strip().split(None,2))
                    if (len(lineLst) != 2):
                        print("Error: line should have a sample ID and a file path:\n%s" % (line.strip()))
                        exit(1)
                    if lineLst[0] in samples:
                        print("Error: non-unique sample ID (%s)" % (lineLst[0]))
                        exit(1)
                    if not os.path.isfile(lineLst[1]):
                        print("Error: GTF file not found (%s)" % (lineLst[1]))
                        exit(1)
                    samples.append(lineLst)
        except IOError:
            print("Error: List of .gtf files, %s, doesn't exist" % (output_path))
            exit(1)
        samples.sort()
        read_len=75
        t_count_matrix, g_count_matrix=[],[]
        geneIDs={}
        for s in samples:
            badGenes=[] #list of bad genes (just ones that aren't MSTRG)
            try:
        
                with open(s[1]) as f:
                    split=[l.split('\t') for l in f.readlines()]

        ## i = numLine; v = corresponding i-th GTF row
                for i,v in enumerate(split):
                    if is_transcript(v):
                        try:
                            t_id=RE_TRANSCRIPT_ID.search(v[8]).group(1)
                            g_id=getGeneID(v[8], v[0], t_id)
                        except:
                            print("Problem parsing file %s at line:\n:%s\n" % (s[1], v))
                            sys.exit(1)
                        geneIDs.setdefault(t_id, g_id)
                        if not RE_STRING.match(g_id):
                            badGenes.append([v[0],v[6], t_id, g_id, min(int(v[3]),int(v[4])), max(int(v[3]),int(v[4]))]) #chromosome, strand, cluster/transcript id, start, end
                            j=i+1
                            while j<len(split) and split[j][2]=="exon":
                                badGenes[len(badGenes)-1].append((min(int(split[j][3]), int(split[j][4])), max(int(split[j][3]), int(split[j][4]))))
                                j+=1

            except StopIteration:
                warnings.warn("Didn't get a GTF in that directory. Looking in another...")

            else: #we found the "bad" genes!
                break
        geneDict={} #key=gene/cluster, value=dictionary with key=sample, value=summed counts
        t_dict={}
        guidesFile='' # file given with -G for the 1st sample
        for q, s in enumerate(samples):
            lno=0
            try:
       
                f = open(s[1])
                transcript_len=0
        
                for l in f:
                    lno+=1
                    if l.startswith('#'):
                        if lno==1:
                            ei=l.find('-e')
                            if ei<0:
                                print("Error: sample file %s was not generated with -e option!" % ( s[1] ))
                                sys.exit(1)
                            gf=RE_GFILE.search(l)
                            if gf:
                                gfile=gf.group(1)
                                if guidesFile:
                                    if gfile != guidesFile:
                                        print("Warning: sample file %s generated with a different -G file (%s) than the first sample (%s)" % ( s[1], gfile, guidesFile ))
                                else:
                                    guidesFile=gfile
                            else:
                                print("Error: sample %s was not processed with -G option!" % ( s[1] ))
                                sys.exit(1)
                        continue
                    v=l.split('\t')
                    if v[2]=="transcript":
                        if transcript_len>0:
##                        transcriptList.append((g_id, t_id, int(ceil(coverage*transcript_len/read_len))))
                            t_dict.setdefault(t_id, {})
                            t_dict[t_id].setdefault(s[0], int(ceil(coverage*transcript_len/read_len)))
                        t_id=RE_TRANSCRIPT_ID.search(v[len(v)-1]).group(1)
                        #g_id=RE_GENE_ID.search(v[len(v)-1]).group(1)
                        g_id=getGeneID(v[8], v[0], t_id)
                        #coverage=float(RE_COVERAGE.search(v[len(v)-1]).group(1))
                        coverage=getCov(v[8])
                        transcript_len=0
                    if v[2]=="exon":
                        transcript_len+=int(v[4])-int(v[3])+1 #because end coordinates are inclusive in GTF

##                  transcriptList.append((g_id, t_id, int(ceil(coverage*transcript_len/read_len))))
                t_dict.setdefault(t_id, {})
                t_dict[t_id].setdefault(s[0], int(ceil(coverage*transcript_len/read_len)))

            except StopIteration:

                warnings.warn("No GTF file found in " + s[1])


    
            for i,v in t_dict.items():
##        print i,v
                try:
                    geneDict.setdefault(geneIDs[i],{}) #gene_id
                    geneDict[geneIDs[i]].setdefault(s[0],0)
                    geneDict[geneIDs[i]][s[0]]+=v[s[0]]
                except KeyError:
                    print("Error: could not locate transcript %s entry for sample %s" % ( i, s[0] ))
                raise
        with open(f'{output_path}/readcount_trans_stringtie.csv', 'w') as csvfile:
            my_writer = csv.DictWriter(csvfile, fieldnames = ["transcript_id"] + [x for x,y in samples])
            my_writer.writerow(dict((fn,fn) for fn in my_writer.fieldnames))
            for i in t_dict:
                t_dict[i]["transcript_id"] = i
                my_writer.writerow(t_dict[i])
        with open(f'{output_path}/readcount_gene_stringtie.csv', 'w') as csvfile:
            my_writer = csv.DictWriter(csvfile, fieldnames = ["gene_id"] + [x for x,y in samples])
            my_writer.writerow(dict((fn,fn) for fn in my_writer.fieldnames))
            for i in geneDict:
                geneDict[i]["gene_id"] = i #add gene_id to row
                my_writer.writerow(geneDict[i])
    def process(self):
        self.check_directory()
        self.output.info('Starting Alignment Statistics Process.')
        self.differential_expression()
        self.output.info('Completed Alignment Statistics Process.')
