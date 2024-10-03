#!/bin/bash
# based on script by Rick Masonbrink
# Usage: ./run_piloin <DIR> <GENOME> <R1_FQ> <R2_FQ>

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <DIR> <GENOME> <R1_FQ> <R2_FQ>"
    exit 1
fi

# Assign arguments to variables
DIR="$1"
GENOME="$2"
R1_FQ="$3"
R2_FQ="$4"

# Extract the base name (without extension) from the genome file
GENOME_BASENAME="${GENOME%.*}"
R1_BASENAME="${R1_FQ%.*}"

# Build the genome index using HISAT2
hisat2-build "$GENOME" "$GENOME_BASENAME"

# Align reads to the genome and generate a SAM file
hisat2 -p 20 -x "$GENOME_BASENAME" -1 "$R1_FQ" -2 "$R2_FQ" -S "${GENOME_BASENAME}.${R1_BASENAME}.sam"

# Convert the SAM file to BAM format and sort the BAM file
samtools view --threads 8 -b -o "${GENOME_BASENAME}.${R1_BASENAME}.bam" "${GENOME_BASENAME}.${R1_BASENAME}.sam"

# Create a temporary directory for sorting
mkdir -p Samtemp
samtools sort -o "${GENOME_BASENAME}.${R1_BASENAME}_sorted.bam" -T Samtemp --threads 8 "${GENOME_BASENAME}.${R1_BASENAME}.bam"

# Index the sorted BAM file
samtools index "${GENOME_BASENAME}.${R1_BASENAME}_sorted.bam"

# Run Pilon for genome polishing
pilon -Xmx200G --genome "$GENOME" \
      --frags "${GENOME_BASENAME}.${R1_BASENAME}_sorted.bam" \
      --output "${GENOME_BASENAME}.pilon" \
      --outdir "$DIR" \
      --changes --fix all --threads 10 --chunksize 30000

# Clean up intermediate files
rm -f *.sam *.bam
