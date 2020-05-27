#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "qiime2: Denoises paired-end sequences, dereplicates them, and filters chimeras"


hints:
  - $import: qiime2-docker-hint.yml

inputs:
  demultiplexed_seqs:
    type: File
    label: "paired-end demultiplexed sequences to be denoised"
    inputBinding:
      prefix: "--i-demultiplexed-seqs"
  trim_left_f:
    type: int
    label: "position at which forward sequences should be trimmed"
    inputBinding:
      prefix: "--p-trim-left-f"
  trim_left_r:
    type: int
    label: "position at which reverse sequences should be trimmed"
    inputBinding:
      prefix: "--p-trim-left-r"
  trunc_len_f:
    type: int
    label: "position at which forward sequences should be truncated"
    inputBinding:
      prefix: "--p-trunc-len-f"
  trunc_len_r:
    type: int
    label: "position at which reverse sequences should be truncated"
    inputBinding:
      prefix: "--p-trunc-len-r"
  trunc_q:
    type: int
    label: "Reads are truncated at the first instance of a quality score less than or equal to this value"
    inputBinding:
      prefix: "--p-trunc-q"
  representative_sequences_filename:
    type: string
    label: "resulting feature sequences filename"
    inputBinding:
      prefix: "--o-representative-sequences"
  table_filename:
    type: string
    label: "resulting feature table filename"
    inputBinding:
      prefix: "--o-table"
  denoising_stats_filename:
    type: string
    label: "denoising stats filename"
    inputBinding:
      prefix: "--o-denoising-stats"

outputs:
  representative_sequences:
    type: File
    outputBinding:
      glob: $(inputs.representative_sequences_filename)
  table:
    type: File
    outputBinding:
      glob: $(inputs.table_filename)
  denoising_stats:
    type: File
    outputBinding:
      glob: $(inputs.denoising_stats_filename)

baseCommand: ["qiime", "dada2", "denoise-paired"]
