#!/usr/bin/env bash
#SBATCH --job-name=setup_card
#SBATCH --output=card_%j.out
#SBATCH --error=card_%j.err
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --partition=batch
set -euo pipefail

module load miniforge/25.3.0
export CONDA_ENVS_DIRS=/cluster/tufts/rosenbaumlab/shared/conda/envs
export CONDA_PKGS_DIRS=/cluster/tufts/rosenbaumlab/shared/conda/pkgs
eval "$(conda shell.bash hook)"
conda activate amr

CARD="$SLURM_SUBMIT_DIR/card"
WILDCARD_VERSION=4.0.2

mkdir -p "$CARD"; cd "$CARD"
echo "Start: $(date)"

rgi clean --local

wget -O data https://card.mcmaster.ca/latest/data
tar -xvf data ./card.json
rgi load --card_json card.json --local

rgi card_annotation -i card.json > card_annotation.log 2>&1
CARD_FASTA=$(ls card_database_v*.fasta | grep -v "_all" | head -1)
echo "CARD annotation FASTA: $CARD_FASTA"

wget -O wildcard_data.tar.bz2 https://card.mcmaster.ca/latest/variants
mkdir -p wildcard
tar -xjf wildcard_data.tar.bz2 -C wildcard
gunzip -f wildcard/*.gz

rgi wildcard_annotation -i wildcard --card_json card.json \
    -v "$WILDCARD_VERSION" > wildcard_annotation.log 2>&1

rgi load --card_json card.json \
    --card_annotation "$CARD_FASTA" \
    --wildcard_annotation "wildcard_database_v${WILDCARD_VERSION}.fasta" \
    --wildcard_index wildcard/index-for-model-sequences.txt \
    --wildcard_version "$WILDCARD_VERSION" \
    --local

{
  echo "Setup date: $(date)"
  echo "RGI: $(rgi main --version 2>&1)"
  echo "CARD database: $(rgi database --version --local 2>&1)"
  echo "WildCARD version: $WILDCARD_VERSION"
} | tee card_setup_versions.txt
echo "End: $(date)"
