#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    Parse stampa results and compute last common ancestor.
"""

from __future__ import print_function

__author__ = "Frédéric Mahé <mahe@rhrk.uni-kl.fr>"
__date__ = "2015/02/16"
__version__ = "$Revision: 1.0"

import os
import sys

#*****************************************************************************#
#                                                                             #
#                                  Functions                                  #
#                                                                             #
#*****************************************************************************#


def last_common_ancestor(taxonomies):
    """Compute last common ancestor"""
    lca = list()
    if len(taxonomies) > 1:
        zipped = zip(*taxonomies)
        for level in zipped:
            if len(set(level)) > 1:
                level = "*"
            else:
                level = level[0]
            lca.append(level)
    else:  # only one top hit
        lca = taxonomies[0]
    return lca


def main():
    """Parse stampa results and compute last common ancestor."""

    # Parse command line options and change working directory
    directory = sys.argv[1]
    if not os.path.exists(directory):
        sys.exit("ERROR: directory %s not found!" % directory)
    os.chdir(directory)

    # List files
    files = [f for f in os.listdir(directory) if f.startswith("hits.")]
    files.sort()

    # Parse files
    for input_file in files:
        previous = ("", "", "")
        taxonomies = list()
        accessions = list()
        output_file = input_file.replace("hits.", "results.")
        with open(input_file, "rb") as input_file:
            with open(output_file, "wb") as output_file:
                for line in input_file:
                    amplicon, identity, hit = line.strip().split("\t")
                    amplicon, abundance = amplicon.split("_")
                    if hit != "*":
                        accession, taxonomy = hit.split(" ", 1)
                    else:  # no hit
                        accession = taxonomy = "No_hit"
                    taxonomy = taxonomy.split("|")
                    if previous[0] == amplicon:
                        taxonomies.append(taxonomy)
                        accessions.append(accession)
                    elif previous[0] == "":  # deal with first item
                        taxonomies.append(taxonomy)
                        accessions.append(accession)
                        previous = (amplicon, abundance, identity)
                    elif previous[0] != amplicon:
                        # flush
                        lca = last_common_ancestor(taxonomies)
                        print("\t".join(previous), "|".join(lca),
                              ",".join(accessions), sep="\t", file=output_file)
                        # reinitialize
                        taxonomies = list()
                        accessions = list()
                        taxonomies.append(taxonomy)
                        accessions.append(accession)
                        previous = (amplicon, abundance, identity)
                # Deal with end of file
                lca = last_common_ancestor(taxonomies)
                print("\t".join(previous), "|".join(lca),
                      ",".join(accessions), sep="\t", file=output_file)
    return


#*****************************************************************************#
#                                                                             #
#                                     Body                                    #
#                                                                             #
#*****************************************************************************#

if __name__ == '__main__':

    main()

sys.exit(0)
