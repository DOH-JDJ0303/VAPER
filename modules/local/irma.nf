process IRMA {
    tag "${prefix}"
    label 'process_high'
    
    container "docker.io/staphb/irma:1.1.4"

    input:
    tuple val(meta), path(refs), path(reads)
    path module_template

    output:
    tuple val(meta), path('results/*.fasta'),  emit: consensus
    tuple val(meta), path('results/*.bam'),    emit: bam
    tuple val(meta), path('results/logs/'),    emit: logs
    tuple val(meta), path('results/figures/'), emit: figures
    //path "versions.yml",                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = "${meta.id}"

    """
    # determine IRMA path
    irma_path=\$(which IRMA)
    # create module
    mod=\$(shuf -er -n20  {A..Z} {a..z} {0..9} | tr -d '\n')
    mv ${module_template} \${irma_path}_RES/modules/\${mod}
    # combine references into single file
    cat ${refs} > \${irma_path}_RES/modules/\${mod}/reference/consensus.fasta
    # run IRMA
    IRMA \${mod} ${reads[0]} ${reads[1]} results
    # clean up
    rm -r \${irma_path}_RES/modules/\${mod}
    """
}
