#!/usr/bin/env bash
#SBATCH --job-name=unzip
#SBATCH --output=unzip_%j.out
#SBATCH --error=unzip_%j.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --partition=batch
set -euo pipefail

cd "$SLURM_SUBMIT_DIR"
mkdir -p fastq metadata logs

echo "Start: $(date)"
export UNZIP_DISABLE_ZIPBOMB_DETECTION=TRUE
unzip -q study16318_artifact.zip -d qiita_download

find qiita_download -name "*.fastq.gz" -exec mv -t fastq/ {} +
find qiita_download -name "*.txt" -exec cp -t metadata/ {} + 2>/dev/null || true

echo "FASTQ files: $(ls fastq/*.fastq.gz | wc -l)"
echo "Anything left behind:"
find qiita_download -type f | head -20
df -h /cluster/tufts/rosenbaumlab | tail -1
echo "End: $(date)"
