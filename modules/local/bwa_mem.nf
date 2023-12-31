process BWA_MEM {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::bwa"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:219b6c272b25e7e642ae3ff0bf0c5c81a5135ab4-0' :
        'biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:219b6c272b25e7e642ae3ff0bf0c5c81a5135ab4-0' }"

    input:
    tuple val(meta), val(ref), path(reads)
    path  refs_tar

    output:
    tuple val(meta), val(ref), path('*.bam'),           emit: bam
    tuple val(meta), val(ref), path('*.coverage.txt'),  emit: coverage
    tuple val(meta), val(ref), path('*.stats.txt'),     emit: stats
    tuple val(meta), val(ref), path("*.read-list.txt"), emit: read_list

    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # setup for pipe
    set -euxo pipefail

    # extract references
    mkdir refs
    gzip -d ${refs_tar}
    tar -xvhf *.tar -C refs

    # index the reference
    bwa index refs/*/${ref}

    # run bwa mem, select only mapped reads, convert to .bam, and sort
    bwa mem -t ${task.cpus} refs/*/${ref} ${reads[0]} ${reads[1]} | samtools view -b -F 4 - | samtools sort - > ${prefix}-${ref}.bam

    # gather read stats
    samtools coverage ${prefix}-${ref}.bam > ${prefix}-${ref}.coverage.txt
    samtools stats --threads ${task.cpus} ${prefix}-${ref}.bam > ${prefix}-${ref}.stats.txt

    # get list of read headers for fastq extraction
    samtools view ${prefix}-${ref}.bam | cut -f 1 | sort | uniq > ${prefix}-${ref}.read-list.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa-mem: \$(bwa 2>&1 | grep "Version" | cut -f 2 -d ' ')
    END_VERSIONS
    """
}
