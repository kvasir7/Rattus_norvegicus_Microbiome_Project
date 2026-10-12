#!/usr/bin/env bash
#SBATCH --job-name=neg_ctrl
#SBATCH --output=logs/negctrl_%j.out
#SBATCH --error=logs/negctrl_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --partition=batch
set -euo pipefail

module load miniforge/25.3.0
export CONDA_ENVS_DIRS=/cluster/tufts/rosenbaumlab/shared/conda/envs
export CONDA_PKGS_DIRS=/cluster/tufts/rosenbaumlab/shared/conda/pkgs
eval "$(conda shell.bash hook)"
conda activate amr

PROJ="$SLURM_SUBMIT_DIR"
read -r S R1 R2 < <(grep "^NEGATIVE_CONTROL " "$PROJ/samples.txt")
export TMPDIR="$PROJ/tmp"

echo "== $S start $(date)"
cd "$PROJ/card"

# RGI only. MicrobeCensus is not run: with 501 reads it reports
# "No hits to marker proteins - cannot estimate genome size",
# so genome equivalents cannot be computed for this blank.
rgi bwt -1 "$R1" -2 "$R2" -a kma -n 4 --clean --local \
    --include_wildcard -o "$PROJ/rgi/$S"

echo "== $S done $(date)"
