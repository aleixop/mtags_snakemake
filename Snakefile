EXTRACTION_DB = "data/db/eukaryotesV4_92clust"
CLASSIFICATION_DB = "data/db/eukaryotesV4_v8.fasta"

rule format_input:
    input: 
        R1="data/input/{sample}_R1.fastq.gz", 
        R2="data/input/{sample}_R2.fastq.gz"
    output:
        "results/{sample}.fasta"
    params:
        min_length = 75
    shell:
        "seqkit seq -m {params.min_length} {input.R1} {input.R2} | "
        "seqkit fq2fa | "
        "seqkit replace -w 0 -p ' ' -r '/' "
        "> {output}"

rule blast_search:
    input:
        "results/{sample}.fasta"
    output:
        "results/{sample}.blast"
    params:
        database = EXTRACTION_DB
    shell:
        "blastn "
          "-max_target_seqs 1 "
          "-db {params.database} "
          "-outfmt '6 qseqid sseqid pident length qcovhsp qstart qend sstart send evalue' "
          "-perc_identity 90 "
          "-qcov_hsp_perc 70 "
          "-query {input} "
          "-out {output} "
          "-num_threads {threads}"

rule extract_blast_hits:
    input:
        "results/{sample}.blast"
    output:
        "results/{sample}.hits"
    shell:
        "cut -f1 {input} | sort -u > {output}"

rule extract_mtags:
    input:
        fasta="results/{sample}.fasta",
        hits="results/{sample}.hits"
    output:
        "results/{sample}.mtags"
    shell:
        "seqkit grep -f {input.hits} {input.fasta} | "
        "seqkit replace -p $ -r ';sample={wildcards.sample}' "
        "> {output}"

rule map_mtags:
    input:
        "results/{sample}.mtags"
    output:
        "results/{sample}.uc"
    params:
        database = CLASSIFICATION_DB
    shell:
        "vsearch "
          "--usearch_global {input} "
          "--db {params.database} "
          "--uc {output} "
          "--id 0.97 "
          "--mincols 70 "
          "--strand both "
          "--top_hits_only "
          "--maxaccepts 0 "
          "--maxrejects 0 "
          "--threads {threads}"

