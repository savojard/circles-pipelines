#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: qiime2 importing data from manifest

inputs:
  manifest_file: File
  sequences_artifact_filename:
    type: string
    default: imported-paired-end-sequences.qza
  

outputs:
  sequences_artifact:
    type: File
    outputSource: make_sequences_artifact/sequences_artifact

steps:
  import_sequences:
    run: ../tools/qiime2-tools-import.cwl
    in:
      input_path: manifest_file
      type: SampleData[PairedEndSequencesWithQuality]
      input_format: PairedEndFastqManifestPhred33V2
      output_filename: sequences_artifact_filename
    out:
      - sequences_artifact
  denoise_artifact:
    run: ../tools/qiime2-dada2-denoise-paired.cwl
    in:
      demultiplexed_seqs: sequences_artifact_filename

    out:
