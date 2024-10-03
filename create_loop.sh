#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <GENOME_PREFIX> <FASTQ_R1> <FASTQ_R2> <NUM_ITERATIONS>"
    exit 1
fi

# Assign input arguments to variables
GENOME_PREFIX="$1"       # Genome assembly prefix
FASTQ_R1="$2"            # First FASTQ file 
FASTQ_R2="$3"            # Second FASTQ file 
NUM_ITERATIONS="$4"      # Number of iterations

# Create the Pilon_Loop.sh script
{
    # Loop from 01 to NUM_ITERATIONS and create commands for Pilon
    for (( f=1; f<=NUM_ITERATIONS; f++ )); do
        # Format the current iteration with leading zeros (e.g., 01, 02, ..., 20)
        printf -v padded "%02d" "$f"

        # Build the command for running Pilon on each genome file
        echo "./runPilon.sh ./ ${GENOME_PREFIX}${padded}.fa $FASTQ_R1 $FASTQ_R2; mv ${GENOME_PREFIX}${padded}.pilon.fa"
    done | paste - <(
        # Loop from 02 to (NUM_ITERATIONS + 1) to append the next genome file name
        for (( f=2; f<=NUM_ITERATIONS+1; f++ )); do
            printf -v padded "%02d" "$f"
            echo "${GENOME_PREFIX}${padded}.fa"
        done
    ) | sed 's/\t/ /g' > Pilon_Loop.sh
}

# Notify the user that the script has been generated
echo "Pilon_Loop.sh has been created with Pilon commands."
