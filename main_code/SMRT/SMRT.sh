###activate environment (change to your location with smrttools)
export PATH=$PATH:~/Downloads/smrtlink/smrtcmds/bin

##assemble[nor required if we do have reference files]
test_1:
flye --plasmids --pacbio-corr Psa_M228.fastq.gz -g 6.6m -o ./outdir -t num
##alignment(subreads)
pbmm2 index ref.fasta ref.mmi
pbmm2 align ref.fa subreads.bam --sort aligned.bam
##alignment(ccs, hifi)
#conda install -c bioconda pbtk
ccs-kinetics-bystrandify ccs.bam ccs_out.bam
pbvalidate ccs_out.bam
pbmm2 index ref.fasta ref.mmi
pbmm2 align ref.fa ccs_out.bam --sort aligned.bam
pbvalidate aligned.bam
##call modification
pbindex aligned.bam
ipdSummary aligned.bam --reference ref.fa --identify m6A --methylFraction --gff m6A.gff -j 10 --pvalue 0.001 --log-level INFO
##motif (moftifMaker or MEME)
motifMaker find -f ref.fa -g m6A.gff -o m6A_motif.csv
motifMaker reprocess -f ref.fa -g m6A.gff -m m6A_motif.csv -o m6A_motif.gff
