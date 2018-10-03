#!/bin/bash

source $HOME/.bashrc

#$ -cwd
#$ -pe sharedmem 1
#$ -l h_vmem=4G
#$ -l h_rt=240:00:00

module load anaconda
source activate usda_microbiome

snakemake --keep-going --rerun-incomplete --jobscript custombash.sh --use-conda --cluster-config cluster.json --cluster "qsub -R yes -V -S /bin/bash -cwd -pe sharedmem {cluster.core} -l h_rt={cluster.time} -l h_vmem={cluster.vmem} -P {cluster.proj}" --jobs 5000
