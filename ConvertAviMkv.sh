#! /usr/bin/env bash 
# Title   :  ConvertAviMkv.sh 
# Author  :  JamesIsIn 20201015  Do something nice today.  

# Purpose :  Recursively convert AVI files to MKV files.   
# 

## 

################## 
#  Declarations  # 

declare rootAVIFolderPath="${1}" 
declare -a A_aviToConvert 
declare -a A_foldersWithAVIfiles 

# # debugging 
# 
# # 

## 

############### 
#  Functions  # 

function func_EnterToContinue() { 
	# just waits for the user before proceeding; a timer could be added later 
	read -rp "Press [Enter] to continue…  " 
} 

function func_getContainingFolder() { 
	# obtain directory in which to work 
	printf '%s\n' "" "========================================" "" "Hello.  " "" 
	printf '%s\n' "Crtl-c at any time abandons any changes and exits the script.  " "" 
	func_EnterToContinue 
	while [ ! -d "${rootAVIFolderPath}" ] ; do 
		read -rep "Please provide the containing folder for find to recursively search for AVI files:  " -i "${rootAVIFolderPath}" rootAVIFolderPath 
		# expand the ~/ if it gets submitted 
		rootAVIFolderPath="${rootAVIFolderPath/#~/${HOME}}" 
		# fix spaces to be used in a quoted variable 
		rootAVIFolderPath="${rootAVIFolderPath//\\/}" 
		if [ -d "${rootAVIFolderPath}" ] ; then 
			printf '%s\n' "I have confirmed this is a directory.  " 
			printf '%s\n' "${rootAVIFolderPath}" "" 
		else 
			printf '%s\n' "I cannot confirm this is a directory.  " 
			printf '%s\n' "${rootAVIFolderPath}" "" 
		fi 
	done 
} 

function func_scrapeAVIfiles() { 
	local loc_bash_version 
	printf '%s\n' "	→	Scrape recursively for AVI files:  " 
	func_EnterToContinue 
	loc_bash_version="$( bash --version | head -n1 | cut -d " " -f4 | cut -d "(" -f1 )" 
	if printf '%s\n' "4.4.0" "${loc_bash_version}" | sort -V -C ; then 
		# readarray or mapfile -d fails before bash 4.4.0 
		mapfile -d '' A_aviToConvert < <( find "${rootAVIFolderPath}" -type f -name "*.avi" -print0 ) 
	else 
		while IFS=  read -r -d $'\0'; do 
			A_aviToConvert+=( "$REPLY" ) 
		done < <( find "${rootAVIFolderPath}" -type f -name "*.avi" -print0 ) 
	fi 
} 

function func_convertAVIandBuildContainingPathArray() { 
	local loc_pathThisFolder 
	for avi in "${A_aviToConvert[@]}" ; do 
		printf '%s\n' "${avi}	→	${avi/avi/mkv}" "" 
		mkvmerge -o "${avi/%avi/mkv}" "${avi}" 
		loc_pathThisFolder=$( dirname "${avi}" ) 
		# grep requires -F to prevent it interpreting a - in a path as signifying a range 
		if ! printf '%s\n' "${A_foldersWithAVIfiles[@]}" | grep -Fq --line-regexp "${loc_pathThisFolder}" ; then 
			A_foldersWithAVIfiles+=( "${loc_pathThisFolder}" ) 
		fi 
	done 
} 

function main() { 
	func_getContainingFolder 
	func_scrapeAVIfiles 
	func_convertAVIandBuildContainingPathArray 
} 

## 

########## 
#  Main  # 

main 
exit $? 

## 
