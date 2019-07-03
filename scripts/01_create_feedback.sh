#!/bin/sh
# bash 01_create_feedback.sh
# runs all the scripts required to create the feedback files
#
# chris.browne@anu.edu.au - all care and no responsibility :)
# ===========================================================


# load in variables
> ./scripts/variables.tmp
source ./scripts/functions.sh

# reset folders and files
reset_folders
reset_files

# process the columns needed to run the scripts
bash ./scripts/11_data_columns.sh

# extract the crit/comment fields from the marks file
bash ./scripts/12_marks_feedback.sh

# create csv to upload to wattle
bash ./scripts/21_wattle_csv.sh