#!/bin/bash


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

short="m:s:q:r:t:a:d:"
long="manifest:,sample_metadata:,trunc_q:reference_reads:,"
long=${long}"reference_taxonomy:,max_accepts:,sampling_depth:,"
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

# Fixed paramenters
IMPORT_TYPE="SampleData[PairedEndSequencesWithQuality]"
IMPORT_FORMAT="PairedEndFastqManifestPhred33V2"
TRIM_LEFT_F=0
TRIM_LEFT_R=0
TRUNC_LEN_F=0
TRUNC_LEN_R=0

# Filenames
imported_sequences_artifact=imported-sequences.qza
repr_seq_artifact=dada2-rep_seq.qza
otu_table_artifact=dada2-table.qza
denoise_stat_artifact=dada2-stats.qza
denoise_stat_visualization_artifact=dada2-stats.qzv
taxonomy_artifact=taxonomy.qza
taxonomy_visualization_artifact=taxonomy.qzv
taxa_barplot_artifact=taxa-barplot.qzv
aligned_repr_seq_artifact=aligned-rep-seqs.qza
masked_repr_seq_artifact=masked-aligned-rep-seqs.qza
unrooted_tree_artifact=unrooted-tree.qza
rooted_tree_artifact=rooted-tree.qza
core_metrics_output_directory=core-metrics-results

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
#${q2import} --input-path ${manifest_file} \
#            --output-path ${imported_sequences_artifact} \
#            --type ${IMPORT_TYPE} \
#            --input-format ${IMPORT_FORMAT}

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
#${q2dada} --i-demultiplexed-seqs ${imported_sequences_artifact} \
#          --p-trim-left-f ${TRIM_LEFT_F} \
#          --p-trim-left-r ${TRIM_LEFT_R} \
#          --p-trunc-len-f ${TRUNC_LEN_F} \
#          --p-trunc-len-r ${TRUNC_LEN_R} \
#          --p-trunc-q ${trunc_q} \
#          --o-representative-sequences ${repr_seq_artifact} \
#          --o-table ${otu_table_artifact} \
#          --o-denoising-stats ${denoise_stat_artifact}
# Step 1.2: tabulating denoise statistics for visualization
# Input:
# - denoising stat artifact
# Output:
# - denoisinf stat visualization artifact (dada2-stats.qzv)
${q2tabulate} --m-input-file ${denoise_stat_artifact} \
              --o-visualization ${denoise_stat_visualization_artifact}

# Step 2.1: taxonomic classification of ASV using consensus vsearch
# Input:
# - representative sequences artifact
# - reference reads file
# - reference taxonmy file
# - max accepts
# Output:
# - taxonomy artifact (taxonomy.qza)
${q2classify} --i-query ${repr_seq_artifact} \
              --i-reference-reads ${reference_reads_file} \
              --i-reference-taxonomy ${reference_taxonomy_file} \
              --o-classification ${taxonomy_artifact} \
              --p-maxaccepts ${max_accepts}
# Step 2.2: visualization of the taxonomy artifact
# Input:
# - taxonomy artifact
# Output:
# - taxonomy visualization artifact (taxonomy.qzv)
${q2tabulate} --m-input-file ${taxonomy_artifact} \
              --o-visualization ${taxonomy_visualization_artifact}
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
             --o-visualization ${taxa_barplot_artifact}

# Step 3.1: building ASV multiple sequence alignment using MAFFT
# Input:
# - representative sequences artifact
# Output:
# - aligned sequences artifact (aligned-rep-seqs.qza)
${q2mafft} --i-sequences ${repr_seq_artifact} \
           --o-alignment ${aligned_repr_seq_artifact}
# Step 3.2: masking MSA for highgly-variable positions
# Input:
# - aligned sequences artifact
# Output:
# - masked alignment sequences artifact (masked-aligned-rep-seqs.qza)
${q2mask} --i-alignment ${aligned_repr_seq_artifact} \
          --o-masked-alignment ${masked_repr_seq_artifact}
# Step 3.3: building the phylogenitc tree using FastTree
# Input:
# - masked alignment sequences artifact
# Output:
# - unrooted tree artifact (unrooted-tree.qza)
${q2fasttree} --i-alignment ${masked_repr_seq_artifact} \
              --o-tree ${unrooted_tree_artifact}
# Step 3.4: setting the tree root using midpoint-root placement
# Input:
# - unrooted tree artifact
# Output:
# - rooted tree artifact (rooted-tree.qza)
${q2midpoint} --i-tree ${unrooted_tree_artifact} \
              --o-rooted-tree ${rooted_tree_artifact}

# Step 4: computing alpha and beta diversity metrics
# Input:
# - rooted tree artifact
# - otu table artifact
# - sample metadata
# - sampling depth
# Output:
# - core metrics output directory (core-metrics-results)
${q2diversity} --i-phylogeny ${rooted_tree_artifact} \
               --i-table ${otu_table_artifact} \
               --m-metadata-file ${sample_metadata} \
               --p-sampling-depth ${sampling_depth} \
               --output-dir ${core_metrics_output_directory}
