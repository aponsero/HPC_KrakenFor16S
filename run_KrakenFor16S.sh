#!/bin/bash -l

# load job configuration
source config.sh

# echo for log
echo "job started"; hostname; date


# start process
cd $IN_DIR

if [[ ! -d "$OUT_DIR" ]]; then
	mkdir -p $OUT_DIR
fi

# Run cutadapt
if [[ "$CUTADAPT" = "TRUE" ]]; then
	if [[ ! -d "$OUT_DIR/Cutadapt" ]]; then
        	mkdir -p $OUT_DIR/Cutadapt
	fi

	for PAIR1 in *_R1_001.fastq.gz
	do
		PAIR2="${PAIR1%%_R1_001.fastq.gz}_R2_001.fastq.gz"
		OUT1="$OUT_DIR/Cutadapt/${PAIR1%%_R1_001.fastq.gz}_trimmed_R1_001.fastq.gz"
		OUT2="$OUT_DIR/Cutadapt/${PAIR1%%_R1_001.fastq.gz}_trimmed_R2_001.fastq.gz"
		cutadapt -a $ADAPTER1 -g $ADAPTER2 -o $OUT1 -p $OUT2 $PAIR1 $PAIR2
	done
fi

# Run Kraken2
echo " #### Starting Kraken2 processing ####"

if [[ ! -d "$OUT_DIR/Kraken2" ]]; then
        mkdir -p $OUT_DIR/Kraken2
fi

if [[ "$CUTADAPT" = "TRUE" ]]; then
	cd $OUT_DIR/Cutadapt
	for PAIR1 in *_trimmed_R1_001.fastq.gz
	do
        	PAIR2="${PAIR1%%_trimmed_R1_001.fastq.gz}_trimmed_R2_001.fastq.gz"
        	SAMPLE="${PAIR1%%_trimmed_R1_001.fastq.gz}_profiles.txt"
        	OUTPUT="${PAIR1%%_trimmed_R1_001.fastq.gz}_output.txt"
        	if [[ -f "$OUT_DIR/Kraken2/$SAMPLE" ]]; then
                	echo "$OUT_DIR/Kraken2/$SAMPLE already processed by Kraken2 -- Skipping to next file."
        	else
                	kraken2 --paired --db $DBNAME --confidence $KRA_CONF --report $OUT_DIR/Kraken2/$SAMPLE $PAIR1 $PAIR2
        	fi
	done
else 
	for PAIR1 in *_R1_001.fastq.gz
	do
        	PAIR2="${PAIR1%%_R1_001.fastq.gz}_R2_001.fastq.gz"
        	SAMPLE="${PAIR1%%_R1_001.fastq.gz}_profiles.txt"
        	OUTPUT="${PAIR1%%_R1_001.fastq.gz}_output.txt"
        	if [[ -f "$OUT_DIR/Kraken2/$SAMPLE" ]]; then
                	echo "$OUT_DIR/Kraken2/$SAMPLE already processed by Kraken2 -- Skipping to next file."
        	else
                	kraken2 --paired --db $DBNAME --confidence $KRA_CONF --report $OUT_DIR/Kraken2/$SAMPLE $PAIR1 $PAIR2
        	fi
	done
fi

echo " #### Ending Kraken2 processing ####"
echo "####################################"

# Run Bracken
if [[ $BRACKEN = "TRUE" ]]; then
	echo " #### Starting Braken processing ####"        
        echo "####################################"

	if [[ ! -d "$OUT_DIR/Bracken" ]]; then
        	mkdir -p $OUT_DIR/Bracken
	fi

	for PAIR1 in *_R1_001.fastq.gz
	do
	       SAMPLE="${PAIR1%%_R1_001.fastq.gz}_profiles.txt"
	       if [[ -f "$OUT_DIR/Bracken/$SAMPLE" ]]; then
	             echo "$OUT_DIR/Bracken/$SAMPLE already done."
       		else
	             bracken -d $DBNAME -i $OUT_DIR/Kraken2/$SAMPLE -o $OUT_DIR/Bracken/$SAMPLE -r $BRA_LEN -l G
       		fi
	done	
	echo "####################################"
	echo "####### Ending Bracken processing ########"
fi

# Merge outputs in PhyloSeq
if [[ $MERGE = "TRUE" ]]; then
	echo " #### Starting Merging process ####"
        echo "####################################"
	if [[ $BRACKEN = "FALSE" ]]; then
		Rscript $SLURM_SUBMIT_DIR/workers/Kraken2table.R -i $OUT_DIR/Kraken2 -t dir 
		Rscript $SLURM_SUBMIT_DIR/workers/merge2physeq.R -i $OUT_DIR/Kraken2 -o $OUT_DIR/Kraken_PhyloSeq.rds  
	else 
		Rscript $SLURM_SUBMIT_DIR/workers/Brackentable.R -i $OUT_DIR/Kraken2 -t dir 
		Rscript $SLURM_SUBMIT_DIR/workers/merge2physeq.R -i $OUT_DIR/Kraken2 -o $OUT_DIR/Bracken_PhyloSeq.rds
	fi
fi

# echo for log
echo "job successfully ended"; hostname; date

