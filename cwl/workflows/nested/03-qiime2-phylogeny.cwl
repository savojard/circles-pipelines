#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
requirements:
- class: SubworkflowFeatureRequirement
label: qiime2 create phylogenetic tree


inputs:
  representative_sequences: File
  aligned_rep_seqs_filename:
    type: string
    default: aligned-rep-seqs.qza
  masked_aligned_rep_seqs_filename:
    type: string
    default: masked-aligned-rep-seqs.qza
  unrooted_tree_filename:
    type: string
    default: unrooted-tree.qza
  rooted_tree_filename:
    type: string
    default: rooted-tree.qza

outputs:
  aligned_repr_seq_artifact:
    type: File
    outputSource: align_representative_sequences/alignment
  masked_repr_seq_artifact:
    type: File
    outputSource: mask_representative_sequences/masked_aligned_rep_seqs
  unrooted_tree_artifact:
    type: File
    outputSource: create_tree_from_alignment/unrooted_tree
  rooted_tree_artifact:
    type: File
    outputSource: root_tree/rooted_tree

steps:
  align_representative_sequences:
    run: ../../tools/qiime2-alignment-mafft.cwl
    in:
      sequences: representative_sequences
      alignment_filename: aligned_rep_seqs_filename
    out:
      - alignment
  mask_representative_sequences:
    run: ../../tools/qiime2-alignment-mask.cwl
    in:
      alignment: align_representative_sequences/alignment
      masked_aligned_rep_seqs_filename: masked_aligned_rep_seqs_filename
    out:
      - masked_aligned_rep_seqs
  create_tree_from_alignment:
    run: ../../tools/qiime2-phylogeny-fasttree.cwl
    in:
      alignment: mask_representative_sequences/masked_aligned_rep_seqs
      tree_filename: unrooted_tree_filename
    out:
      - unrooted_tree
  root_tree:
    run: ../../tools/qiime2-phylogeny-midpoint-root.cwl
    in:
      tree: create_tree_from_alignment/unrooted_tree
      rooted_tree_filename: rooted_tree_filename
    out:
      - rooted_tree
