# hisat2

Example command to run the pipeline:
1) With indexing:
```
nextflow run main.nf --reads testdata/reads/ --fasta testdata/reference/genome.fa
```

2) If already indexed:
```bash
nextflow run main.nf --reads testdata/reads/ --hisat2_index testdata/hisat2_index/ --hisat2_index_name hisat2_index/genome.hisat2_index
```