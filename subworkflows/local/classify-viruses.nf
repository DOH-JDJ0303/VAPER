//
// Check input samplesheet and get read channels
//

include { SHOVILL as SHOVILL               } from '../../modules/nf-core/shovill/main'
include { KRAKEN2 as KRAKEN2               } from '../../modules/local/kraken2'
include { MINIMAP2_ALIGN as MINIMAP2       } from '../../modules/nf-core/minimap2/align/main'
include { SUMMARIZE_TAXA as SUMMARIZE_TAXA } from '../../modules/local/summarize_taxa'


workflow CLASSIFY_VIRUSES {
    take:
    reads // channel: [meta, reads]
    refs  // channel: [refs]

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: Run Shovill
    //
    SHOVILL (
        reads
    )
    ch_versions = ch_versions.mix(SHOVILL.out.versions.first())

    //
    // MODULE: Run Kraken2
    //
    KRAKEN2 (
        SHOVILL.out.contigs,
        params.k2db
    )

    //
    // MODULE: Map contigs to the references
    //
    MINIMAP2 (
        SHOVILL.out.contigs,
        refs.map{ refs -> ["reference",refs] },
        false,
        false,
        false
    )

    //
    // MODULE: Summarize taxonomy
    //
    KRAKEN2
        .out
        .output
        .map{ meta, output, cov -> [meta, output, cov] }
        .set{ k2_output }
    MINIMAP2
        .out
        .paf
        .map{ meta, paf -> [meta, paf] }
        .join(k2_output, by: 0)
        .set{ taxa_files }

    SUMMARIZE_TAXA (
        taxa_files
    )

    SUMMARIZE_TAXA
        .out
        .ref_list
        .splitCsv(header: false)
        .map{ meta, ref -> [meta, ref.get(0)] }
        .join(reads.map{ meta, reads -> [meta, reads] }, by: 0, remainder: true)
        .set{ ref_list }

    emit:
    ref_list   // channel: [ val(meta), val(reference), path(reads) ]
    versions = SHOVILL.out.versions // channel: [ versions.yml ]
}