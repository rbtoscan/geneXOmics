# geneXOmics
 


## Instructions for installing dependencies

Installing Cellranger 8.0.1

```
# navigate to your preferred workspace and create the following folders accordingly
mkdir apps ref_data input_data 

# installing cell ranger 8.0.1
cd apps

# download cell ranger via wget
wget -O cellranger-8.0.1.tar.gz "https://cf.10xgenomics.com/releases/cell-exp/cellranger-8.0.1.tar.gz?Expires=1726259616&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=Ll8hCgqkYrA6WGiYWNmPq3Znq-t~~YLu4O~jfr4a4V9q43fnj3if2yeZjMD0UFuAINro4rfofTKcZmL3Bm5HGMb0AehvYXZ1TZkAGa8TUQuHcyQEPFYzZZcxsBZCOmz4cb3sqoxP559LOdnT~iEbHFtjB2255FecCFxyrMdOGEyoRX~6RDaAnTYFBB4eHcIhyyRdrSipeVKU8VqYTF2dEO~1SuZ8bvvKp8R3i4PquHlbScVTuMKR9lhDSslrTHAJY~B07zx-CyK4iEvszUBulD0ch94YyW5MMS8JtrwMkKRJT0YMH1qWezV~9A0GXpXt2vYqy5OjzWzR7rWHh1HXIQ__"


# decompressed gzipped file
tar -xvf cellranger-8.0.1.tar.gz

# export executables to environment path. Adjust path accordingly
export PATH=path/to/cellranger-8.0.1/bin/:$PATH

# for a permanent solution, please add this to your .bashrc or .bash_profile file in the home directory

```

Downloading reference genome

```
# navigate to the dedicated folder for reference genomes
cd ../ref_data

# download hg38 reference genome
wget "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2024-A.tar.gz"

# unpack reference genome
tar -xvf refdata-gex-GRCh38-2024-A.tar.gz

```
Create conda environment for snakemake installation
```
# create conda 
conda create -n loka

# activate it
conda activate loka

# install snakemake
conda install -c bioconda snakemake


```
Setting up toy models for experimentation
```
# navigate to dedicated directory for input data
cd ../input_data

# download bcl example file
wget 'https://cf.10xgenomics.com/supp/cell-exp/cellranger-tiny-bcl-1.2.0.tar.gz' 

# unpack
tar -xvf cellranger-tiny-bcl-1.2.0.tar.gz

# download layout file
wget 'https://cf.10xgenomics.com/supp/cell-exp/cellranger-tiny-bcl-simple-1.2.0.csv' 

# download sample sheet
wget 'https://cf.10xgenomics.com/supp/cell-exp/cellranger-tiny-bcl-samplesheet-1.2.0.csv'

```


## Example inputs and outputs of the pipeline

Several files are used as input and generated as intermediary files throughout the whole processing of this pipeline. Below, only the main files are listed.

1) BCL Files: the base-calling files are binary files generated by the sequencer and are produced by the sequencer. Please see example_files/cellranger-tiny-bcl-1.2.0. Those can be freely downloaded here: [https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/mkfastq.
](url)

2) Sample sheet: These binary base-calling files are generated by the sequencer. Please see example_files/cellranger-tiny-bcl-samplesheet-1.2.0.csv.

3) Fastq files: Text files generated after demultiplexing, containing headers, nucleotide sequences, and quality scores. Please see inside example_files/fastq.

4) BAM files: sequenced alignment files containing information on the mapping of sequenced reads to a reference genome or genomic region of interest. Those files were not added to this repository given significant size, but can be made readily available upon request.

5) CellRanger multi output files: The final outputs can be seen in example_files/cell-ranger-multi-output. Those include a metrics overview (metrics_summary.csv) and a visual report that summarizes the key results, such as metrics, UMI counts, gene expression, features and some interactive plots. Those were generated using the following dataset, freely available here:[ https://www.10xgenomics.com/datasets/10k-k562-transduced-with-small-guide-library-5-ht-v2-0-chromium-x-2-standard
](url)




## Guide



The whole pipeline presented in this repository is divided into three main steps: runfolder copying, flowcell demultiplexing and dataset analysis.

Design:
- The overall strategy implemented here was to crop out unecessary copying procedures and automate chained processes using snakemake. 


Some considerations:

- To my knowledge,  there is no publicly available BCL dataset that can be used for both primary and secondary analysis within the template of the proposed experiment (perturb-Seq). Thefore, the process was split into two pipelines that need to be run independently.
- For production use, access to a real AWS bucket is required. In this repository, the AWS bucket is simulated as a folder, and the aws sync command is replaced with a simple cp command.
- This pipeline is a simple sketch of what a real application should look like. There are several bottlenecks that should be taken into account when migration this approach from test to production. For instance, the current snakemake pipeline takes into account that the demuxing will occur flawlessly which is hardly the case. Issues may occur during sequencing prep, lab pooling, sample sheet generation, etc. Additional quality-control steps should be added in order to achieve a robust pipeline that assures that the desired output is generated without human intervention.
- Due to time limitation, the rotuines for metadata transfer from Benchling/SmartSheet to Quilt were not implemented here. They were however envisioned in the visual diagram present in this repository.


```
# ! Make sure you have bcl2fastq and cellranger executables present in your path and organize your filesystem accordingly

# your workspace should look like tis
$ tree -L 1
.
|-- apps (where our apps were installed - please see installation section above)
|-- aws_bucket (simulating our AWS infrastructure)
|-- geneXomics (scripts)
|-- ref_data  (human genome version hg38 used for mapping)
|-- remote_sequencer (folder simulating genexOmics facility containing sequencers)


# Inside the geneXomics folder, please make sure you have the following files
$ tree geneXomics/
geneXomics/
|-- 0_copy.py
|-- 1_demux.snakefile
|-- 2_analysis.snakefile
`-- config.yaml

# Inside the aws_bucket, please make sure you have the following folders.
$ tree aws_bucket/ -L 1
aws_bucket/
|-- analysis
|-- demux
|-- fastqs
|-- ready_for_demux
|-- samplesheets
`-- sequencers


# If the RTAComplete.txt file exists, copies flowcell from geneXomics to AWS infrastructure.
# This script should be executed as a cron job so that it can constantly check for newly sequenced flowcells present in geneXOmics' sequencing facility
python 0_copy.py


# This part of the pipelines performs the demultiplexing of the BCL files into fastq files if the copy of the BCL files was succesfully done
snakemake --snakefile 1_demux.snakefile


# This part of the pipeline performs the analysis of the fastq files utilizing cellranger multi if the fastqs are present in their designated folder
snakemake --snakefile 2_analysis.snakefile

```

