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
    input_binding:
      prefix: "--i-phylogeny"
  input_table:
    label: "input table"
    type: File
    input_binding:
      prefix: "--i-table"
  sample_metadata:
    type: File
    label: "sample metadata tsv"
    input_binding:
      prefix: "--m-metadata-file"
  sampling_depth:
    type: int
    label: "sample depth"
    input_binding:
      prefix: "--p-sampling-depth"
  output_dir:
    type: string
    label: "output directory"
    input_binding:
      prefix: "--output-dir"
outputs:
  rarefied_table:
    outputBinding:
      glob: $(inputs.output_dir)/rarefied_table.qza


baseCommand: ["qiime", "diversity", "core-metrics-phylogenetic"]
