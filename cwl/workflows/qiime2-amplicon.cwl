cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: "Perform complete 16S analysis with Qiime2"

inputs:
  manifest_file:
    type: File
  sample_metadata:
    type: File
  reference_reads_file:
    type: File
  reference_taxonomy_file:
    type: File
  trunc_q:
    type: int

outputs:
  imported_sequences_artifact:
    type: File
    outputSource: import_data/imported_sequences_artifact
  repr_seq_artifact:
    type: File
    outputSource: dada2/repr_seq_artifact
  otu_table_artifact:
    type: File
    outputSource: dada2/otu_table_artifact
  denoise_stat_artifact:
    type: File
    outputSource: dada2/denoise_stat_artifact
  denoise_stat_visualization_artifact:
    type: File
    outputSource: dada2/denoise_stat_visualization_artifact
  taxonomy_artifact:
    type: File
    outputSource: taxonomy/taxonomy_artifact
  taxonomy_visualization_artifact:
    type: File
    outputSource: taxonomy/taxonomy_visualization_artifact
  taxa_barplot_artifact:
    type: File
    outputSource: taxonomy/taxa_barplot_artifact
  aligned_repr_seq_artifact:
    type: File
    outputSource: phylogeny/aligned_repr_seq_artifact
  masked_repr_seq_artifact:
    type: File
    outputSource: phylogeny/masked_repr_seq_artifact
  unrooted_tree_artifact:
    type: File
    outputSource: phylogeny/unrooted_tree_artifact
  rooted_tree_artifact:
    type: File
    outputSource: phylogeny/rooted_tree_artifact
  core_metrics_output_directory:
    type: Directory
    outputSource: diversity/core_metrics_output_directory

steps:
  import_data:
    run: nested/01-qiime2-import.cwl
    in:
      manifest_file: manifest_file
    out:
      - imported_sequences_artifact
  dada2:
    run: nested/02-qiime2-dada2-denoise.cwl
    in:
      demux_sequences_artifact: import_data/imported_sequences_artifact
      trunc_q: trunc_q
    out:
      - repr_seq_artifact
      - otu_table_artifact
      - denoise_stat_artifact
      - denoise_stat_visualization_artifact
  phylogeny:
    run: nested/03-qiime2-phylogeny.cwl
    in:
      representative_sequences: dada2/repr_seq_artifact
    out:
      - aligned_repr_seq_artifact
      - masked_repr_seq_artifact
      - unrooted_tree_artifact
      - rooted_tree_artifact
  taxonomy:
    run: nested/04-qiime2-taxonomy.cwl
    in:
      representative_sequences_artifact: dada2/repr_seq_artifact
      reference_reads_file: reference_reads_file
      reference_taxonomy_file: reference_taxonomy_file
      sample_metadata: sample_metadata
      otu_table_artifact: dada2/otu_table_artifact
    out:
      - taxonomy_artifact
      - taxonomy_visualization_artifact
      - taxa_barplot_artifact
  diversity:
    run: nested/05-qiime2-diversity.cwl
    in:
      rooted_tree_artifact: phylogeny/rooted_tree_artifact
      otu_table_artifact: dada2/otu_table_artifact
      sample_metadata: sample_metadata
    out:
      - core_metrics_output_directory
