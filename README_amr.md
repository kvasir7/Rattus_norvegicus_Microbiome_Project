# Boston rat resistome: AMR analysis

Antimicrobial resistance gene (ARG) profiling of shotgun metagenomes from
*Rattus norvegicus* faecal samples collected in Boston, 2016–2022
(Qiita study 16318).

## Data

Reads were processed upstream in Qiita (study 16318, artifact 234379) using
"Adapter and host filtering v2023.12", which performs adapter trimming with
fastp and removes rat reads with minimap2. All scripts here start from those
filtered per-sample FASTQ files.

287 samples were processed: 285 rats, an extraction blank, and a positive
control.

## Pipelines

Two independent ARG databases were used, so that results could be compared.

CARD / RGI. `rgi bwt` with KMA, against CARD 4.0.2 together with CARD
Resistomes & Variants (WildCARD) 4.0.2. Mutation-dependent models are excluded
by RGI 6.x default behaviour.

MEGARes / AMR++. AMR++ v4 `resistome` pipeline with BWA-MEM, against MEGARes
4.00, with SNP confirmation disabled so that mutation-dependent determinants
are excluded from both pipelines.

Normalisation. MicrobeCensus estimates average genome size and genome
equivalents per sample, allowing ARG counts to be expressed as RPKG (reads per
kilobase of reference per genome equivalent).

## Repository layout

```
hpc_scripts/   SLURM and Nextflow scripts run on the Tufts Pax cluster
patches/       modifications made to published software, with explanations
env/           software and database versions, conda environment export
docs/          SOURCES.md: provenance of every command and parameter choice
```

## Order of execution

1. `unzip.sbatch` — extract the Qiita artifact
2. `depth.sbatch` — per-sample read counts and read lengths
3. `make_sample_list.sh` — build the sample manifest from file names
4. `setup_card.sbatch` — install and index CARD + WildCARD
5. `02_amr_array.sbatch` — RGI and MicrobeCensus, one array task per sample
6. `neg_control.sbatch` — RGI only, for the extraction blank
7. `amrpp_run.sh` — AMR++ / MEGARes

Downstream filtering, normalisation and statistics are done in R.

## Quality control

Extraction blank. 501 reads yielding four ARG hits, all below 40% reference
coverage and none passing any detection threshold.

Positive control. Taxonomic profiling showed an unexpected community rather
than a mock standard, so the sample was excluded from analysis and reported as
such.

Plate integrity. Six rats had two vials sequenced independently. In all six
cases the two vials from the same animal were each other's closest match out
of 268 profiled samples.

Batch structure. All samples were sequenced in a single run. Lane is crossed
with collection year; plate is partially correlated with year and is included
as a covariate.

Sample exclusions. 14 samples with implausible average genome size estimates
(genome equivalents below 100) were excluded. These are the same low-depth
samples independently dropped by Qiita's Woltka processing.

## Provenance and AI assistance

See `docs/SOURCES.md` for the origin of each command and parameter choice, and
for the AI-assistance statement.
