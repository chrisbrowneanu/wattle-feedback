#!/bin/bash
# sh 11_data_columns.sh
# reads in the files and generates vars for all scripts
#
# chris.browne@anu.edu.au - all care and no responsibility :)
# ===========================================================


# load in the functions
source ./scripts/functions.sh

# create data file
> $tmp

printf "reading in csv files in directory \n" 2>&1 | tee $log
csv_arr=( $(ls ./files/ | grep '.csv$' | sed 's/.csv$//') )

# convert csvs to tsvs for processing
printf "organising csv files in directory \n" 2>&1 | tee -a $log
printf "available csvs are: \n" 2>&1 | tee -a $log

# this loop creates the tsvs and reports status to the console
for file in "${csv_arr[@]}"; do
	# convert csv to tsv for processing
	csv2tsv ./files/$file.csv > ./files/$file.tsv 2> /dev/null 
	find_replace_header " " "_" "$file"
	# count the number of entries 
	this_record_count=$( count_lines ./files/$file.tsv )
	# count the number of columns
	read -a this_array <<< "$(head -n1 ./files/$file.tsv | tr '\t' ' ')"; this_column_count=${#this_array[@]}
	# check to see if there are any entries
	if [[ $this_record_count -lt 2 ]]; then 
		# report that a file is empty
		printf "    %12s.csv has %2d columns and %3d entries -- this may cause errors in the scripts\n" "$file" "$this_column_count" "$this_record_count" 2>&1 | tee -a $log
	else	
		# report the number of entries
		printf "    %12s.csv has %2d columns and %3d entries\n" "$file" "$this_column_count" "$this_record_count" 2>&1 | tee -a $log
		# make the files accessible variables in data.txt
		printf "$file=./files/$file.tsv%s\n" >> $tmp 
	fi

	# reset this_record_count
	this_record_count=""; this_column_count="";
done

printf "fixing up csvs and extracting header rows\n" 2>&1 | tee -a $log

# this loop makes changes to the tsvs and reports the headers to the data file
for file in "${csv_arr[@]}"; do

case $file in
	students)
		# fix up common misplacements in files; should eventually be fixed at the source     
	    find_replace_header "First" "first" "$file"
	    find_replace_header "First_name" "first" "$file"
		find_replace_header "Surname" "last" "$file"
		find_replace_header "Uni_ID" "user" "$file"
		find_replace_header "Uni ID" "user" "$file"
	    ;;    
	marks)
		# fix up common misplacements in files; should eventually be fixed at the source
	    find_replace_header "Username" "marker_id" "$file"
	    find_replace_header "User" "marker_name" "$file"
	    find_replace_header " " "_" "$file"
	    # replace forward slashes with underscores for processing
	    find_replace "/" "_" "$file"
	    ;;
	crit_levels)
		# replace forward slashes with underscores for processing
		find_replace "/" "_" "$file"
		;;
	*)              
	esac 

	# read in header row as an array
	read -a this_array <<< "$(head -n1 ./files/$file.tsv | tr '\t' ' ')"

	# add the columns in the header rows to the data file 
	# variables are automatically called "first letter of filename"_"column name"
	for arg in "${this_array[@]}"; do 
		printf "${file:0:1}_$arg=$(awk -v RS='\t' '/^'"$arg"'$/{print NR; exit}' "./files/$file.tsv")%s\n" >> "$tmp"
	done 
done

# load in functions again to do checks
source ./scripts/functions.sh

# check for names and duplicate fields in the marks.csv
printf "using the $marks_list field to create the feedback\n" 2>&1 | tee -a $log
check_header_row $marks_list marks

# get the column number for the selected list in variables.txt
this_marks_list=m_"$marks_list"

# count whether there are duplicate entries
printf "looking for duplicate entries in marks.csv\n" 2>&1 | tee -a $log
duplicates_check=$(awk -F $'\t' -v col="${!this_marks_list}" 'FNR > 1 { print $col }' ./files/marks.tsv | sort | uniq -d | grep -c "^")

# print a warning message if there are duplicates
if [[ $duplicates_check -gt 0 ]]; then
	printf "there are duplicates in marks.csv. This might cause confusion.\nduplicates are:\n" 2>&1 | tee -a $log
	awk_find_duplicates ${!this_marks_list} $marks
	# reprocess the file without duplicate entries
	awk -v col="${!this_marks_list}" '!a[$col]++' $marks > $marks.tmp && mv $marks.tmp $marks
	printf "the one entry for these students will be used in the output\n ** PLEASE REMOVE DUPLICATE ENTRIES FROM ./files/marks.csv\n" 2>&1 | tee -a $log
else
	printf "there are no duplicates - OK\n"
fi


# make a list of groups 
# echo "groups" > ./files/teams.tsv
# echo "teams" > ./files/teams.tsv
# awk 'FNR > 1 { print $1 }' ./files/groups.tsv | sort --uniq >> ./files/teams.tsv


# make a list of radio fields, used  in the javascript
# printf "field\tlevel\tlabel\tweight\ttype\n" > "$fields_radio"
# awk '/radio/' "$fields" >> "$fields_radio"

printf "loading data complete           \n"


