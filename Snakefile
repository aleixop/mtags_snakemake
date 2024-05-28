EXTRACTION_DB = "data/db/eukaryotesV4_92clust"
CLASSIFICATION_DB = "data/db/eukaryotesV4_v8.fasta"

rule format_input:
    input: 
        R1="data/input/{sample}_R1.fastq.gz", 
        R2="data/input/{sample}_R2.fastq.gz"
    output:
        "results/fasta/{sample}.fasta"
    params:
        min_length = 75
    shell:
        "seqkit seq -m {params.min_length} {input.R1} {input.R2} | "
        "seqkit fq2fa | "
        "seqkit replace -w 0 -p ' ' -r '/' "
        "> {output}"

rule blast_search:
    input:
        "results/fasta/{sample}.fasta"
    output:
        "results/blast/{sample}.blast"
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
        "results/blast/{sample}.blast"
    output:
        "results/blast/{sample}.hits"
    shell:
        "cut -f1 {input} | sort -u > {output}"

rule extract_mtags:
    input:
        fasta="results/fasta/{sample}.fasta",
        hits="results/blast/{sample}.hits"
    output:
        "results/mtags/{sample}.mtags"
    shell:
        "seqkit grep -f {input.hits} {input.fasta} | "
        "seqkit replace -p $ -r ';sample={wildcards.sample}' "
        "> {output}"

rule map_mtags:
    input:
        "results/mtags/{sample}.mtags"
    output:
        "results/vsearch/{sample}.uc"
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

rule make_consensus_taxonomy:
    input:
        map = "results/vsearch/{sample}.uc",
        script = "scripts/mtags_consensus_tax_v2.py"
    output:
        "results/vsearch/{sample}_filtered.uc"
    shell:
        "{input.script} "
          "--tax_separator '_' "
          "--tax_sense 'asc' "
          "--pair_separator '/' "
          "--output_file {output} "
          "{input.map}"
        
# rule make_otu_table:
#     input: 
#         filtered_map = "results/vsearch/{sample}_filtered.uc"
#         script = "scripts/make_otu_table.py"
#     output:
#         "results/otu_table/mtags_otu_table.tsv"

#         ${MAKE_OTU_TABLE} \
#   --sample_identifier 'barcodelabel=' \
#   --output_file ${OUT_TABLE}/${OUT_NAME}_otuTable.txt \
#   ${OUT_MAP}/${OUT_NAME}.uc
