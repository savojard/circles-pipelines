cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: "qiime2 perform taxonomic classification"

inputs:
  representative_sequences_artifact:
    type: File
  reference_reads_file:
    type: File
    label: "path to the reference reads file for taxonomic classification"
  reference_taxonomy_file:
    type: File
    label: "path to the reference taxonomy file for taxonomic classification"
  taxonomy_file_name:
    type: string
    label: "name of assigned taxonomy artifact"
    default: taxonomy.qza
  taxonomy_visualization_file_name:
    type: string
    label: "name of assigned taxonomy visualization artifact"
    default: taxonomy.qzv

outputs:
  taxonomy_artifact:
    type: File
    outputSource: feature-classify/out_taxa
  taxonomy_visualization_artifact:
    type: File
    outputSource: taxonomy-visualization/visualization_artifact

steps:
  feature-classify:
    run: ../tools/qiime2-feature-classifier-classify-consensus-vsearch.cwl
    in:
      rep_seqs: representative_sequences_artifact
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
