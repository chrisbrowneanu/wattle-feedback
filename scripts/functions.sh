#!/bin/bash
# sh 11_data.sh
# reads in the files and generates vars for all scripts

# chris.browne@anu.edu.au - all care and no responsibility :)
# ===========================================================

source ./files/assignment_data.txt
source ./scripts/variables.txt
source ./scripts/variables.tmp

# trap used to exit within functions when requirements will cause errors
trap "exit 1" TERM
export TOP_PID=$$

reset_folders () {
	mkdir ./feedback/out/ 2> /dev/null 
	mkdir ./feedback/pdf/ 2> /dev/null 
	rm ./feedback/out/* 2> /dev/null 
	rm ./feedback/pdf/* 2> /dev/null 
}

reset_files () {
	rm ./files/*.tsv 2> /dev/null 
	rm ./feedback/wattle_upload.csv 2> /dev/null 
	rm ./feedback/wattle_upload_group.csv 2> /dev/null 
	rm ./files/*.tsv 2> /dev/null 

}

# update header labels from standard exports for continuity in scripts
# requires 3 argument:
#   $1: column to find
#   $2: text to replace
#   $3: filename
find_replace_header () {
	check_head=$(head -1 ./files/$3.tsv | grep "$1" | grep -c "^")
	if [[ $check_head -eq 1 ]]; then
		sed  -i "1s/$1/$2/" ./files/"$3".tsv
		printf "    \"%12s\" replaced by \"%12s\" in %s.csv\n" "$1" "$2" "$3"
	fi
}

# check that a value exists in a row
# requires 2 argument:
#   $1: column to find
#   $2: filename
check_header_row () {
	this_check=$(head -n1 ./files/$2.tsv | grep -c $1 )
	if [[ $this_check -lt 1 ]]; then
		printf "    %10s is missing from %10s - this may cause errors\n" $1 $2
	else
		printf "    %10s in %6s - OK\n" $1 $2
	fi
}

# check that a file exists in the files directory
# requires 1 argument:
#   $1: filename
check_file_exists () {
	if [[ -e ./files/$1.tsv ]]; then
		printf "    %10s exists - OK\n" $1
	else 
		printf "    %10s is missing - this will cause errors\n" $1
	fi
}

# generic find replace
# requires 3 argument:
#   $1: text to find
#   $2: text to replace
#   $3: filename
find_replace () {
	sed -i "s:$1:$2:g" ./files/"$3".tsv
}

# count the lines in a file
# requires 1 argument:
#   $1: filename
count_lines () {
	local return=$(grep -c "^" "$1")
	echo "$return"
}

# awk a value where the row and column are known
# requires 3 argument:
#   $1: row
#   $2: coluwn
#   $3: file
awk_row_column () {
	# check that there are 3 arguments
	if [[ -z "$3" ]] ; then
		printf "\tFATAL ERROR: add_row_column is missing an argument - exiting... val 1:$1 val 2:$2 val 3:$3\n" >&2 
		kill -s TERM $TOP_PID
	else
		local return=$( awk -F $'\t' -v col="$2" 'NR=='$1' {print $col}' $3 )
		echo "$return"
	fi
}

# awk a value where the row and column are known
# requires 3 argument:
#   $1: val
#   $2: column
#   $3: field
#   $4: file
awk_val_column () {
	# check that there are 4 arguments
	if [[ -z "$4" ]] ; then
		printf "\tFATAL ERROR: add_val_column is missing an argument - exiting... val 1:$1 val 2:$2 val 3:$3 val 4:$4\n" >&2
		kill -s TERM $TOP_PID
	else
		local return=$( awk -F $'\t' -v val="$1" -v col="$2" '$val ~ /'$3'/ {print $col}' $4)
		echo "$return"
	fi
}

# print a value to the console
# requires 1 argument:
#   $1: value to print
print_console_tab () {
	printf "%s..\t" "$1"
}

# print a progress value to the console
# requires 3 argument:
#   $1: value to print
#   $2: count
#   $3: total
print_console_progress () {
	printf "%03d / %03d %s..%30s\r" "$2" "$3" "$1" " "
}

# print any duplicates
# requires 2 arguments:
#   $1: column
#   $2: file
awk_find_duplicates () {
	awk -F $'\t' -v col="$1" 'FNR > 1 { print $col }' "$2" | sort | uniq -d
}


