

rule length_filter:
    input: 
        R1="data/input/{sample}_R1.fastq.gz", 
        R2="data/input/{sample}_R2.fastq.gz"
    output:
        "results/{sample}.filtered"
    params:
        min_length = 75
    shell:
        "seqkit seq -m {params.min_length} {input.R1} {input.R2} > {output}"

rule fastq_to_fasta:
    input: