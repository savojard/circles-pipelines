#!/bin/bash
# Pipeline for shotgun metagenomics sequencing analysis


# CIRCLES_PIPELINES_ROOT is an env variable set to the pipeline root dir
SCRIPTS_DIR=${CIRCLES_PIPELINES_ROOT}/utils

function logmsg {
  echo "[$(date -R)]: $1"
}

if [ $# -eq 0 ]
then
    echo -e "\n$0 options
    -f/--forward: input FASTQ file of forward reads [required]
    -r/--reverse: input FASTQ file of reerse reads [required]
    -o/--output_dir: output directory [shotgun-analysis]
    "
    exit 1
fi
# -----------------------

# Paramenters
forward=''
reverse=''
output_dir=shotgun-analysis

short="f:r:o:"
long="forward:,reverse:,output_dir:,"
OPTS=$(getopt -o ${short} -l ${long} -- "$@")
eval set -- "$OPTS"

while [ $# -gt 0 ] ; do
    case "$1"
    in
        -f|--manifest) forward=$2; shift;;
        -r|--reverse) reverse=$2; shift;;
        -o|--output_dir) output_dir=$2; shift;;
        (--) shift; break;;
    esac
    shift
done

if ! test -f ${forward} ; then
  echo "Error with forward read file: no such file or directory"
  exit 1
fi

if ! test -f ${reverse} ; then
  echo "Error with reverse file: no such file or directory"
  exit 1
fi

mkdir -p ${output_dir}
log_stdout=${output_dir}/analysis.out.log
log_stderr=${output_dir}/analysis.err.log

cat /dev/null > ${log_stdout}
cat /dev/null > ${log_stderr}

# Filenames
metawrap_output_dir=${output_dir}/metawrap_qc
clean_forward_reads=${metawrap_output_dir}/final_pure_reads_1.fastq
clean_reverse_reads=${metawrap_output_dir}/final_pure_reads_2.fastq
metaphlan_output_file=${output_dir}/metaphlan.profile.tsv
humann_output_dir=${output_dir}/humann-output-dir
humann_output_basename=humann
humann_gene_output_file=${humann_output_dir}/${humann_output_basename}_genefamilies.tsv
humann_pathway_output_file=${humann_output_dir}/${humann_output_basename}_pathabundance.tsv
humann_coverage_output_file=${humann_output_dir}/${humann_output_basename}_pathcoverage.tsv
humann_gene_cpm_output_file=${humann_output_dir}/${humann_output_basename}_genefamilies.cpm.tsv
humann_pathway_cpm_output_file=${humann_output_dir}/${humann_output_basename}_pathabundance.cpm.tsv
humann_search_mode=uniref90
humann_pathway_db=metacyc
# Tools shortcut
metawrapqc="metawrap read_qc"
metaphlan="metaphlan"
humann="humann"
humanncpm="humann_renorm_table"

# Step 1: read quality check, filtering and trimming
# conda activate metawrap
${metawrapqc} -1 ${forward} -2 ${reverse} -o ${metawrap_output_dir}
# conda deactivate

# Step 2: taxonomic profiling
# conda activate metaphlan
${metaphlan} --input_type fastq  --tax_lev a \
             --ignore_eukaryotes --ignore_archaea \
             ${clean_forward_reads},${clean_reverse_reads} \
             ${metaphlan_output_file}

# Step 3: functional profiling

${humann} -i ${clean_forward_reads},${clean_reverse_reads} \
          --input-format fastq \
          --output ${humann_output_dir} \
          --output-basename ${humann_output_basename}
          --taxonomic-profile ${metaphlan_output_file} \
          --search-mode ${humann_search_mode} \
          --pathways ${humann_pathway_db}

${humanncpm} --input ${humann_gene_output_file} \
             --output ${humann_gene_cpm_output_file}

${humanncpm} --input ${humann_pathway_output_file} \
             --output ${humann_pathway_cpm_output_file}
# conda deactivate
