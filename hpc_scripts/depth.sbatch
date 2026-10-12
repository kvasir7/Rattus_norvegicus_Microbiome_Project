#!/usr/bin/env bash
#SBATCH --job-name=depth
#SBATCH --output=depth_%j.out
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --partition=batch
module load miniforge/25.3.0
export CONDA_ENVS_DIRS=/cluster/tufts/rosenbaumlab/shared/conda/envs
eval "$(conda shell.bash hook)"
conda activate amr
cd "$SLURM_SUBMIT_DIR"
seqkit stats -j 8 -T fastq/*_R1_001.fastq.gz > logs/depth.tsv
echo "done: $(wc -l < logs/depth.tsv) files"
