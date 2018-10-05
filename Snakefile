shell.executable("/bin/bash")
shell.prefix("source $HOME/.bashrc; ")

IDS, = glob_wildcards("fastq/{id}_1.fastq.gz")

rule all:
	input: expand("checkm/{sample}.checkm.txt", sample=IDS)

rule download:
	input: "runs/{id}.txt"
	output: 
		R1="fastq/{id}_1.fastq.gz",
		R2="fastq/{id}_2.fastq.gz"
	params:
		id="{id}"
	shell: 
		'''
		echo {input} {output.R1} {output.R2}
		'''

rule cutadapt:
	input:
		R1="fastq/{id}_1.fastq.gz",
		R2="fastq/{id}_2.fastq.gz"
	output:
		R1="trimmed/{id}_1.t.fastq.gz",
		R2="trimmed/{id}_2.t.fastq.gz"
	conda: "envs/cutadapt.yaml"
	shell: 
		'''
		cutadapt -a AGATCGGAAGAGC -A AGATCGGAAGAGC -o {output.R1} -p {output.R2} -O 5 --minimum-length=50 {input.R1} {input.R2}
		'''

rule megahit:
	input:
		R1="trimmed/{id}_1.t.fastq.gz",
		R2="trimmed/{id}_2.t.fastq.gz"
	output: 
		di="megahit/{id}/",
		fa="megahit/{id}/final.contigs.fa"
	conda: "envs/megahit.yaml"
	threads: 8
	shell: 
		'''
		megahit --continue --k-list 27,47,67,87 --kmin-1pass -m 12e+10 --presets meta-large --min-contig-len 1000 -t {threads} -1 {input.R1} -2 {input.R2} -o {output.di}
		'''


rule bwa_index:
	input:  "megahit/{id}/final.contigs.fa"
	output: "bwa_indices/{id}.fa.bwt"
	params:
		idx="bwa_indices/{id}.fa"
	conda: "envs/megahit.yaml"
	shell:
		'''
		bwa index -p {params.idx} {input}
		'''

rule bwa_mem:
	input:
		R1="trimmed/{id}_1.t.fastq.gz",
		R2="trimmed/{id}_2.t.fastq.gz",
		idx="bwa_indices/{id}.fa.bwt"
	output: 
		cov="coverage/{id}.txt"
	params:
		idx="bwa_indices/{id}.fa",
		bam="bam/{id}.bam"
	conda: "envs/megahit.yaml"
	threads: 4
	shell: 
		'''
		bwa mem -t {threads} {params.idx} {input.R1} {input.R2} | samtools sort -@{threads} -m 500M -o {params.bam} -
		samtools index {params.bam}

		samtools flagstat {params.bam} > {params.bam}.flagstat
		jgi_summarize_bam_contig_depths --outputDepth {output.cov} --minContigLength 2000 --minContigDepth 2 {params.bam}
		
		rm {params.bam}
		rm {params.bam}.bai
		'''
	
rule metabat:
        input:
                asm="megahit/{id}/final.contigs.fa",
                dep="coverage/{id}.txt"
        output: "metabat/{id}"
        conda: "envs/metabat2.yaml"
        params:
                out="metabat/{id}/{id}"
        threads: 16
        shell:
                '''
                metabat2 -t {threads} -v -m 2000 -i {input.asm} -a {input.dep} -o {params.out}
                '''

rule checkm:
        input:  "metabat/{id}"
        output:
                txt="checkm/{id}.checkm.txt",
                dir="checkm/{id}.checkm"
        threads: 8
        conda: "envs/checkm.yaml"
        shell:
                '''
                checkm lineage_wf -f {output.txt} -t {threads} -x fa {input} {output.dir}
		'''
