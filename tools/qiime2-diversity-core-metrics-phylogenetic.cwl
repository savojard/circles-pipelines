#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "qiime2: compute alpha and beta diversity core metrics"

hints:
  - $import: qiime2-docker-hint.yml

inputs:
  input_tree:
    type: File
    input_binding:
      prefix: "--i-phylogeny"
  input_table:
    type: File
    input_binding:
      prefix: "--i-table"
  sample_metadata:
    type: File
    input_binding:
      prefix: "--m-metadata-file"
  sampling_depth:
    type: int
    input_binding:
      prefix: "--p-sampling-depth"
  output_dir:
    type: string
    input_binding:
      prefix: "--output-dir"
outputs:
  rarefied_table:
  outputBinding:
    glob: $(inputs.output_dir)/rarefied_table.qza


baseCommand: ["qiime", "diversity", "core-metrics-phylogenetic"]
