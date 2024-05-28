process IVAR_CONSENSUS {
    tag "${prefix}"
    label 'process_high'

    conda "bioconda::ivar"
    container "staphb/ivar:1.4.2"

    input:
    tuple val(meta), val(ref_id), path(bam)

    output:
    tuple val(meta), val(ref_id), path('*.fa'),  emit: consensus
    path "versions.yml",                         emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = "${meta.id}_${ref_id}"

    """
    # setup for pipe
    set -euxo pipefail

    # create mpilup and call consensus
    samtools mpileup -aa -A -Q 0 -d 0 ${bam} | \\
       ivar consensus \\
       -p ${prefix} \\
       -m ${params.cons_depth} \\
       -n ${params.cons_amb} \\
       -t ${params.cons_ratio} \\
       -q ${params.cons_qual} \\
       ${args}
    
    sed -i 's/>.*/>${prefix}/g' ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools 2>&1 | grep "Version" | cut -f 2 -d ' ')
        ivar: \$(ivar version | head -n 1)
    END_VERSIONS
    """
}
