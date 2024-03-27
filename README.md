# HPC_KrakenFor16S
 HPC pipeline for 16S taxonomic profiling using Kraken2. Developed for NBI cluster (SLURM scheduler).

 ## Pipeline overview:
 The pipeline takes raw or QC'd amplicon reads and run Kraken2 and optionally Bracken for rapid taxonomic profiling. An optional merging step will parse the Kraken2/Bracken output and generate a PhyloSeq object.

 ## To dos:
 	- Add cutadapt step in the pipeline
 	- Add merging a parsing Bracken outputs 

 ## Requirements
 This pipeline requires:
 	- Kraken2 v2.1.3
 	- Bracken v2.9
 	- Cutadapt v4.7
 	- R v4.2.1 (and the Phyloseq, tidyverse and r-argparse packages)

The required tools can be installed using conda and the provided .yml environment description.

```
conda env create -f KrakenFor16S.yml
```

## Run the pipeline
To run the pipeline you'll need to:
	- Edit the config.sh file 
	- Edit the Scheduler header of the script to specify the correct pipeline

Note: The current implementation is not parrallelized and will submit a single job that will process one file at a time.
