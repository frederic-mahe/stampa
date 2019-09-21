#!/bin/bash -
#
# This shell script parses vsearch results and merges the sorted
# results in a final file.

PWD="${1}"
SCRIPT="../stampa_merge.py"
FINAL_FILE=${PWD/*stampa_/}
FINAL_FILE=${FINAL_FILE/\//}.results

cd "${PWD}"

python3 "${SCRIPT}" "${PWD}"

for f in results.* ; do
    sort -k2,2nr -k1,1d ${f}
done > ../${FINAL_FILE}

rm -f results.*

exit 0
