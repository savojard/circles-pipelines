#!/bin/bash

IMPORT_TYPE="SampleData[PairedEndSequencesWithQuality]"
IMPORT_FORMAT="PairedEndFastqManifestPhred33V2"
TRIM_LEFT_F=0
TRIM_LEFT_R=0
TRUNC_LEN_F=0
TRUNC_LEN_R=0

manifest_file=${1}
sample_metadata=${2}
trunc_q=${3}
reference_reads_file=${4}
reference_taxonomy_file=${5}

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

qiime tools import --input-path ${manifest_file} \
                   --output-path ${imported_sequences_artifact} \
                   --type ${IMPORT_TYPE} \
                   --input-format ${IMPORT_TYPE}

qiime dada2 denoise-paired --i-demultiplexed-seqs ${imported_sequences_artifact} \
                           --p-trim-left-f ${TRIM_LEFT_F} \
                           --p-trim-left-r ${TRIM_LEFT_R} \
                           --p-trunc-len-f ${TRUNC_LEN_F} \
                           --p-trunc-len-r ${TRUNC_LEN_R} \
                           --p-trunc-q ${trunc_q} \
                           --o-representative-sequences ${repr_seq_artifact} \
                           --o-table ${otu_table_artifact} \
                           --o-denoising-stats ${denoise_stat_artifact}

qiime metadata tabulate --m-input-file ${denoise_stat_artifact} \
                        --o-visualization ${denoise_stat_visualization_artifact}

qiime feature-classify classify-consensus-vsearch --i-query \
                                                  --i-reference-reads \
                                                  --i-reference-taxonomy \
                                                  --o-classification \
                                                  --p-maxaccepts

qiime metadata tabulate --m-input-file  \
                        --o-visualization

qiime taxa barplot --i-table \
                   --i-taxonomy \
                   --m-metadata-file \
                   --o-visualization

qiime alignment mafft --i-sequences --o-alignment

qiime alignment mask --i-alignment --o-masked-alignment

qiime phylogeny fasttree --i-alignment --o-tree

qiime phylogeny midpoint-root --i-tree --o-rooted-tree

qiime diversity core-metrics-phylogenetic --i-phylogeny \
                                          --i-table \
                                          --m-metadata-file \
                                          --p-sampling-depth \
                                          --output-dir
