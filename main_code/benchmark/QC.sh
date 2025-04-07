# Good to see you there!
# We start analyzing Nanopore date from raw fast5 or POD5
# We can easily converting them by
pip install pod5
pod5 convert fast5 ./<fast5_dir>/*.fast5 --output pod5/

# This is because Dorado require POD5 for optimal performance
# Easily download Dorado from Github with the newest version
# wget -c https://cdn.oxfordnanoportal.com/software/analysis/dorado-0.5.0-linux-x64.tar.gz
# tar -xzvf dorado-0.5.0-linux-x64.tar.gz | rm dorado-0.5.0-linux-x64.tar.gz
# export PATH=/home/lu/dorado-0.5.0-linux-x64/bin:$PATH
export PATH=/<your_path>/dorado-0.5.0-linux-x64/bin:$PATH
# Download the latest model for basecall
dorado download --model dna_r10.4.1_e8.2_400bps_sup@v4.1.0 #for PAO1r10
dorado download --model dna_r10.4.1_e8.2_400bps_fast@v4.3.0 #for DC3000
dorado download --model dna_r9.4.1_e8_sup@v3.6
dorado basecaller <model> pod5/ > raw.bam

## run dorado basecaller for each sample
## For R10.4.1 5kHz
dorado basecaller dna_r10.4.1_e8.2_400bps_sup@v4.3.0 -r pod5/ > basecall.bam 
## For R10.4.1 4kHz (ecoli, kp)
dorado basecaller ../dna_r10.4.1_e8.2_400bps_sup@v4.1.0 -r all.pod5 >  basecall.bam 

# Extract the fastq from bam, this is the basecalled fastq file
# conda install -c bam2fastq
bam2fastq -o <name.fastq> --no-filtered raw.bamsamtools bam2fq basecall.bam>final.fastq

## run giraffe 
giraffe estimate --input  final.fastq --cpu 64
giraffe observe --input  final.fastq --cpu 64 --ref ./1448a.fasta

## run minimap2
minimap2 --MD -t 32 -ax map-ont 1448a.fasta.fasta final.fastq | samtools view -hbS -F 3844 - | samtools sort -@ 32 -o genomic.bam 

# Evaluate the unfiltered bam
samtools view -hbS -F 3328 <name.sam> > <name.bam>
samtools sort -@ 8 -o <name.sorted.bam> <name.bam> 
samtools index <name.sorted.bam>
samtools depth <name.sorted.bam> > <name_depth.txt>
# Or we can do this together
name=<yourfilename>
for i in $name; do samtools view -hbS -F 3328 ${i}.sam > ${i}.bam; samtools sort -o ${i}.sorted.bam ${i}.bam; samtools index ${i}.sorted.bam; samtools depth ${i}.sorted.bam > ${i}_depth.txt; rm ${i}.bam; done

# QC
python count_mapped_read_base.py <name>
# Check how many sites has coverage lower than 50
awk '$3 < 50' <name_depth.txt> > lowerthan50.txt
wc -l lowerthan50.txt 
# Give average and median coverage
awk '{ sum += $3; arr[NR] = $3 } END { avg = sum / NR; if (NR % 2 == 1) median = arr[(NR + 1) / 2]; else median = (arr[NR / 2] + arr[NR / 2 + 1]) / 2; print "Average：" avg; print "Median：" median }' <name_depth.txt>
