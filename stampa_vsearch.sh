#!/bin/bash -

# Target SSE4.1-able nodes, keep all the threads on one host
# Usage: bsub -q long -n 16 -R "span[hosts=1] select[model==XEON_E5_2670] rusage[mem=1024]" bash stampa_vsearch.sh FASTA

VSEARCH="${HOME}/bin/vsearch/bin/vsearch"
SUBJECTS="${1}"
PWD=${2}
INDEX=$(printf "%05g\n" $(( $LSB_JOBINDEX - 1 )))
QUERIES="fasta.${INDEX}"
ASSIGNMENTS="${QUERIES/fasta./hits.}"
IDENTITY="0.5"
MAXREJECTS=32
THREADS=16
NULL="/dev/null"

# compare environmental sequences to known reference sequences
"${VSEARCH}" --usearch_global "${QUERIES}" \
    --threads "${THREADS}" \
    --dbmask none \
    --qmask none \
    --rowlen 0 \
    --notrunclabels \
    --userfields query+id1+target \
    --maxaccepts 0 \
    --maxrejects "${MAXREJECTS}" \
    --top_hits_only \
    --output_no_hits \
    --db "${SUBJECTS}" \
    --id "${IDENTITY}" \
    --iddef 1 \
    --userout "${ASSIGNMENTS}" > "${NULL}" 2> "${NULL}"

rm -f "${QUERIES}"

exit 0
