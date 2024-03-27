#!/usr/bin/env Rscript
#Ponsero Alise 2024
#Version  DRAFT
#This script takes a directory of parsed Kraken report files using the Kraken2table.R script
#and wrangle them into a PhyloSeq object.
########## 
#usage: merge2physeq.R [-h] [-i INPUT] [-s SAMPLE_TABLE] [-o OUTPUT] [-p]
#                    [--verbose] [--quietly]
#Kraken2 reports to table parser
#required arguments:
#  -i, --input_dir : Input directory with parsed files to merge
#optional arguments:
#  -s,  --sample_table : Path to a sample description table for PhyloSeq [default=NA]
#  -o,  --output : path and name for the output PhyloSeq object [default="Kraken_PhyloSeq.rds"]
#  -p,  --print_tables : print the merged count and taxonomy tables in csv files [default=FALSE]
#other arguments:
#  -h, --help : show this help message and exit
#  -v,  --verbose : Verbose output [default=TRUE]
#  -q,  --quietly : Quiet output [default=FALSE]
##########

##########
# Libraries
suppressPackageStartupMessages(library("argparse"))
suppressPackageStartupMessages(library("phyloseq"))
suppressPackageStartupMessages(library("tidyverse"))
##########

##########
# create parser object
parser <- ArgumentParser()
# Required arguments
parser$add_argument("-i", "--input", type="character", required=TRUE, 
                    help="path directory to parse",
                    metavar="input")
# Optional arguments
parser$add_argument("-s", "--sample_table", type="character", default='NA', 
                    help="Path to a sample description table for PhyloSeq [default=NA]",
                    metavar="sample_table")
parser$add_argument("-o", "--output", type="character", default='Kraken_PhyloSeq.rds', 
                    help="path and name for the output PhyloSeq object [default=Kraken_PhyloSeq.rds]",
                    metavar="output")
parser$add_argument("-p", "--print_tables", action="store_true", default=FALSE,
                    help="print the merged count and taxonomy tables in csv files [default=FALSE]")
# Other arguments
parser$add_argument("-v", "--verbose", action="store_true", default=TRUE,
                    help="Print extra output [default]")
parser$add_argument("-q", "--quietly", action="store_false", 
                    dest="verbose", help="Print little output")

args <- parser$parse_args()
##########

##########
# Input values sanity check

if ( args$sample_table != "NA" ) {
  if ( ! file.exists(args$sample_table) ) {
    write("INPUT ERROR: sample metadata file doesn't exists", stderr())
    quit(status=1)
  }
}


profiles <- sort(list.files(args$input, pattern=".parsed.tsv", full.names = TRUE))
if ( length(profiles)==0 ) {
  write("INPUT ERROR: input files not found in provided directory", stderr())
  quit(status=1)
}
##########


##########
### Merging to Count and Taxonomy tables

# print some progress messages to stdout if "quietly" wasn't requested
if ( args$verbose ) { 
  write("Starting the merging process...\n", stdout()) 
}

if ( args$verbose ) { 
  write(paste("found", as.character(length(profiles)), "to merge", sep=" "), stdout()) 
}

all_data <- tibble(
  taxid = numeric(), 
  D = character(), 
  P = character(), 
  C = character(),
  O = character(), 
  F = character(),
  G = character(),
  S = character()
)

for(f in profiles) {
  # read profile + select read counts and taxID
  name <- sapply(strsplit(basename(f), ".parsed.tsv"), `[`, 1)
  curr_profile <- read_tsv(f, show_col_types = FALSE) %>%
    mutate(D=ifelse(taxon=="unclassified", "Unclassified", 
                    ifelse(taxon=="root", "Root", D))) %>% select(taxid, D, P, C, O, F, G, S, reads) %>% 
    rename(!!name :="reads")
  
  # merge on TaxID
  all_data <- full_join(all_data, curr_profile, by = c("taxid", "D", "P", "C", "O", "F", "G", "S"))

  if ( args$verbose ) { 
    write("Profiles successfuly parsed and merged", stdout()) 
  }
}

# print count table
count_data <- all_data %>% select(- D, -P, -C, -O, -F, -G, -S)
countMat <- count_data %>% tibble::column_to_rownames("taxid") 
OTU = otu_table(as.matrix(countMat), taxa_are_rows = TRUE)

#print tax table
tax <- all_data %>% select(taxid, D, P, C, O, F, G, S) %>%
  rename("Kingdom"="D", "Phylum"="P", "Class"="C", "Order"="O", "Family"="F", "Genus"="G", "Species"="S")
taxMat <- tax %>% tibble::column_to_rownames("taxid")
TAX = tax_table(as.matrix(taxMat))

# Create PhyloSeq Object
if( args$sample_table=='NA'){
  if ( args$verbose ) { 
    write("Creating a PhyloSeq object without any sample table", stdout()) 
  }
  physeq = phyloseq(OTU, TAX)
}else{
  if ( args$verbose ) { 
    write("Creating a PhyloSeq object with sample table", stdout()) 
  }
  samples <- read_csv(args$sample_table, show_col_types = FALSE) ## move to sanity check
  sampleMat <- samples %>%tibble::column_to_rownames("Sample_ID") ## move to sanity check
  SAMPLE = sample_data(as.data.frame(sampleMat))
  
  physeq = phyloseq(OTU, TAX, SAMPLE)
}
write_rds(physeq, args$output)

# if requested print the count and taxonomy tables in csv
if( args$print_tables){
  if ( args$verbose ) { 
    write("Printing count and taxonomy tables", stdout()) 
  }
  write_excel_csv(count_data, "count_table.csv", na = "0")
  write_excel_csv(tax, "tax_table.csv")
}
##########

