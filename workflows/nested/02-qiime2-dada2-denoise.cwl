cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: "qiime2 perform dada2 analysis (denoise, trim, filtering and visualization)"
inputs:
  demux_sequences_artifact:
    type: File
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
  trim_left_f:
    type: int
    default: 0
  trim_left_r:
    type: int
    default: 0
  trunc_len_f:
    type: int
    default: 20
  trunc_len_r:
    type: int
    default: 20
  trunc_q:
    type: int
    default: 20

outputs:
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

steps:
  dada2-denoise:
    run: ../tools/qiime2-dada2-denoise-paired.cwl
    in:
      demultiplexed_seqs: demux_sequences_artifact
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
