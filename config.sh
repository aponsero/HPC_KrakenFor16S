#!/bin/bash

## STEPS CONFIGURATION
### CUTADAPT STEP (OTIONAL)
CUTADAPT="FALSE" # TRUE or FALSE to run or not cutadapt
ADAPTER1="" # Primer1 string for cutadapt
ADAPTER2="" # Primer2 string for cutadapt

### KRAKEN2 STEP (REQUIRED)
KRA_CONF="0" # Kraken confidence threshold scoring

### BRACKEN STEP (OPTIONAL)
BRACKEN="FALSE" # TRUE or FALSE to run or not bracken
BRA_LEN="250" # length of the reads for Bracken

### MERGING STEP (OPTIONAL)
MERGE="TRUE" #  TRUE or FALSE to run the merging script into a PhyloSeq object

## MAIN CONFIGURATION
IN_DIR="" # Input directory
DBNAME="" # path to Kraken/Bracken database
OUT_DIR="$IN_DIR/Kraken2_profiling"
