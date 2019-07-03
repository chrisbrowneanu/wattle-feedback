#!/bin/sh
# sh 13_data_wattle.sh
# creates a file ready to upload to Wattle
#
# chris.browne@anu.edu.au - all care and no responsibility :)
# ===========================================================


# load in the functions
source ./scripts/functions.sh

# create a csv file to upload to the gradebook
printf "ID,mark,comment%s\n" > ./feedback/wattle_upload.csv
if [[ $assignment_type == "group" ]]; then
	printf "ID,mark,comment,group%s\n" > ./feedback/wattle_upload_group.csv
fi

# organising the files for uploading to wattle
printf "organising the files for wattle upload..\n" 2>&1 | tee -a $log

student_count=$(count_lines $students)

for (( i=2; i<=$student_count; i++ )); do
	# get this_user
	this_s_user=$(awk_row_column "$i" "$s_user" "$students" )
	this_m_grade=$(awk_val_column "$m_List_Name" "$m_Grade_Final" "$this_s_user" "$marks")

	# print any missing grades to the console
	if [[ $this_m_grade == "" ]]; then
		printf "%10s $this_s_user is missing a final grade\n"
	fi

	# generate a secret for file renaming
	this_secret=$(echo "$this_s_user" "$this_assignment_short" | md5sum | cut -d " " -f 1 | tr -d "\n")

	# check that a feedback file exists from the data_sort.sh file
	if [[ -e ./feedback/out/$this_s_user.pdf ]]; then
		# copy the output file to the pdf directory with the secret name
		mv ./feedback/out/$this_s_user.pdf ./feedback/pdf/$this_s_user-$this_secret.pdf
		# print the feedback comments
		printf "$this_s_user,$this_m_grade,<a href=\042$assignment_url/$this_s_user-$this_secret.pdf\042>$assignment_short PDF Feedback</a></strong>\n" >> ./feedback/wattle_upload.csv
	else
		# just print the feedback comments
		printf "$this_s_user,$this_m_grade,Nil submission\n" >> ./feedback/wattle_upload.csv
		printf "%10s $this_s_user did not submit\n"
	fi
	# reset the variables
	this_s_user=""; this_secret=""; this_mark=""
done
