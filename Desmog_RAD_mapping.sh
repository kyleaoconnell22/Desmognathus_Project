#move files from secapr bwa run
#script list2 should be samples_remapped (dir names) from mapped dirs
for x in `cat scriptlist2`; do sample="$(cut -d'_' -f1 <<<"$x")"; mv $x/including_duplicate_reads/$sample.sorted.bam .; done


module load bioinformatics/samtools
module load bioinformatics/bcftools
#scriptlist 1 will be just the bam file prefix ls -1 *.bam > scriptlist
#map bam
echo 'mapping bwa mem'
for x in `cat scriptlist`; do echo 'mapping' $x; bwa mem -M -t 12 reference/Desmog_ref.fa raw_DesmogRAD/$x/$x-READ1.fastq > $x.sam || clean_up $x.sam; done
#convert sam to bam
for x in `cat scriptlist`; do samtools view -S -b $x.sam > $x.bam | samtools sort $x.bam -o $x.sorted.bam
#call concensus from bam file
echo 'calling consensus'
for x in `cat scriptlist`; do echo 'running mpileup on:' $x; samtools mpileup -Q 20 -q 5 -d 5000 -uf reference/Desmog_ref.fa $x.sorted.bam | bcftools call -c | perl vcfutils.pl  vcf2fq -d 3 -Q 20 -l 1 > consensus_$x.fq || clean_up consensus_$x.fq; done
#convert fastq to fasta
echo 'converting fastq to fasta'
for x in `cat scriptlist`; do echo 'running fasta conversion on:' $x; python fastqtofasta.py consensus_$x.fq consensus_$x.fasta || clean_up consensus_$x.fasta; done
#remove lowercase
for x in `cat scriptlist`; perl -e 'while(<>) { if ($_ =~ /^>.*/) { print $_; } else { $_ =~ tr/acgtryswkmbdh/N/; print $_;}}' < consensus_$x.fasta > consensus_uppercase_$x.fasta || clean_up consensus_uppercase_$x.fasta; done


