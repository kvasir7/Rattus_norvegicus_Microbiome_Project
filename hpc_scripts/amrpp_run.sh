#!/usr/bin/env bash
# AMR++ v4 / MEGARes v4.00 resistome run on Tufts Pax.
# Input reads are the Qiita rat-filtered, adapter-trimmed FASTQs (artifact
# 234379), so the "resistome" pipeline is used: alignment and counting only,
# with no further trimming or host removal.
# --snp N skips SNP confirmation, matching RGI 6.x, which excludes
# mutation-dependent models from bwt by default.
module load nextflow/26.04.3 singularity/4.3.4

nextflow run main_AMR++.nf -profile singularity_slurm \
  -c /cluster/tufts/rosenbaumlab/shared/rat_amrpp/tufts.config \
  --pipeline resistome \
  --reads "/cluster/tufts/rosenbaumlab/shared/rat_amr/fastq/*_R{1,2}_001.fastq.gz" \
  --threads 8 --snp N \
  --output /cluster/tufts/rosenbaumlab/shared/rat_amrpp/results \
  -w /cluster/tufts/rosenbaumlab/shared/rat_amrpp/work
