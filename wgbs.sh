#!/bin/bash
# ===============================================================
#  SLURM Batch Script: Whole Genome Bisulfite Sequencing Pipeline
# ===============================================================
#
# Description:
# High performance computing compatible WGBS pipeline for
# paired-end bisulfite sequencing data. Designed for SLURM clusters.
#
# Workflow:
#   1. Raw read quality control (FastQC)
#   2. Adapter trimming (Trim Galore)
#   3. Alignment using Bismark
#   4. Deduplication
#   5. MAPQ filtering (>= 30)
#   6. Methylation extraction
#
# ===============================================================

#SBATCH --job-name=wgbs_full_pipeline
#SBATCH --time=48:00:00
#SBATCH --partition=bigmem
#SBATCH -A <project_account>
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=0
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<your_email>

# ===============================================================
#   Load Environment
# ===============================================================

module load anaconda
conda activate wgbs_preprocess_env

# ===============================================================
#   Define Input / Output Paths
#   (Modify these before running)
# ===============================================================

SAMPLE_ID="sample_name"

RAW_DIR="/path/to/raw_fastq"
WORK_DIR="/path/to/output_directory/${SAMPLE_ID}"
GENOME_DIR="/path/to/bismark_genome"

mkdir -p "$WORK_DIR/RawQC" \
         "$WORK_DIR/Trimmed" \
         "$WORK_DIR/Bismark" \
         "$WORK_DIR/Methylation"

R1="${RAW_DIR}/${SAMPLE_ID}_R1.fastq.gz"
R2="${RAW_DIR}/${SAMPLE_ID}_R2.fastq.gz"

# ===============================================================
# STEP 1: Quality Control on Raw FASTQ Files
# ===============================================================

echo "Running FastQC on raw FASTQ files..."
fastqc -t 8 -o "$WORK_DIR/RawQC" "$R1" "$R2"

echo "Step 1 complete: Raw QC finished."

# ===============================================================
# STEP 2: Adapter and Quality Trimming
# ===============================================================

echo "Running Trim Galore..."
trim_galore --paired \
            --cores $SLURM_CPUS_PER_TASK \
            "$R1" "$R2" \
            -o "$WORK_DIR/Trimmed"

echo "Step 2 complete: Trimming finished."

# ===============================================================
# STEP 3: Alignment with Bismark
# ===============================================================

conda deactivate
conda activate bismark_env

R1_trimmed=$(ls "$WORK_DIR/Trimmed"/*_val_1.fq.gz)
R2_trimmed=$(ls "$WORK_DIR/Trimmed"/*_val_2.fq.gz)

ALIGN_DIR="$WORK_DIR/Bismark"
mkdir -p "$ALIGN_DIR/tmp"

echo "Running Bismark alignment..."

bismark --parallel 8 \
        --genome "$GENOME_DIR" \
        -1 "$R1_trimmed" \
        -2 "$R2_trimmed" \
        -o "$ALIGN_DIR" \
        --temp_dir "$ALIGN_DIR/tmp"

echo "Step 3 complete: Alignment finished."

# ===============================================================
# STEP 4: Deduplication
# ===============================================================

INPUT_BAM=$(ls "$ALIGN_DIR"/*_pe.bam)

echo "Running deduplication..."
deduplicate_bismark --paired --bam "$INPUT_BAM"

DEDUP_BAM=$(ls "$ALIGN_DIR"/*.deduplicated.bam)

echo "Step 4 complete: Deduplication finished."

# ===============================================================
# STEP 5: MAPQ Filtering
# ===============================================================

module load samtools

FILTERED_BAM="$ALIGN_DIR/${SAMPLE_ID}_MAPQ30.bam"

echo "Filtering BAM by MAPQ >= 30..."
samtools view -b -q 30 "$DEDUP_BAM" > "$FILTERED_BAM"

echo "Step 5 complete: MAPQ filtering finished."

# ===============================================================
# STEP 6: Methylation Extraction
# ===============================================================

echo "Running methylation extraction..."

bismark_methylation_extractor \
    --paired-end \
    --gzip \
    --report \
    --multicore 8 \
    --cytosine_report \
    --genome_folder "$GENOME_DIR" \
    -o "$WORK_DIR/Methylation" \
    "$FILTERED_BAM"

echo "Step 6 complete: Methylation extraction finished."

conda deactivate

echo "Pipeline completed successfully."
