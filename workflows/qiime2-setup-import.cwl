#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: qiime2: setup job and importing data from manifest

inputs:
  job_name: string
  manifest_file: File
  sequences_artifact_filename:
    type: string
    default: imported-paired-end-sequences.qza

outputs:
  sequences_artifact:
    type: File
    outputSource: import_sequences/sequences_artifact

steps:
  setup:
    run: ../tools/qiime2-initial-setup.cwl
    in:
      job_name: job_name
    out:
      - working_dir
  import_sequences:
    run: ../tools/qiime2-tools-import.cwl
    in:
      input_path: manifest_file
      type: SampleData[PairedEndSequencesWithQuality]
      input_format: PairedEndFastqManifestPhred33V2
      output_filename: setup/working_dir/$(inputs.sequences_artifact_filename)
    out:
      - sequences_artifact
