cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: qiime2 create diversity analysis

inputs:
  rooted_tree_artifact:
    type: File
  otu_table_artifact:
    type: File
  sample_metadata:
    type: File
  sampling_depth:
    type: int
    default: 5
  output_dir:
    type: string
    default: core-metrics-results
outputs:
  rarefied_table_artifact:
    type: File
    outputSource: core-metrics-calculation/rarefied_table

steps:
  core-metrics-calculation:
    run: ../../tools/qiime2-diversity-core-metrics-phylogenetic.cwl
    in:
      input_tree: rooted_tree_artifact
      input_table: otu_table_artifact
      sample_metadata: sample_metadata
      sampling_depth: sampling_depth
      output_dir: output_dir
    out:
      - rarefied_table
