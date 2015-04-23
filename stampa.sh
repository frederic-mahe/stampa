#!/bin/bash -
#
# This shell script splits a multiple fasta file in individual fasta
# files, each file is then pairwised aligned with a reference dataset
# using vsearch. The best identity (in terms of percentage of
# identity) is kept.


## Usage
function usage () {
	echo "Usage:"
	echo "$(basename ${0}) /path/to/target/file.fasta reference_dataset"
	echo "    (reference_dataset can be SSU_V4, SSU_V9)"
}


## Variables
PROJECT="/path/to/target"
SCRIPT_PATH="${PROJECT}/src"
SCRIPT_NAME="stampa.sh"
VSEARCH_SCRIPT="stampa_vsearch.sh"
MERGE_SCRIPT="stampa_merge.sh"
VSEARCH="${PROJECT}/bin/vsearch/bin/vsearch"
PATH_TO_V4="data/references"
SSU_V4="V4_reference_sequences_20150216.fasta"
PATH_TO_V9="data/references"
SSU_V9="V9_reference_sequences_20130802.fasta"
OUTPUT_PREFIX="fasta."
INPUT_FILE=$(readlink -f "${1}")  # Works if $1 is a symbolic link
PATH_TO_FILE=$(readlink -f $(dirname "${1}"))
TARGET="${2}"
INPUT_FILE_BASENAME=${INPUT_FILE##*/}
INPUT_FILE_BASENAME=${INPUT_FILE_BASENAME%.*}
STAMPA_FOLDER="stampa_${INPUT_FILE_BASENAME}"
NULL="/dev/null"


## Check arguments
if [[ -z "${INPUT_FILE}" ]] ; then
        echo -e "You must specify a fasta file.\n" 1>&2
        usage
        exit 1
fi
if [[ -z "${TARGET}" ]] ; then
        echo -e "You must specify a target database (SSU_V4 or SSU_V9).\n" 1>&2
        usage
        exit 1
fi


## Select database
case "${TARGET}" in
    "SSU_V9")
        DATABASE="${PROJECT}/${PATH_TO_V4}/${SSU_V9}"
        THRESHOLD="10000"
        ;;
    "SSU_V4")
        DATABASE="${PROJECT}/${PATH_TO_V4}/${SSU_V4}"
        THRESHOLD="10000"
        ;;
    *)
        echo -e "You must specify a target database (SSU_V4 or SSU_V9).\n" 1>&2
        usage
        exit 1
        ;;
esac


## Verify the uniqueness of reference sequence names
duplicates=$(grep "^>" "${DATABASE}" | cut -d " " -f 1 | sort -d | uniq -d)
if [[ "${duplicates}" ]] ; then
	echo -e "WARNING!\nThe reference database contains duplicated accession numbers\n${duplicates}\n" 1>&2
fi


## Verify the abundance annotations (expect "_")
if [[ $(head "${INPUT_FILE}" | grep ";size=") ]] ; then
    echo "Please note that the fasta file contains abundance annotations in usearch's style (;size=)." 1>&2
fi


## Compute the number of jobs
AMPLICON_NUMBER=$(grep -c "^>" "${INPUT_FILE}")
if (( AMPLICON_NUMBER % THRESHOLD == 0 )) ; then
	MAX=$((2 * AMPLICON_NUMBER / THRESHOLD))
else
	MAX=$((2 * AMPLICON_NUMBER / THRESHOLD + 1 ))
fi


## The upper limit to the number of amplicons is 10,000 * THRESHOLD / 2
if [[ ${MAX} -gt 10000 ]] ; then
	echo -e "Too many amplicons!\nChange the threshold value or further split your dataset." 1>&2
	exit 1
fi


## Go where the work is.
cd "${PATH_TO_FILE}/"


## Remove old analysis and create a work folder
if  [[ -d "${STAMPA_FOLDER}" ]] ; then
	echo "Removing old stampa analysis." 1>&2
	rm -rf "${STAMPA_FOLDER}/"
fi
mkdir "${STAMPA_FOLDER}"
cd "${STAMPA_FOLDER}/"


## Split the input fasta file into chuncks (convert vsearch abundance-style to swarm style)
split --numeric-suffixes \
    --lines="${THRESHOLD}" \
    --suffix-length=5 \
    <(sed -e '/^>/ s/;size=/_/' -e '/^>/ s/;$//' "${INPUT_FILE}") "${OUTPUT_PREFIX}"


## Where are we?
PWD=$(pwd)


## Launch job array (upper limit is 10,000 jobs)
# -N: separates the job report information from the job output.
LSB_JOB_REPORT_MAIL=N bsub -N -J "${STAMPA_FOLDER}[1-${MAX}]" \
    -o "${NULL}" -e "${NULL}" \
    -q short -W 60 -n 16 \
    -R "span[hosts=1] select[model==XEON_E5_2670] rusage[mem=1024]" \
    bash "${SCRIPT_PATH}/${VSEARCH_SCRIPT}" "${DATABASE}" "${PWD}"


## Hold a job as long as the above job is not done, then launch the merging script
bsub -w "done(\"${STAMPA_FOLDER}\")" -q normal -R "rusage[mem=1024]" bash "${SCRIPT_PATH}/${MERGE_SCRIPT}" "${PWD}"


exit 0
