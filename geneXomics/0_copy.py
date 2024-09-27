import os
import shutil
import yaml

# load config from YAML
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

SEQ_PATH = config["paths"]["seq_path"]
AWS_BUCKET = config["paths"]["aws_bucket"]
READY_FOR_DEMUX = config["paths"]["ready_for_demux"]

SAMPLE_SHEETS = os.path.join(os.path.dirname(AWS_BUCKET), "samplesheets")

def check_and_copy_flowcells():
    # create necessary folders if they do not exist
    if not os.path.exists(READY_FOR_DEMUX):
        os.makedirs(READY_FOR_DEMUX)
    if not os.path.exists(SAMPLE_SHEETS):
        os.makedirs(SAMPLE_SHEETS)

    # for each sequences from genexomics
    for sequencer in ["A", "B", "C", "D"]:
        # get path
        sequencer_path = os.path.join(SEQ_PATH, sequencer)
        
        for flowcell_dir in os.listdir(sequencer_path):
            flowcell_path = os.path.join(sequencer_path, flowcell_dir)
            if os.path.isfile(os.path.join(flowcell_path, "RTAComplete.txt")):
                dest_path = os.path.join(AWS_BUCKET, sequencer, flowcell_dir)
                
                # copy sample sheet to "sample_sheets" folder at the root level of aws_bucket
                sample_sheet = f"{flowcell_path}_samplesheet.csv"
                if os.path.isfile(sample_sheet):
                    # add the sequencer name as a prefix to the sample sheet
                    sample_sheet_dest = os.path.join(SAMPLE_SHEETS, f"{sequencer}_{flowcell_dir}_samplesheet.csv")
                    shutil.copyfile(sample_sheet, sample_sheet_dest)
                    print(f"Copied sample sheet {sample_sheet} to {sample_sheet_dest}")

                if not os.path.exists(dest_path):
                    print(f"Copying {flowcell_path} to {dest_path}...")
                    shutil.copytree(flowcell_path, dest_path)
                    
                    # mark as ready for demultiplexing - Snakemake needs this falg
                    ready_file = f"{READY_FOR_DEMUX}/{sequencer}_{flowcell_dir}.ready"
                    with open(ready_file, 'w') as f:
                        f.write("")
                    print(f"Flowcell {flowcell_dir} marked as ready for demux.")

if __name__ == "__main__":
    check_and_copy_flowcells()