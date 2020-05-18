#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "qiime2: compute alpha and beta diversity core metrics"

hints:
  - $import: qiime2-docker-hint.yml

inputs:
  input_tree:
    type: File
    label: "input tree"
    inputBinding:
      prefix: "--i-phylogeny"
  input_table:
    label: "input table"
    type: File
    inputBinding:
      prefix: "--i-table"
  sample_metadata:
    type: File
    label: "sample metadata tsv"
    inputBinding:
      prefix: "--m-metadata-file"
  sampling_depth:
    type: int
    label: "sample depth"
    inputBinding:
      prefix: "--p-sampling-depth"
  output_dir:
    type: string
    label: "output directory"
    inputBinding:
      prefix: "--output-dir"
outputs:
  rarefied_table:
    type: File
    outputBinding:
      glob: $(inputs.output_dir)/rarefied_table.qza


baseCommand: ["qiime", "diversity", "core-metrics-phylogenetic"]
