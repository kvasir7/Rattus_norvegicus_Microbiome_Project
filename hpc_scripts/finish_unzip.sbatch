#!/usr/bin/env bash
#SBATCH --job-name=unzip2
#SBATCH --output=unzip2_%j.out
#SBATCH --error=unzip2_%j.err
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --partition=batch
set -euo pipefail

cd "$SLURM_SUBMIT_DIR"
export UNZIP_DISABLE_ZIPBOMB_DETECTION=TRUE
unzip -q -o study16318_artifact.zip -d qiita_download

echo "Extracted: $(ls qiita_download/per_sample_FASTQ/234379/*.fastq.gz | wc -l)"
mkdir -p fastq metadata
find qiita_download -name "*.fastq.gz" -exec mv -t fastq/ {} +
find qiita_download -name "*.txt" -exec cp -t metadata/ {} + 2>/dev/null || true

echo "In fastq/: $(ls fastq/*.fastq.gz | wc -l)"
echo "Left behind:"; find qiita_download -type f | head
df -h /cluster/tufts/rosenbaumlab | tail -1
