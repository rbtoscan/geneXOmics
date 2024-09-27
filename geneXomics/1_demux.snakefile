import os
import yaml

# load config from YAML
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

AWS_BUCKET = config["paths"]["aws_bucket"]
READY_FOR_DEMUX = config["paths"]["ready_for_demux"]
DEMUX = config["paths"]["demux_output"]
FASTQS = config["paths"]["fastqs_copied"]
SAMPLE_SHEETS = os.path.join(os.path.dirname(AWS_BUCKET), "samplesheets")

# get list of flowcells ready for demuxing
def get_ready_flowcells():
    flowcells = []
    for file in os.listdir(READY_FOR_DEMUX):
        if file.endswith(".ready"):
            flowcells.append(file.replace(".ready", ""))
    return flowcells



rule all:
    input:
        expand(f"{DEMUX}/{{flowcell}}/demux_done", flowcell=get_ready_flowcells()),
        expand(f"{DEMUX}/{{flowcell}}/fastq_copy_done", flowcell=get_ready_flowcells())

rule copy_fastqs:
    input:
        demux_done=lambda wildcards: f"{DEMUX}/{wildcards.flowcell}/demux_done"
    output:
        touch(f"{DEMUX}/{{flowcell}}/fastq_copy_done")
    params:
        fastqs_output=lambda wildcards: f"{FASTQS}",
        demux_dir=lambda wildcards: f"{DEMUX}/{wildcards.flowcell}"  # The demux directory where the fastqs are stored
    shell:
        """
        # create fastqs output directory
        mkdir -p {params.fastqs_output}

        # find and copy all .fastq.gz files, renaming them with the <sequencer>_<flowcell> prefix
        find {params.demux_dir} -name "*.fastq.gz" | while read file; do
            base=$(basename $file)
            cp $file {params.fastqs_output}/{wildcards.flowcell}_$base
        done

        # touch the fastq_copy_done file to signal completion
        touch {output}
        """


rule demux:
    input:
        ready_file=lambda wildcards: f"{READY_FOR_DEMUX}/{wildcards.flowcell}.ready",
        flowcell_dir=lambda wildcards: f"{AWS_BUCKET}/{wildcards.flowcell.split('_')[0]}/{wildcards.flowcell.split('_')[1]}",
        sample_sheet=lambda wildcards: f"{SAMPLE_SHEETS}/{wildcards.flowcell}_samplesheet.csv"
    output:
        f"{DEMUX}/{{flowcell}}/demux_done"
    params:
        clean_id=lambda wildcards: wildcards.flowcell.replace('.', '_'),  # Sanitize the ID
        output_dir=lambda wildcards: f"{DEMUX}/{wildcards.flowcell}"  # Correct output path
    shell:
        """
     
        cd {params.output_dir} && \
        # Cell Ranger command for demultiplexing with the sample sheet
        cellranger mkfastq --id={params.clean_id}_demux \
                           --run={input.flowcell_dir} \
                           --csv={input.sample_sheet} \
                           --output-dir={params.output_dir} \
                           --jobmode=local
                           
        touch {params.output_dir}/demux_done
        """