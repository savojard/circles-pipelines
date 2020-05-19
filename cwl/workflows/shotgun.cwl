cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: "Perform complete analysis of shotgun metagenomics data using different tools"

inputs:
  

outputs:

steps:
  preprocess:
    run: nested/01-shotgun-preprocess.cwl

  taxonomic_analysis:
    run: nested/02-shotgun-taxonomy.cwl

  functional_analysis:
    run: nested/03-shotgun-function.cwl
