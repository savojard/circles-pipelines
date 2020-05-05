cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: "qiime2 perform complete taxonomic of paired-end samples"
inputs:
  manifest_file:
    type: File
    label: "path to manifest file that should be imported"
  reference_reads_file:
    type: File
    label: "path to the reference reads file for taxonomic classification"
  reference_taxonomy_file:
    type: File
    label: "path to the reference taxonomy file for taxonomic classification"
  imported_file_name:
    type: string
    label: "name of the imported sequence artifact"
    default: imported-sequences.qza
  repr_seq_file_name:
    type: string
    label: "name of DADA2 representative sequence artifact"
    default: dada2-rep_seq.qza
  otu_table_file_name:
    type: string
    label: "name of DADA2 OTU table artifact"
    default: dada2-table.qza
  denoise_stat_file_name:
    type: string
    label: "name of DADA2 denoise stat artifact"
    default: dada2-stats.qza
  denoise_stat_visualization_file_name:
    type: string
    label: "name of DADA2 denoise stat visualization artifact"
    default: dada2-stats.qzv
  taxonomy_file_name:
    type: string
    label: "name of assigned taxonomy artifact"
    default: taxonomy.qza
  taxonomy_visualization_file_name:
    type: string
    label: "name of assigned taxonomy visualization artifact"
    default: taxonomy.qzv
  input_type:
    type: string
    default: "SampleData[PairedEndSequencesWithQuality]"
  input_format:
    type: string
    default: "PairedEndFastqManifestPhred33V2"
  trim_left_f:
    type: int
    default: 0
  trim_left_r:
    type: int
    default: 0
  trunc_len_f:
    type: int
    default: 0
  trunc_len_r:
    type: int
    default: 0
outputs:
  imported_sequence_artifact:
    type: File
    outputSource: import_data/sequences_artifact
  repr_seq_artifact:
    type: File
    outputSource: dada2-denoise/representative_sequences
  otu_table_artifact:
    type: File
    outputSource: dada2-denoise/table
  denoise_stat_artifact:
    type: File
    outputSource: dada2-denoise/denoising_stats
  denoise_stat_visualization_artifact:
    type: File
    outputSource: dada2-visualization/visualization_artifact
  taxonomy_artifact:
    type: File
    outputSource: feature-classify/out_taxa
  taxonomy_visualization_artifact:
    type: File
    outputSource: taxonomy-visualization/visualization_artifact
steps:
  import_data:
    run: ../tools/qiime2-tools-import.cwl
    in:
      input_path: manifest_file
      input_type: input_type
      input_format: input_format
      output_filename: imported_file_name
    out:
      - sequences_artifact
  dada2-denoise:
    run: ../tools/qiime2-dada2-denoise-paired.cwl
    in:
      demultiplexed_seqs: import_data/sequences_artifact
      trim_left_f: trim_left_f
      trim_left_r: trim_left_r
      trunc_len_f: trunc_len_f
      trunc_len_r: trunc_len_r
      representative_sequences_filename: repr_seq_file_name
      table_filename: otu_table_file_name
      denoising_stats_filename: denoise_stat_file_name
    out:
      - representative_sequences
      - table
      - denoising_stats
  dada2-visualization:
    run: ../tools/qiime2-metadata-tabulate.cwl
    in:
      input_file: dada2-denoise/denoising_stats
      visualization_filename: denoise_stat_visualization_file_name
    out:
      - visualization_artifact
  feature-classify:
    run: ../tools/qiime2-feature-classifier-classify-consensus-vsearch.cwl
    in:
      rep_seqs: dada2-denoise/representative_sequences
      reference_reads: reference_reads_file
      reference_taxonomy: reference_taxonomy_file
      taxonomy_filename: taxonomy_file_name
    out:
      - out_taxa
  taxonomy-visualization:
    run: ../tools/qiime2-metadata-tabulate.cwl
    in:
      input_file: feature-classify/out_taxa
      visualization_filename: taxonomy_visualization_file_name
    out:
      - visualization_artifact
