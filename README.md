# stampa #

Sequence Taxonomic Assignment by Massive Pairwise Alignments

The purpose of **stampa** is to assign amplicons from environmental
studies to known taxonomic groups. It is based on
[vsearch](https://github.com/torognes/vsearch) for the actual
similarity search and pairwise comparisons, the rest of the scripts
only deal with the splitting of the input and gathering of the output
(similar in spirit to a map-reduce approach).

Outline:
* check the input fasta file,
* create and work in a sub-directory,
* split it in smaller chunks,
* for each chunk, launch a vsearch job (LSF scheduler),
* collect all the results,
* solve ties by computing last common ancestor assignments,
* output a table of taxonomic assignments.

The **stampa** scripts are made public for transparency. These scripts
are not generic and are very unlikely to run out-of-the-box in a new
environment. However, experience has shown that with a reasonable
amount of modifications (and patience), **stampa** can be successfully
replicated.

## Requirements ##

### Input ###

**stampa** expects the input fasta file to look like that:

```
>4cd8428ea6c4e43cea1e82374c94a8e8_15638316
gtcgctactaccgattgaacgttttagtgaggtcctcggactgtttggtagtcggatcactctgactgcctggcgggaagacgaccaaactgtagcgtttagaggaagtaaaagtcgtaacaaggtttcc
>43fc0f0172e7aaac61d17259daa5beb4_13556476
gtcgctactaccgattgaacgttttagtgaggtcctcggactgtttgcctggcggattactctgcctggctggcgggaagacgaccaaactgtagcgtttagaggaagtaaaagtcgtaacaaggtttcc
>97485665bcded44c4d86c131ca714848_7929938
gtcgctcctaccgattgaatacgttggtgattgaattggataaagagatatcatcttaaatgatagcaaagcggtaaacatttgtaaactagattatttagaggaaggagaagtcgtaacaaggtttcc
>e16f63411f69ad864bd504118029a344_7174749
gtcgctactaccgattgaacgttttagtgaggtatttggactgggccttgggaggattcgttctcccatgttgctcgggaagactcccaaacttgagcgtttagaggaagtaaaagtcgtaacaaggtttcc
>8120906e4f554b6d4fa5f41604d985fd_6704338
gtcgctactaccgattgaacgttttagtgaggtcctcggactgtgatcctggctggttactcagcctgggttgcgggaagacgaccaaactgtagcgtttagaggaagtaaaagtcgtaacaaggtttcc
```

Abundance values (after the `_`) will be reported in the
results. Abundance annotations in uclust-style `;size=` are also
accepted.

### References ###

Reference datasets need to be cut using the same primers than the one
used to produce the amplicons. For eucaryotes, the website
[PR2](http://ssu-rrna.org/) provides datasets trimmed using primer
pairs for popular marker regions (rRNA 18S V4 and rRNA 18S V9). The
reference sequences should be formatted as such:

```
>AM490275.1.2082_U Eukaryota|Opisthokonta|Metazoa|Arthropoda|Crustacea|Branchiopoda|Bosmina|Bosmina+longirostris
gtcgctactaccgattgaatgatttagtgagaacttcagacggctatgtttgtccggggcaacccgcgtcaagcagggctgaaagatgttcaaacttgatcctttagaggaagtaaaagtcgtaacaaggtttcc
>AY772728.1.1784_U Eukaryota|Archaeplastida|Rhodophyta|Florideophyceae|Gigartinales|Gigartinales_X|Atractophora|Atractophora+hypnoides
gtcgctcctaccgattgagtggtccggtgaggccttgggagggcaggatggactgttgcttgtcgacggaccgtctggcccaaacttggtcaaaccttatcacttagaggaaggagaactcgtaacaaggtttcc
>JN701622.1.846_U Eukaryota|Opisthokonta|Metazoa|Arthropoda|Crustacea|Malacostraca|Biarctus|Biarctus+sordidus
gtcgctactaccgattgaatgatttagtgaggccttcggactggcgctcttggatgttctacccttcacgctgcatccgtggcgtaggggttctcgcctcgagctgacggaaagatgtccaaacttgatcatttagaggaagtaaaagtcgtaacaaggtttcc
```

The space separating the accession field and the taxonomic path is
important. The field separator `|` (pipe) for the taxonomic levels is
important too. The number of taxonomic levels, using DNA or RNA, or
the case of the DNA sequence are not important.

### Third-party tools ###

**stampa** was tested with:
* python 2.7 (or later versions, not tested with python 3),
* vsearch 1.1.13 (or later versions),
* bash 4 (or later versions),
* *(probably other hidden dependencies)*

## Results ##

**stampa** will output a table containing 5 fields:
* identifier of the environmental sequence,
* abundance of the environmental sequence,
* global pairwise identity with reference sequences (from 0.0% to 100.0%),
* taxonomic assignment (could be last common ancestor),
* accession numbers of reference sequences (co-best hits, comma separated)

```
4cd8428ea6c4e43cea1e82374c94a8e8	18416272	96.9	Eukaryota|Opisthokonta|Metazoa|Arthropoda|Crustacea|Maxillopoda|Copepoda|Calanoida|Gaetanus|Gaetanus+variabilis	AB625960.1.2064_U
43fc0f0172e7aaac61d17259daa5beb4	18024962	100.0	Eukaryota|Opisthokonta|Metazoa|Arthropoda|Crustacea|Maxillopoda|Copepoda|Calanoida|*|*	L81939.1.1800_U,AF514342.1.1802_U,AF514341.1.1802_U,AF514343.1.1802_U,AF514340.1.1802_U,AF514344.1.1802_U,AF514339.1.1802_U
3f7e7831cc058f87f68b06d7a4f1762f	15107744	100.0	Eukaryota|Alveolata|Dinophyta|Dinophyceae|*|*|*|*|*	AF274260,EF492510,EF492511,EU287485,EU287487,EU780638,AY803739,DQ004735,Y16232,AJ415519,EF492484,HM067010,JF791096
```

The third line shows what happens when there is a problem with the
reference database. Several identical references are assigned to
different branches of the Dinophyceae, logically **stampa** assigned
the sequence to the last common ancestor (taxa names were replaced by
a star `*`).

### Stampa plots ###

Building on taxonomic assignment results, it is straightforward to
produce "stampa plots". These informative plots represent the
distribution of maximum percentage of similarity to reference
sequences. Ideally, most environmental sequences should be close to
known references and stand on the right side of the plot (close to
100% similarity).

Stampa plots are graphical evaluations of the coverage of
environmental sequences by reference sequences, allowing to assess
immediately the numerical importance of novel sequences.

The first step is to summarize stampa results: target a specific taxa
(Metazoa fo instance), group by similarity value (column #3) and count
reads (column #2):

```
TABLE="18S_samples_stampa.table" grep "Metazoa" "${TABLE}" | \ awk
'BEGIN {FS = "\t"} {stampa[$3] += $2 } END { for (similarity in
stampa) { print similarity, stampa[similarity] } }' | sort -k1,1n >
"${TABLE/.table/.data}"
```

Then, use the data to produce a plot with R and ggplot (the above step
can be easily performed in R with the packages tidyr and dplyr, if you
are more familiar with them):

```
library(ggplot2)
library(scales)

setwd("~/mydata/")
input <- "18S_samples_stampa.data"
TITLE <- "Metazoa"

## Load the data
d <- read.table(input, sep = " ", dec = ".")
colnames(d) <- c("identities", "abundance")
d$identities <- d$identities / 100

## Get the max abundance value
y_max <- max(d$abundance)

## Plot
ggplot(d, aes(x = identities, y = abundance)) +
    geom_segment(aes(xend = identities, yend = 0), colour = "darkred", size = 1) +
    scale_x_continuous(labels = percent, limits = c(0.5, 1)) +
    scale_y_continuous(labels = comma) +
    xlab("max % of similarity to reference database") +
    ylab("number of reads") +
    annotate("text", x = 0.50, y = y_max * 0.9,
             hjust = 0, colour = "grey", size = 8, label = TITLE)

## Output to PDF
output <- gsub(".data", ".pdf", input, fixed = TRUE)
ggsave(file = output, width = 8 , height = 5)

quit(save = "no")
```
