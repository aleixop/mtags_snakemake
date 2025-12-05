#!/bin/bash

#SBATCH --job-name=mtags
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --output=data/logs/mtags_%J.out
#SBATCH --error=data/logs/mtags_%J.err

## Load modules if you did not use conda for installation

module load snakemake
module load vsearch
module load blast
module load python
module load seqkit
module load R

## Activate the environment if you used conda for installation

# module load miniconda # you may need to change this for your cluster
# conda activate mtags_snakemake

## Run the pipeline

snakemake --cores ${SLURM_CPUS_PER_TASK}