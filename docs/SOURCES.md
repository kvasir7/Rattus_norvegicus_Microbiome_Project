# Sources and provenance

This file records, for each script in this repository, which commands and
parameter choices come from published tools, documentation, or the primary
literature, and which parts were written specifically for this dataset.

Software versions are recorded in `env/`.

---

## Databases and tools

| Tool | Version | Citation |
|---|---|---|
| CARD | 4.0.2 | Alcock BP, Huynh W, Chalil R, Smith KW, Raphenya AR, Wlodarski MA, Edalatmand A, Petkau A, Syed SA, Tsang KK, et al. 2023. CARD 2023: expanded curation, support for machine learning, and resistome prediction at the Comprehensive Antibiotic Resistance Database. *Nucleic Acids Res* 51:D690–D699. doi:10.1093/nar/gkac920 |
| CARD Resistomes & Variants (WildCARD) | 4.0.2 | As above; downloaded from https://card.mcmaster.ca/latest/variants |
| RGI | 6.0.8 | https://github.com/arpcard/rgi |
| KMA | 1.6.18 | Clausen PTLC, Aarestrup FM, Lund O. 2018. Rapid and precise alignment of raw reads against redundant databases with KMA. *BMC Bioinformatics* 19:307. doi:10.1186/s12859-018-2336-6 |
| MicrobeCensus | 1.1.1 | Nayfach S, Pollard KS. 2015. Average genome size estimation improves comparative metagenomics and sheds light on the functional ecology of the human microbiome. *Genome Biol* 16:51. |
| MEGARes | 4.00 | MEGARes 4.0 and AMR++ 4.0: expanded, flexible resources for comprehensive resistome characterization in high-throughput analysis of metagenomic data. *Nucleic Acids Res* (under review, 2026). See also Bonin N, Doster E, Worley H, Pinnell LJ, Bravo JE, Ferm P, Marini S, Prosperi M, Noyes N, Morley PS, Boucher C. 2023. MEGARes and AMR++, v3.0. *Nucleic Acids Res* 51(D1):D744–D752. doi:10.1093/nar/gkac1047 |
| AMR++ | v4, commit 4a94623 | As above; https://github.com/Microbial-Ecology-Group/AMRplusplus |
| BWA-MEM | (container) | Li H. 2013. Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. arXiv:1303.3997 |
| seqkit | 2.14.0 | Shen W, Le S, Li Y, Hu F. 2016. SeqKit: a cross-platform and ultrafast toolkit for FASTA/Q file manipulation. *PLoS ONE* 11:e0163962. |
| Nextflow | 26.04.3 | Di Tommaso P, Chatzou M, Floden EW, Barja PP, Palumbo E, Notredame C. 2017. Nextflow enables reproducible computational workflows. *Nat Biotechnol* 35:316–319. |
| Singularity | 4.3.4 | Kurtzer GM, Sochat V, Bauer MW. 2017. Singularity: scientific containers for mobility of compute. *PLoS ONE* 12:e0177459. |
| Qiita (upstream) | 2023.12 | Gonzalez A, Navas-Molina JA, Kosciolek T, McDonald D, Vázquez-Baeza Y, Ackermann G, DeReus J, Janssen S, Swafford AD, Orchanian SB, et al. 2018. Qiita: rapid, web-enabled microbiome meta-analysis. *Nat Methods* 15:796–798. |
| Woltka (upstream taxonomy) | — | Zhu Q, Huang S, Gonzalez A, McGrath I, McDonald D, Haiminen N, Armstrong G, Vázquez-Baeza Y, Yu J, Kuczynski J, et al. 2022. Phylogeny-aware analysis of metagenome community ecology based on matched reference genomes while bypassing taxonomy. *mSystems* 7:e0016722. |

---

## Upstream data

Reads were downloaded from Qiita study 16318, artifact 234379: per-sample
FASTQ files produced by Qiita's "Adapter and host filtering v2023.12"
(qp-fastp-minimap2 2023.12) with `reference = rat`. All adapter trimming and
host-read removal was therefore performed upstream of this repository.

---

## Scripts

### hpc_scripts/unzip.sbatch, finish_unzip.sbatch

Extraction of the Qiita artifact archive.

From documentation: the Qiita zip layout
(`per_sample_FASTQ/<artifact-id>/*.fastq.gz`), described in the Qiita
documentation, "Downloading From Qiita".

Workaround: `UNZIP_DISABLE_ZIPBOMB_DETECTION=TRUE` is required because
recent Info-ZIP versions raise a false "possible zip bomb" error on large
archives with many entries. The archive's byte count was verified against the
length reported by the server before extraction.

Original: directory creation, the byte-count integrity check, and the
`find`/`mv` flattening of the unpacked tree.

### hpc_scripts/make_sample_list.sh

Pairs R1/R2 files and maps file names to sample identifiers.

From documentation: the Casava 1.8 paired-end naming convention
(`<id>_S<n>_L<lane>_R[12]_001.fastq.gz`), described in the QIIME 2
documentation, "Importing data".

Original: the sample-ID regex `[0-9]{2}R[0-9]{3}(-[0-9]+)?`, which encodes
this study's rat ID convention (collection year, R, rat number, optional vial
suffix); control-sample detection; the pairing loop; and the duplicate-name
verification.

### hpc_scripts/setup_card.sbatch

One-time setup of CARD and WildCARD for read mapping.

From documentation: the command sequence `rgi clean` → `rgi load --card_json`
→ `rgi card_annotation` → `rgi wildcard_annotation` → `rgi load` with both
annotations, given in the RGI documentation (`docs/rgi_bwt.rst`,
`docs/rgi_load.rst`). The download endpoints
`https://card.mcmaster.ca/latest/data` and `/latest/variants` are specified by
CARD for automated downloads. Selection of the non-`_all` annotation FASTA
(homolog models only) follows the RGI documentation's distinction between
homolog-only and all-models reference files.

Original: the SLURM wrapper and version logging.

### hpc_scripts/02_amr_array.sbatch

Per-sample RGI `bwt` and MicrobeCensus, as a SLURM job array.

From documentation: `rgi bwt -1 -2 -a kma -n --clean --local
--include_wildcard -o`, as given in the RGI documentation. KMA is RGI's
recommended aligner for CARD because of its handling of highly similar
reference sequences. `--include_wildcard` is recommended by the same
documentation for non-clinical samples, where allelic diversity is
underrepresented in canonical CARD; results are therefore summarised
primarily at AMR Gene Family level, as that documentation also advises.
MicrobeCensus is run as `run_microbe_census.py -t <threads> <R1>,<R2> <out>`
on default settings, per its README; quality filtering is not applied, per the
developers' guidance when the tool is used for normalisation.

Verified behaviour: mutation-dependent models (protein variant, rRNA
mutation, over-expression) are excluded by RGI 6.x default behaviour in `bwt`.
This was confirmed in the output, where all rows are `protein homolog model`.

Original: the SLURM array wrapper, the `sed -n "${SLURM_ARRAY_TASK_ID}p"`
task-to-sample mapping (a standard SLURM array idiom, not from a
bioinformatics tutorial), the skip-if-complete check, the cleanup trap, and
`TMPDIR` handling.

### hpc_scripts/neg_control.sbatch

RGI only, for the extraction blank. MicrobeCensus cannot estimate average
genome size from 501 reads ("No hits to marker proteins"), so genome
equivalents are unavailable for this sample and it is reported as a gene list
rather than as normalised abundance.

### hpc_scripts/depth.sbatch

`seqkit stats` across all R1 files, to obtain per-sample read counts and read
lengths.

### hpc_scripts/amrpp_run.sh, hpc_scripts/tufts.config

AMR++ v4 with MEGARes v4.00.

From documentation: `--pipeline resistome` performs alignment and counting
without trimming or host removal, per the AMR++ documentation. It was chosen
because adapter trimming and host filtering were already performed upstream in
Qiita. `--snp N` disables SNP confirmation so that mutation-dependent
determinants are excluded from both pipelines; `RequiresSNPConfirmation`
accessions are additionally removed during analysis in R. AMR++'s own
threshold-evaluation default (`evaluation_exclude_snp = "Y"`) excludes these
genes as well, and Bonin et al. 2023 note that many users drop them to
simplify the workflow. The default `min_gene_fraction = 0` in v4.00 is
retained so that detection criteria are applied downstream in R, identically
to the CARD results. The default `count_mode = "fragment"` is also retained;
because RGI counts reads rather than fragments, the two pipelines are compared
on relative abundance rather than on absolute counts.

Original: `tufts.config` (queue size and per-process CPU request, tuned to
this cluster's 250-CPU per-user limit) and the run wrapper.

---

## Patches

Both patches modify published software and are recorded here in full.

### patches/microbecensus_py3_patch.diff

MicrobeCensus 1.1.1 (bioconda) fails under Python 3 with `a bytes-like object
is required, not 'str'` in `check_rapsearch`, because `subprocess.Popen`
returns bytes in Python 3 while the surrounding code expects strings. The
patch adds `universal_newlines=True` to that call. No analytical behaviour is
changed; the patch affects only a version check. Related: MicrobeCensus GitHub
issue #32.

### patches/resistome_nf_patch.diff

AMR++'s `build_dependencies` process clones a GitHub repository at runtime.
Compute nodes on this cluster have no outbound network access, so the clone
fails. The patch replaces the `git clone` with a copy from `bin/`, into which
the repository was cloned once from a login node, matching how the same
process already handles its other two dependencies.

---

## Analysis decisions and their precedents

| Decision | Basis |
|---|---|
| Primary detection criterion: ≥80% of the reference covered by reads | The "gene fraction" threshold introduced with MEGARes (Lakin et al. 2017, *Nucleic Acids Res* 45:D574–D580) and applied by default in AMR++ v3.0 (Bonin et al. 2023). Applied with both CARD-RGI and MEGARes by Drane et al. 2025. |
| Permissive criterion: ≥50% coverage | Sensitivity analysis; threshold evaluation below 80% is examined by Rumore et al. 2023, *BMC Microbiol*, "Modeling the limits of detection for antimicrobial resistance genes in agri-food samples" (author list to be verified). |
| Read-count criterion: >100 mapped reads | Hackenberger D, Imtiaz H, Raphenya AR, Alcock BP, Poinar HN, Wright GD, McArthur AG. 2025. CARPDM: cost-effective antibiotic resistome profiling of metagenomic samples using targeted enrichment. *Appl Environ Microbiol* 91(3):e01876-24, which classified ARGs as present at more than 100 mapped reads regardless of breadth of coverage, using RGI bwt with KMA. |
| Normalisation: RPKG (reads / gene kb / genome equivalents) | Nayfach & Pollard 2015. |
| Reporting primarily at AMR Gene Family and Drug Class level | Advised by the RGI documentation when `--include_wildcard` is used. Hackenberger et al. 2025 describe the underlying "allele network problem", in which reads are misassigned among highly similar alleles in redundant databases even when using KMA. |
| Comparison of two databases and multiple thresholds | Recommended reporting practice for resistome studies; Drane et al. 2025 compare CARD and MEGARes directly and report them as equally sufficient for surveillance, with MEGARes giving better resolution for precise identification and quantification. |
| Exclusion of samples with genome equivalents < 100 | MicrobeCensus average genome size estimates for these samples fall far outside the bacterial range. The same samples were independently excluded by Qiita's Woltka processing. |

Additional citation: Drane K, Huerlimann R, Jones R, Whelan A, Sheehan M,
Ariel E, Kinobe R. 2025. Concordance in molecular methods for detection of
antimicrobial resistance: a cross sectional study of the influent to a
wastewater plant. *J Microbiol Methods* 228:107069.

---

## AI assistance

Claude Opus 5 (Anthropic; https://www.anthropic.com/claude) was used
to help write and debug the HPC job submission scripts in `hpc_scripts/` and
the R analysis code, between September and October 2026. All analytical
decisions, including database selection, detection thresholds, normalisation
approach, and statistical design, were made or approved by the authors. All
code was reviewed and tested by the authors, who are responsible for its
correctness. No AI tool was used to generate, interpret, or draw conclusions
from the data.
