cwlVersion: v1.0
class: CommandLineTool
label: "qiime2: setting up a new analysis"

requirements:
  - class: ShellCommandRequirement

inputs:
  job_name:
    type: string
    label: "The name given to this analysis"

outputs:
  working_dir:
    type: string
    outputBinding:
      glob: $(inputs.job_name)

arguments:
  - mkdir
  - -p
  - $(inputs.job_name)
