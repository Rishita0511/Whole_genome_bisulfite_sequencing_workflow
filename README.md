# Whole Genome Bisulfite Sequencing (WGBS) Pipeline

High performance computing compatible WGBS pipeline designed for paired-end bisulfite sequencing data. Optimized for execution on SLURM-based high performance computing clusters.

## Overview

This pipeline performs end-to-end preprocessing and methylation analysis for whole genome bisulfite sequencing datasets. It includes read quality control, adapter trimming, alignment, deduplication, mapping quality filtering, and cytosine methylation extraction.

Designed for reproducible large-scale epigenomic analysis in HPC environments.

## Workflow

1. Quality control of raw FASTQ files using FastQC  
2. Adapter and quality trimming using Trim Galore  
3. Alignment to bisulfite-converted genome using Bismark  
4. PCR duplicate removal using deduplicate_bismark  
5. Mapping quality filtering (MAPQ >= 30) using samtools  
6. Cytosine methylation extraction using bismark_methylation_extractor  

## Tools and Dependencies

- FastQC  
- Trim Galore  
- Bismark  
- Samtools  
- SLURM workload manager  
- Conda  

## Execution

Submit the pipeline to a SLURM cluster using:

    sbatch wgbs_full_pipeline.sh

Before execution, update:

- SAMPLE_ID  
- RAW_DIR  
- WORK_DIR  
- GENOME_DIR  
- Project account and email in SLURM header  

## Input Requirements

- Paired-end FASTQ files following naming convention:

      sample_name_R1.fastq.gz
      sample_name_R2.fastq.gz

- Pre-built Bismark genome index directory  

## Output Structure

The pipeline generates the following directory structure:

- RawQC          → FastQC reports for raw reads  
- Trimmed        → Adapter-trimmed FASTQ files  
- Bismark        → Alignment BAM files and deduplicated BAM  
- Methylation    → Cytosine methylation reports and coverage files  
