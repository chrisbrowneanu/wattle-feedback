#!/bin/sh
# sh marks_feedback.sh
# reads in the files and generates vars for all scripts
#
# chris.browne@anu.edu.au - all care and no responsibility :)
# ===========================================================

# load in the functions
source ./scripts/functions.sh

# check that files used in the script exist
printf "checking that the required files exist..\n" 2>&1 | tee -a $log
check_file_exists marks
check_file_exists fields

# report to the console
printf "sorting the following fields for processing..\n" 2>&1 | tee -a $log

# check for all fields used in this script
# check for crit and comment fields from fields.tsv
field_count=$(count_lines $fields)
for (( l=2; l<=$field_count; l++ )); do
	# get the value of the first column
	this_record=$(awk_row_column "$l" "$f_field" "$fields")
	check_header_row $this_record marks
done

# create an array for the crit columns from data.txt
read -a crit_arr <<< "$(grep "m_Crit.*" $tmp | sed 's/=.*//g;' | sort | tr '\n' ' ')"
# create an array for the comment columns from data.txt
read -a comment_arr <<< "$(grep "m_Comment.*" $tmp | sed 's/=.*//g;' | sort | tr '\n' ' ')"

# check the marks list
this_marks_list=m_"$marks_list"

# starting the main loop
printf "creating feedback files for..\n" 2>&1 | tee -a $log

# count the records in marks
count_records=$( count_lines "$marks" )
# output the data for each record
for (( i=2; i<=$count_records; i++ )); do

	this_record=$( awk_row_column "$i" "${!this_marks_list}" $marks )
	this_user=${this_record/ */}
	this_out="./feedback/out/$this_user"; > "$this_out.md"
	
	# print to console
	print_console_progress "$this_record" "$i" "$count_records"

	# print the output file header
	DATE=$(date "+%Y-%m-%d %H:%M")
	echo "---" > "$this_out.md"
	echo "title: $this_record" >> "$this_out.md"
	echo "date: updated $DATE" >> "$this_out.md"
	echo "subtitle: $assignment_short" >> "$this_out.md"
	echo "course: $assignment_course" >> "$this_out.md"
	echo "semester: $assignment_semester" >> "$this_out.md"
	cat ./includes/pdf/front_plain.md >> "$this_out.md"
	echo ""  >> "$this_out.md"

	# include the first headings
	printf "# ${this_record/_/\ }{-}\n\n" >> "$this_out.md"
	printf "## Indicators against criteria{-}\n\n" >> "$this_out.md"
	printf "%s" "$message_indicators" >> "$this_out.md"
	echo "" >> "$this_out.md"

	# get the values of the crit
	for this_crit in "${crit_arr[@]}"; do
		# set the values needed for each crit from fields
		this_field=${this_crit/m_/}; this_text=$(awk_val_column "$f_field" "$f_text" "$this_field" "$fields"); this_label=$(awk_val_column "$f_field" "$f_label" "$this_field" "$fields")
		# look up this value from the marks
		this_value=$(awk_row_column "$i" "${!this_crit}" "$marks" )
		# find the image placeholder
		this_img=$(awk_val_column "$c_ref" "$c_img" "$this_value" "$crit_levels")
		# print to $this_out.md
		printf "\n## %s{-}\n*%s*\n\n" "$this_text" "$this_label" >> $this_out.md
		if [[ $this_img == "" ]]; then
			printf "(No value selected)\n" >> $this_out.md
		else
			printf "![](./includes/scales/%s)\n" $this_img >> $this_out.md
		fi
		# clear the values
		this_field=""; this_text=""; this_label=""; this_img=""; this_value="";
	done

	# get the values of the comments
	for this_comment in "${comment_arr[@]}"; do
		# set the values needed for each comment
		this_field=${this_comment/m_/}; this_text=$(awk_val_column "$f_field" "$f_text" "$this_field" "$fields"); this_comment=$(awk_row_column "$i" "${!this_comment}" "$marks")
		# print to $this_out.md
		printf "\n## %s{-}\n\n" "$this_text" >> $this_out.md
		if [[ $this_comment == "" ]]; then
			printf "(No comment provided)" >> $this_out.md
		else
			printf "%s" "$this_comment" | iconv -c -f utf-8 -t ascii//TRANSLIT | html2text --escape-all | sed 's/<[^>]*>//g' | awk '!seen[$0]++' >> $this_out.md
		fi
		# clear the values
		this_field=""; this_text=""; this_comment="";
	done

	# zap common text gremlins
	pandoc -s -o $this_out.md $this_out.md
	if [[ $print_to_pdf == "yes" ]] || [[ $print_to_pdf == "y" ]]; then
		pandoc $this_out.md -o ./feedback/out/$this_user.pdf --template ./includes/pdf/anu_cecs.latex
	fi
done


# give the console a break...
printf "\n"