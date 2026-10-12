#!/usr/bin/env bash
#SBATCH --job-name=rat_amr
#SBATCH --output=logs/amr_%A_%a.out
#SBATCH --error=logs/amr_%A_%a.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --partition=batch
#SBATCH --array=1-287%20
set -euo pipefail

module load miniforge/25.3.0
export CONDA_ENVS_DIRS=/cluster/tufts/rosenbaumlab/shared/conda/envs
export CONDA_PKGS_DIRS=/cluster/tufts/rosenbaumlab/shared/conda/pkgs
eval "$(conda shell.bash hook)"
conda activate amr

PROJ="$SLURM_SUBMIT_DIR"
CARD="$PROJ/card"
THREADS=${SLURM_CPUS_PER_TASK:-8}

read -r S R1 R2 < <(sed -n "${SLURM_ARRAY_TASK_ID}p" "$PROJ/samples.txt")
[ -n "${S:-}" ] || { echo "No entry at line $SLURM_ARRAY_TASK_ID"; exit 1; }

mkdir -p "$PROJ"/rgi "$PROJ"/mc "$PROJ"/tmp
export TMPDIR="$PROJ/tmp"

if [ -s "$PROJ/rgi/$S.gene_mapping_data.txt" ] && [ -s "$PROJ/mc/$S.txt" ]; then
  echo "$S already done"; exit 0
fi

# remove partial output if this task dies (RGI --clean never runs on failure)
cleanup() {
  if [ -s "$PROJ/rgi/$S.gene_mapping_data.txt" ] && [ -s "$PROJ/mc/$S.txt" ]; then
    rm -f "$PROJ/rgi/$S".*temp* 2>/dev/null   # success: tidy any stragglers
  else
    echo "Task incomplete; removing partial output for $S"
    rm -f "$PROJ/rgi/$S".* "$PROJ/mc/$S.txt"
  fi
}
trap cleanup EXIT

echo "== $S start $(date) threads $THREADS"
cd "$CARD"

rgi bwt -1 "$R1" -2 "$R2" -a kma -n "$THREADS" --clean --local \
    --include_wildcard -o "$PROJ/rgi/$S"

run_microbe_census.py -t "$THREADS" "$R1","$R2" "$PROJ/mc/$S.txt"

echo "== $S done $(date)"
