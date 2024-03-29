//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    refs        // file: /path/to/ref-list.csv

    main:
    // Create samplesheet channel
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { reads }

    // Create reference assembly channel
    Channel
        .fromPath(refs)
        .splitCsv( header: true, sep:',' )
        .map{ it -> create_ref_channel(it) }
        .set{ refs }

    emit:
    reads                                     // channel: [ val(meta), [ reads ] ]
    refs                                      // channel: [ val(meta), path(refs) ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.single_end = row.single_end.toBoolean()

    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    if (!file(row.fastq_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
    }
    if (meta.single_end) {
        fastq_meta = [ meta, [ file(row.fastq_1) ] ]
    } else {
        if (!file(row.fastq_2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
        }
        fastq_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
    }
    return fastq_meta
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_ref_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id = row.taxa
    meta.single_end = false

    // add path(s) of the fastq file(s) to the meta map
    def refs = []
    if (!file(row.assembly).exists()) {
        exit 1, "ERROR: Please check reference list -> Reference file does not exist!\n${row.assembly}"
    }else(
        refs = [meta, row.assembly]
    )

    return refs
}
