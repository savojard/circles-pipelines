#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "qiime2: importing data and create output artifact"

hints:
  - $import: qiime2-docker-hint.yml

inputs:
  input_type:
    type: string
    label: "type of the qiime2 artifact that will be created"
    inputBinding:
      prefix: "--type"
  input_path:
    type: string
    label: "path to file that should be imported"
    inputBinding:
      prefix: "--input-path"
  input_format:
    type: string
    label: "format of the input path"
    inputBinding:
      prefix: "--input-format"
  output_filename:
    type: string
    label: "filename to use for output file (qza format)"
    inputBinding:
      prefix: "--output-path"
outputs:
  sequences_artifact:
    type: File
    outputBinding:
      glob: $(inputs.output_filename)

baseCommand: ["qiime", "tools", "import"]
