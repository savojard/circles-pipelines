cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: "Perform complete 16S analysis with Qiime2"

inputs:
  manifest_file:
    type: File
  reference_reads_file:
    type: File
  reference_taxonomy_file:
    type: File

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

steps:
  import_data:
    run: nested/01-qiime2-import.cwl
    in:
      input_path: manifest_file
    out:
      - imported_sequences_artifact
  dada2:
    run: nested/02-qiime2-dada2-denoise.cwl
    in:
      demux_sequences_artifact: import_data/imported_sequences_artifact
    out:
      - repr_seq_artifact
      - otu_table_artifact
      - denoise_stat_artifact
      - denoise_stat_visualization_artifact
  taxonomy:
    run: nested/04-qiime2-taxonomy.cwl
    in:
      representative_sequences_artifact: dada2/repr_seq_artifact
      reference_reads_file: reference_reads_file
      reference_taxonomy_file: reference_taxonomy_file
    out:
      - taxonomy_artifact
      - taxonomy_visualization_artifact
