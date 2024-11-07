#! /usr/bin/env bash 
# Title  :  splitFLAC.sh 
# Author :  JamesIsIn 20191121  Do something kind today.  

# Purpose:  Convert FLAC albums to FLAC tracks recursively.  
#           This script has dependnecies:  cuetools shntool 

## 

################## 
#  Declarations  # 

declare trackname 
	trackname="%n – %p – %t" 
declare -a A_albumfind 
declare -a A_cuefind 
declare albumfolder 
declare -a A_deadfiles 
declare -a A_hidemes 
declare containingFolderPath="${1}" 

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
	while [ ! -d "${containingFolderPath}" ] ; do 
		read -rep "Please provide the containing folder for the files to be split:  " -i "${containingFolderPath}" containingFolderPath 
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
	unset REPLY 
	until [[ "${REPLY}" =~ (Y|y|N|n) ]] ; do 
		printf '%s\n' "Do you want to include the performer name in the file names?  " 
		read -rp "[y or n]:  " -n1 
		if [[ "${REPLY}" =~ (Y|y) ]] ; then 
			printf '%s\n' "" "Ok, I'll attempt to include performer names:  01 – Performer Name – Track Name.flac  " "" 
		else [[ "${REPLY}" =~ (N|n) ]] ; 
			printf '%s\n' "" "Ok, I won't include performer names:  01 – Track Name.flac  " "" 
			trackname="%n – %t" 
		fi 
	done 
} 

function func_RecursivelyParseFilesIntoArrays() { 
	# mapfile -t A_albumfind < <( find "${containingFolderPath}" -type f -iname \*.ape -o -iname \*.flac ) 
	mapfile -t A_albumfind < <( find "${containingFolderPath}" -type f -iname \*.flac ) 
	mapfile -t A_cuefind < <( find "${containingFolderPath}" -type f -iname \*.cue ) 
} 

function func_splitFilesAndHideOriginals() { 
	# split apes and flacs; hide album files 
	for (( i=0 ; i < ${#A_albumfind[@]} ; i++ )) ; do 
		# path is cue iteration less file name 
		albumfolder="${A_cuefind[i]%/*.*}" 
		shnsplit -d "${albumfolder}" -o flac -f "${A_cuefind[i]}" -t "${trackname}" "${A_albumfind[i]}" && mv "${A_albumfind[i]}" "${A_albumfind[i]}".hideme ; 
	done 
} 

function func_hide00Files() { 
	# mapfile -t A_deadfiles < <( find "${containingFolderPath}" -type f -iname 00\*.ape -o -iname 00\*.flac ) 
	mapfile -t A_deadfiles < <( find "${containingFolderPath}" -type f -iname 00\*.flac ) 
	for (( i=0 ; i < ${#A_deadfiles[@]} ; i++ )) ; do 
		mv "${A_deadfiles[i]}" "${A_deadfiles[i]}".hideme ; 
	done 
} 

function func_tagSplitFiles() { 
	# tag files 
	for (( i=0 ; i < ${#A_cuefind[@]} ; i++ )) ; do 
		# path is cue iteration less file name 
		albumfolder="${A_cuefind[i]%/*.*}" 
		cuetag "${A_cuefind[i]}" "${albumfolder}"\/*.flac && mv "${A_cuefind[i]}" "${A_cuefind[i]}".hideme ; 
	done 
} 

function func_locateSourceFiles() { 
	mapfile -t A_hidemes < <( find "${containingFolderPath}" -type f -iname \*.hideme ) 
} 

function func_PerformCleanup() { 
	# remove hideme files and unset all variables 
	func_locateSourceFiles 
	for (( i=0 ; i < ${#A_hidemes[@]} ; i++ )) ; do 
		rm "${A_hidemes[i]}" ; 
	done 
	unset 
} 

function func_revertSourceFiles() { 
	# revert used files and exit 
	func_locateSourceFiles 
	for (( i=0 ; i < ${#A_hidemes[@]} ; i++ )) ; do 
		mv "${A_hidemes[i]}" "${A_hidemes[i]/\.hideme/}" ; 
	done 
} 

function func_confirmCueRatio() { 
	# follow array counts 
	printf '%s\n' "" "Counts are as follows.  " "	Albums:	${#A_albumfind[@]} " "	Cues:	${#A_cuefind[@]} " 
	if ! [ "${#A_albumfind[@]}" == "${#A_cuefind[@]}" ] ; then 
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
#  Main  # 

main 
exit ${?} 

## 
