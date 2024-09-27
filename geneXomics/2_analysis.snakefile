import os
import yaml

CONFIG_FILE = config["paths"]["multi_config_file"]

rule all:
    input:
        "analysis_done"

rule run_cellranger_multi:
    input:
        config_file=CONFIG_FILE
    output:
        touch("analysis_done")
    params:
        multi_id="loka_analysis",
        output_dir="/storage-matrix/projects/loka/aws_bucket/analysis/",
        cores=30  # Define the number of cores
    shell:
        """
        cellranger multi --id {params.multi_id} --csv {input.config_file} \
            --output-dir {params.output_dir} \
            --localcores={params.cores}

        touch {output}
        """