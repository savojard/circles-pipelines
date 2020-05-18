cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: "qiime2 data import sub-workflow"

inputs:
  manifest_file:
    type: File
    label: "path to manifest file that should be imported"
  input_type:
    type: string
    default: "SampleData[PairedEndSequencesWithQuality]"
  input_format:
    type: string
    default: "PairedEndFastqManifestPhred33V2"
  imported_file_name:
    type: string
    label: "name of the imported sequence artifact"
    default: imported-sequences.qza

outputs:
  imported_sequences_artifact:
    type: File
    outputSource: import_data/sequences_artifact

steps:
  import_data:
    run: ../../tools/qiime2-tools-import.cwl
    in:
      input_path: manifest_file
      input_type: input_type
      input_format: input_format
      output_filename: imported_file_name
    out:
      - sequences_artifact
