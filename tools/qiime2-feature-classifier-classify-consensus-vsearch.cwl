#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "qiime2: Classify reads by taxon using vsearch consensus classifier"

hints:
  - $import: qiime2-docker-hint.yml

inputs:
  rep_seqs:
    inputBinding:
      prefix: --i-query
    label: The feature data to be classified
    type: File
  reference_reads:
    inputBinding:
      prefix: --i-reference-reads
    label: The reference reads artifact
    type: File
  reference_taxonomy:
    inputBinding:
      prefix: --i-reference-taxonomy
    label: The reference taxonomy artifact
    type: File
  taxonomy_filename:
    inputBinding:
      prefix: --o-classification
    label: Resulting taxonomy filename
    type: string
  max_accepts:
    inputBinding:
      prefix: --p-maxaccepts
    type: integer
    label: Maximum number of hits to keep for each query
    default: 100
outputs:
  out_taxa:
    type: File
    outputBinding:
      glob: $(inputs.taxonomy_filename)

baseCommand: ["qiime", "feature-classifier", "classify-consensus-vsearch"]
