#!/usr/bin/env bash
set -euo pipefail
PROJ=${1:-$PWD}
cd "$PROJ"

: > samples.txt
: > unpaired.txt
for R1 in fastq/*_R1_001.fastq.gz; do
  R2=${R1/_R1_001/_R2_001}
  base=$(basename "$R1")
  if   [[ $base == *Negative_control* ]]; then S=NEGATIVE_CONTROL
  elif [[ $base =~ [Zz]ymo ]];            then S=ZYMO_CONTROL
  else
    id=$(grep -oE '[0-9]{2}R[0-9]{3}(-[0-9]+)?' <<< "$base" | head -1)
    S=${id/-/.}
  fi
  if [ -z "${S:-}" ]; then echo "$base  (no sample id)" >> unpaired.txt; continue; fi
  if [ ! -f "$R2" ];  then echo "$base  (no R2)"        >> unpaired.txt; continue; fi
  echo "$S $PWD/$R1 $PWD/$R2" >> samples.txt
done

n=$(wc -l < samples.txt)
echo "samples.txt: $n samples"
echo "duplicate sample names (should be none):"
cut -d' ' -f1 samples.txt | sort | uniq -d
[ -s unpaired.txt ] && { echo "unpaired/unnamed files:"; cat unpaired.txt; }
echo
echo "Set the array range to:  --array=1-$n%20"
