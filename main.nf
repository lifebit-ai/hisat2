#!/usr/bin/env nextflow

reads="${params.reads}/${params.reads_prefix}_{1,2}.${params.reads_extension}"
Channel
    .fromFilePairs(reads, size: 2)
    .ifEmpty { exit 1, "Cannot find any reads matching: ${reads}" }
    .set { reads_ch }

if (params.fasta) {
    Channel
        .fromPath(params.fasta)
        .ifEmpty { exit 1, "FASTA annotation file not found: ${params.fasta}" }
        .set { ch_fasta_for_hisat_index }
} else if (params.hisat2_index) {
    Channel
        .fromPath(params.hisat2_index)
        .ifEmpty { exit 1, "Folder containing Hisat2 indexes for reference genome not found: ${params.hisat2_index}" }
        .set { hs2_indices }
    hisat2_index_name = Channel.value( "${params.hisat2_index_name}" )
} else {
    exit 1, "Please specify either `--fasta /path/to/file.fasta` OR `--hisat2_index /path/to/hisat2_index_folder` AND `--hisat2_index_name hisat2_index_folder/basename`"
}

/*
 * PREPROCESSING - Build HISAT2 index
 */
if(!params.hisat2_index){
    process makeHISATindex {
        tag "$fasta"
        container 'makaho/hisat2-zstd'

        input:
        file fasta from ch_fasta_for_hisat_index

        output:
        val("hisat2_index/${fasta.baseName}.hisat2_index") into hisat2_index_name
        file("hisat2_index") into hs2_indices

        script:
        """
        mkdir hisat2_index
        hisat2-build -p ${task.cpus} $fasta hisat2_index/${fasta.baseName}.hisat2_index
        """
    }
}

process hisat2 {
  tag "${name}"
  container 'makaho/hisat2-zstd'
  publishDir "${params.outdir}/HISAT2", mode: 'copy'

  input:
  set val(name), file(fastq) from reads_ch
  val(hisat2_index_name) from hisat2_index_name
  file(hisat2_index) from hs2_indices

  output:
  file("${name}.sam") into hs2_sam

  script:
  """
  hisat2 \
  -p ${task.cpus} \
  -x $hisat2_index_name \
  -1 ${fastq[0]} \
  -2 ${fastq[1]} \
  -S ${name}.sam
  """
}


