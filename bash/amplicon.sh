#!/bin/bash


function logmsg {
  echo "[$(date -R)]: $1"
}

if [ $# -eq 0 ]
then
    echo -e "\n$0 options
    -m/--manifest: input manifest file in TSV format
    -s/--sample_metadata: input sample metadata file in TSV format
    -q/--trunc_q: qulity score threshold for trimming
    -r/--reference_reads: input reference reads file for classification
    -t/--reference_taxonomy: input reference taxonomy for classification
    -a/--max_accepts: max accepts paramenter for classification
    -d/--sampling_depth: sampling depth paramenter form normalization
    -o/--output_dir: output directory
    "
    exit 1
fi


# -----------------------
manifest_file=''
sample_metadata=''
trunc_q=''
reference_reads_file=''
reference_taxonomy_file=''
max_accepts=''
sampling_depth=''
output_dir=''

short="m:s:q:r:t:a:d:o:"
long="manifest:,sample_metadata:,trunc_q:reference_reads:,"
long=${long}"reference_taxonomy:,max_accepts:,sampling_depth:,output_dir:,"
OPTS=$(getopt -o ${short} -l ${long} -- "$@")
eval set -- "$OPTS"

while [ $# -gt 0 ] ; do
    case "$1"
    in
        -m|--manifest) manifest_file=$2; shift;;
        -s|--sample_metadata) sample_metadata=$2; shift;;
        -q|--trunc_q) trunc_q=$2; shift;;
        -r|--reference_reads) reference_reads_file=$2; shift;;
        -t|--reference_taxonomy) reference_taxonomy_file=$2; shift;;
        -a|--max_accepts) max_accepts=$2; shift;;
        -d|--sampling_depth) sampling_depth=$2; shift;;
        -o|--output_dir) output_dir=$2; shift;;
        (--) shift; break;;
    esac
    shift
done

if ! test -f ${manifest_file} ; then
  echo "Error with manifest file: no such file or directory"
  exit 1
fi

if ! test -f ${sample_metadata} ; then
  echo "Error with metadata file: no such file or directory"
  exit 1
fi

if ! test -f ${reference_reads} ; then
  echo "Error with reference reads file: no such file or directory"
  exit 1
fi

if ! test -f ${reference_taxonomy} ; then
  echo "Error with reference taxonomy file: no such file or directory"
  exit 1
fi

mkdir -p ${output_dir}
log_stdout=${output_dir}/analysis.out.log
log_stderr=${output_dir}/analysis.err.log

# Fixed paramenters
IMPORT_TYPE="SampleData[PairedEndSequencesWithQuality]"
IMPORT_FORMAT="PairedEndFastqManifestPhred33V2"
TRIM_LEFT_F=0
TRIM_LEFT_R=0
TRUNC_LEN_F=0
TRUNC_LEN_R=0

# Filenames
imported_sequences_artifact=${output_dir}/imported-sequences.qza
repr_seq_artifact=${output_dir}/dada2-rep_seq.qza
otu_table_artifact=${output_dir}/dada2-table.qza
denoise_stat_artifact=${output_dir}/dada2-stats.qza
denoise_stat_visualization_artifact=${output_dir}/dada2-stats.qzv
taxonomy_artifact=${output_dir}/taxonomy.qza
taxonomy_visualization_artifact=${output_dir}/taxonomy.qzv
taxa_barplot_artifact=${output_dir}/taxa-barplot.qzv
aligned_repr_seq_artifact=${output_dir}/aligned-rep-seqs.qza
masked_repr_seq_artifact=${output_dir}/masked-aligned-rep-seqs.qza
unrooted_tree_artifact=${output_dir}/unrooted-tree.qza
rooted_tree_artifact=${output_dir}/rooted-tree.qza
core_metrics_output_directory=${output_dir}/core-metrics-results

# Qiime2 tools shortcuts
q2import="qiime tools import"
q2dada="qiime dada2 denoise-paired"
q2tabulate="qiime metadata tabulate"
q2classify="qiime feature-classifier classify-consensus-vsearch"
q2barplot="qiime taxa barplot"
q2mafft="qiime alignment mafft"
q2mask="qiime alignment mask"
q2fasttree="qiime phylogeny fasttree"
q2midpoint="qiime phylogeny midpoint-root"
q2diversity="qiime diversity core-metrics-phylogenetic"

# Step 0: importing paired-end data from manifest v2 file
# Input:
# - manifest file
# - import type: [SampleData[PairedEndSequencesWithQuality]
# - import format: "PairedEndFastqManifestPhred33V2"
# Output:
# - imported sequence artifact (imported-sequences.qza)
logmsg 'Step0: Importing data...'
${q2import} --input-path ${manifest_file} \
            --output-path ${imported_sequences_artifact} \
            --type ${IMPORT_TYPE} \
            --input-format ${IMPORT_FORMAT} \
            1> ${log_stdout} 2> ${log_stderr}
logmsg 'Step0: done.'

# Step 1.1: running dada2 denoising on imported sequences
# Input:
# - imported sequence artifact
# - trim_left_f, trim_left_r: 0, 0 (no trim left)
# - trunc_len_f, trunc_len_r: 0, 0 (no trunc len)
# - trun_q
# Output:
# - representative sequences artifact (dada2-rep_seq.qza)
# - otu table artifact (dada2-table.qza)
# - denoising stat artifact (dada2-stats.qza)
logmsg 'Step1: Denoising data...'
${q2dada} --i-demultiplexed-seqs ${imported_sequences_artifact} \
          --p-trim-left-f ${TRIM_LEFT_F} \
          --p-trim-left-r ${TRIM_LEFT_R} \
          --p-trunc-len-f ${TRUNC_LEN_F} \
          --p-trunc-len-r ${TRUNC_LEN_R} \
          --p-trunc-q ${trunc_q} \
          --o-representative-sequences ${repr_seq_artifact} \
          --o-table ${otu_table_artifact} \
          --o-denoising-stats ${denoise_stat_artifact} \
          1> ${log_stdout} 2> ${log_stderr}
# Step 1.2: tabulating denoise statistics for visualization
# Input:
# - denoising stat artifact
# Output:
# - denoisinf stat visualization artifact (dada2-stats.qzv)
${q2tabulate} --m-input-file ${denoise_stat_artifact} \
              --o-visualization ${denoise_stat_visualization_artifact} \
              1> ${log_stdout} 2> ${log_stderr}
logmsg 'Step1: done.'
# Step 2.1: taxonomic classification of ASV using consensus vsearch
# Input:
# - representative sequences artifact
# - reference reads file
# - reference taxonmy file
# - max accepts
# Output:
# - taxonomy artifact (taxonomy.qza)
logmsg 'Step2: Taxonomic classification...'
${q2classify} --i-query ${repr_seq_artifact} \
              --i-reference-reads ${reference_reads_file} \
              --i-reference-taxonomy ${reference_taxonomy_file} \
              --o-classification ${taxonomy_artifact} \
              --p-maxaccepts ${max_accepts} \
              1> ${log_stdout} 2> ${log_stderr}
# Step 2.2: visualization of the taxonomy artifact
# Input:
# - taxonomy artifact
# Output:
# - taxonomy visualization artifact (taxonomy.qzv)
${q2tabulate} --m-input-file ${taxonomy_artifact} \
              --o-visualization ${taxonomy_visualization_artifact} \
              1> ${log_stdout} 2> ${log_stderr}
# Step 2.3: creating taxonomy bar plot
# Input:
# - otu table artifact
# - taxonomy artifact
# - sample metadata
# Output:
# - taxa barplot artifact (taxa-barplot.qzv)
${q2barplot} --i-table ${otu_table_artifact} \
             --i-taxonomy ${taxonomy_artifact} \
             --m-metadata-file ${sample_metadata} \
             --o-visualization ${taxa_barplot_artifact} \
             1> ${log_stdout} 2> ${log_stderr}
logmsg 'Step2: done.'
# Step 3.1: building ASV multiple sequence alignment using MAFFT
# Input:
# - representative sequences artifact
# Output:
# - aligned sequences artifact (aligned-rep-seqs.qza)
logmsg 'Step3: Phylogenitic analysis...'
${q2mafft} --i-sequences ${repr_seq_artifact} \
           --o-alignment ${aligned_repr_seq_artifact} \
           1> ${log_stdout} 2> ${log_stderr}
# Step 3.2: masking MSA for highgly-variable positions
# Input:
# - aligned sequences artifact
# Output:
# - masked alignment sequences artifact (masked-aligned-rep-seqs.qza)
${q2mask} --i-alignment ${aligned_repr_seq_artifact} \
          --o-masked-alignment ${masked_repr_seq_artifact} \
          1> ${log_stdout} 2> ${log_stderr}
# Step 3.3: building the phylogenitc tree using FastTree
# Input:
# - masked alignment sequences artifact
# Output:
# - unrooted tree artifact (unrooted-tree.qza)
${q2fasttree} --i-alignment ${masked_repr_seq_artifact} \
              --o-tree ${unrooted_tree_artifact} \
              1> ${log_stdout} 2> ${log_stderr}
# Step 3.4: setting the tree root using midpoint-root placement
# Input:
# - unrooted tree artifact
# Output:
# - rooted tree artifact (rooted-tree.qza)
${q2midpoint} --i-tree ${unrooted_tree_artifact} \
              --o-rooted-tree ${rooted_tree_artifact} \
              1> ${log_stdout} 2> ${log_stderr}
logmsg 'Step3: done.'
# Step 4: computing alpha and beta diversity metrics
# Input:
# - rooted tree artifact
# - otu table artifact
# - sample metadata
# - sampling depth
# Output:
# - core metrics output directory (core-metrics-results)
logmsg 'Step4: Diversity analysis...'
${q2diversity} --i-phylogeny ${rooted_tree_artifact} \
               --i-table ${otu_table_artifact} \
               --m-metadata-file ${sample_metadata} \
               --p-sampling-depth ${sampling_depth} \
               --output-dir ${core_metrics_output_directory} \
               1> ${log_stdout} 2> ${log_stderr}
logmsg 'Step4: done.'
