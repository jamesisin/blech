#! /usr/bin/env bash 
# Title  :  splitFLAC.sh 
# Author :  JamesIsIn 20191121  Do something nice today.  

# Purpose:  Convert FLAC albums to FLAC tracks recursively.  
#           This script has dependnecies:  cuetools shntool 

## 

############### 
#  variables  # 

declare trackname 
	trackname="%n – %p – %t" 
declare -a albumfind 
declare -a cuefind 
declare albumfolder 
declare -a deadfiles 
declare -a hidemes 
declare containingFolderPath="${1}" 

## 

############### 
#  functions  # 

function func_EnterToContinue() { 
	# just waits for the user before proceeding; a timer could be added later 
	read -rp "Press [Enter] to continue…  " 
} 

function func_getContainingFolder() { 
	# obtain directory in which to work 
	printf '%s\n' "" "========================================" "" "Hello.  " "" 
	printf '%s\n' "Crtl-c at any time abandons any changes and exits the script.  " "" 
	func_EnterToContinue 
	while [ ! -d "${containingFolderPath}" ] ; do 
		read -rep "Please provide the containing folder for the files to be renamed:  " -i "${containingFolderPath}" containingFolderPath 
		# expand the ~/ if it gets submitted 
		containingFolderPath="${containingFolderPath/#~/${HOME}}" 
		# fix spaces to be used in a quoted variable 
		containingFolderPath="${containingFolderPath//\\/}" 
		if [ -d "${containingFolderPath}" ] ; then 
			printf '%s\n' "I have confirmed this is a directory.  " 
			printf '%s\n' "${containingFolderPath}" "" 
		else 
			printf '%s\n' "I cannot confirm this is a directory.  " 
			printf '%s\n' "${containingFolderPath}" "" 
		fi 
	done 
} 

function func_FileNamingOptions() { 
	# number, performer, and track names 
	printf '%s\n' "Assuming a cue has good information there are two formatting options:  " 
	printf '%s\n' "01 – Track Name.flac  " "01 – Performer Name – Track Name.flac  " "" 
	printf '%s\n' "Do you want to include the performer name in the file names?  " 
	read -rp "[y or n]:  " 
	if [ "${REPLY}" = "[Yy]" ] ; then 
		printf '%s\n' "Ok, I'll include performer names:  01 – Performer Name – Track Name.flac  " "" 
		trackname="%n – %p – %t" 
	else [ "${REPLY}" = "[Nn]" ] ; 
		printf '%s\n' "Ok, I won't include performer names:  01 – Track Name.flac  " "" 
		trackname="%n – %t" 
	fi 
} 

function func_RecursivelyParseFilesIntoArrays() { 
	# mapfile -t albumfind < <( find "${containingFolderPath}" -type f -iname \*.ape -o -iname \*.flac ) 
	mapfile -t albumfind < <( find "${containingFolderPath}" -type f -iname \*.flac ) 
	mapfile -t cuefind < <( find "${containingFolderPath}" -type f -iname \*.cue ) 
} 

function func_splitFilesAndHideOriginals() { 
	# split apes and flacs; hide album files 
	for (( i=0 ; i < ${#albumfind[@]} ; i++ )) ; do 
		# path is cue iteration less file name 
		albumfolder="${cuefind[i]%/*.*}" 
		shnsplit -d "$albumfolder" -o flac -f "${cuefind[i]}" -t "$trackname" "${albumfind[i]}" && mv "${albumfind[i]}" "${albumfind[i]}".hideme ; 
	done 
} 

function func_hide00Files() { 
	# mapfile -t deadfiles < <( find "${containingFolderPath}" -type f -iname 00\*.ape -o -iname 00\*.flac ) 
	mapfile -t deadfiles < <( find "${containingFolderPath}" -type f -iname 00\*.flac ) 
	for (( i=0 ; i < ${#deadfiles[@]} ; i++ )) ; do 
		mv "${deadfiles[i]}" "${deadfiles[i]}".hideme ; 
	done 
} 

function func_tagSplitFiles() { 
	# tag files 
	for (( i=0 ; i < ${#cuefind[@]} ; i++ )) ; do 
		# path is cue iteration less file name 
		albumfolder="${cuefind[i]%/*.*}" 
		cuetag "${cuefind[i]}" "$albumfolder"\/*.flac && mv "${cuefind[i]}" "${cuefind[i]}".hideme ; 
	done 
} 

function func_locateSourceFiles() { 
	mapfile -t hidemes < <( find "${containingFolderPath}" -type f -iname \*.hideme ) 
}

function func_PerformCleanup() { 
	# remove hideme files and unset all variables 
	func_locateSourceFiles 
	for (( i=0 ; i < ${#hidemes[@]} ; i++ )) ; do 
		rm "${hidemes[i]}" ; 
	done 
	unset 
} 

function func_revertSourceFiles() { 
	# revert used files and exit 
	func_locateSourceFiles 
	for (( i=0 ; i < ${#hidemes[@]} ; i++ )) ; do 
		mv "${hidemes[i]}" "${hidemes[i]/\.hideme/}" ; 
	done 
} 

function func_confirmCueRatio() { 
	# follow array counts 
	printf '%s\n' "" "Counts are as follows:  There are ${#albumfind[@]} albums and ${#cuefind[@]} cues.  " 
	if ! [ "${#albumfind[@]}" == "${#cuefind[@]}" ] ; then 
		printf '%s\n' "Your albums ought to equal your cues.  " "" 
		printf '%s\n' "Are these counts different than expected?  " 
		printf '%s\n' "	Please inspect the containing folders.  " 
		printf '%s\n' "	(Or select a different folder.)  " 
		printf '%s\n' "	Then re-run the script.  " "" 
		exit 255 
	fi 
	printf '%s\n' "Your albums equal your cues.  That's great!  " "" 
	printf '%s\n' "Are these counts different than expected?  " 
	printf '%s\n' "	Please ctrl-c and inspect the containing folders.  " 
	printf '%s\n' "	(Or select a different folder.)  " 
	printf '%s\n' "	Then re-run the script.  " "" 
	func_EnterToContinue 
} 

function func_confirmDeleteSourceFiles() { 
	## clean-up 
	until [[ "${REPLY}" =~ (d|q|r) ]] ; do 
		printf '%s\n' "" "It is time to clean up the used files.  " 
		printf '%s\n' "Ensure you are satisfied with the state of things before you continue.  " 
		printf '%s\n' "Please note:  We are about to delete all the album-length files.  " 
		printf '%s\n' "Check your work!  " "" 
		printf '%s\n' "Choose from the following options:  " 
		printf '%s\n' "(D)elete all of the used files.  " 
		printf '%s\n' "(Q)uit this script leaving all used files with a .hideme extension.  " 
		printf '%s\n' "(R)evert the used files and exit this script.  " "" 
		read -rp "Choose d or q or r:  " -n1 
		[[ "${REPLY}" == "q" ]] && ( printf '\n' ; exit 0 ) 
		[[ "${REPLY}" == "r" ]] && ( func_revertSourceFiles ; printf '\n' ) 
		[[ "${REPLY}" == "d" ]] && ( func_PerformCleanup ; printf '\n' ) 
	done 
} 

function main() { 
	## gather information 
	func_getContainingFolder 
	func_FileNamingOptions 
	printf '%s\n' "" "Let's get to work.  " "" "" 
	func_RecursivelyParseFilesIntoArrays 
	func_confirmCueRatio 
	func_splitFilesAndHideOriginals 
	func_hide00Files 
	func_tagSplitFiles 
	func_confirmDeleteSourceFiles 
} 

## 

########## 
#  main  # 

main 
exit $? 

## 
