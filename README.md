# chicken_pig_amr
Snakemake pipeline for assembly of chicken and pig AMR datasets

You will need
* Snakemake
* Conda

Practice run:
```sh
snakemake -np
```

Simple usage:
```sh
snakemake --use-conda 
```

Cluster usage:
```sh
snakemake --jobscript custombash.sh --use-conda --cluster-config cluster.json --cluster "qsub -R yes -V -S /bin/bash -cwd -pe sharedmem {cluster.core} -l h_rt={cluster.time} -l h_vmem={cluster.vmem} -P {cluster.proj}" --jobs 5000
```
