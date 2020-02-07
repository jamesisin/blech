#! /usr/bin/env bash 
# Title   :  FileRename.sh 
# Author  :  JamesIsIn 20190603 Do something nice today. 

# Purpose :  Rename files by string substitution based on user input and supplied file extension.  
# 

## 

############### 
#  Variables  # 

declare containingFolderPath="${1}" 
declare filename 
declare fileExtension 
	fileExtension="." 
declare StringSearch 
	StringSearch=' _ ' 
declare StringReplacement 
	StringReplacement=' – ' 
declare proceed 
	proceed="n" 

## 

############### 
#  Functions  # 

function func_intro() { 
	printf '%s\n' "" "Hello.  " "" 
	printf '%s\n' "Crtl-c at any time abandons any changes and exits the script.  " "" 
} 

function func_getContainingFolder() { 
	read -rep "Please provide the containing folder for the files to be renamed:  " -i "${containingFolderPath}" containingFolderPath 
	# expand the ~/ if it gets submitted 
	containingFolderPath="${containingFolderPath/#~/${HOME}}" 
	# fix escaped characters to be used in a quoted variable 
	containingFolderPath="${containingFolderPath//\\/}" 
	if [ -d "${containingFolderPath}" ] ; then 
		printf '%s\n' "I have confirmed this is a directory.  " 
		printf '%s\n' "${containingFolderPath}" "" 
	else 
		printf '%s\n' "I cannot confirm this is a directory.  " 
		printf '%s\n' "${containingFolderPath}" "" 
	fi 
} 

function func_getContainingFolderLoop() { 
	# obtain directory in which to work 
	while [ ! -d "${containingFolderPath}" ] ; do 
		func_getContainingFolder 
	done 
} 

function func_getFileExtension() { 
	# ask the user for the file extension for the files for string swapping 
	read -rep "Please provide the file extension for the files to be changed:  " -i "${fileExtension}" fileExtension 
} 

function func_getStringSearch() { 
	# ask the user for the string to be replaced 
	printf '%s\n' "(Certain characters may require an escape.)  " 
	oldIFS="${IFS}" && IFS='' 
	read -rep "What is the string which will be replaced?  " -i "${StringSearch}" StringSearch 
	printf '%s\n' "" "	\"${StringSearch}\"" 
	IFS="${oldIFS}" 
} 

function func_getStringReplacement() { 
	# ask the user for the string to insert as replacement 
	oldIFS="${IFS}" && IFS='' 
	read -rep "With what shall we replace that string?  " -i "${StringReplacement}" StringReplacement 
	printf '%s\n' "	\"${StringReplacement}\"" 
	IFS="${oldIFS}" 
} 

function func_testReplacement() { 
	# emulate name change for user evaluation 
	cd "${containingFolderPath}" 
	for filename in *"${fileExtension}" ; do 
		printf '%b\n' "${filename}  →  " "${filename/${StringSearch}/${StringReplacement}}" "" 
	done 
} 

function func_testReplacementLoop() { 
	# loop through tests 
	while [ ! "${proceed}" == y ] ; do # something 
		func_getFileExtension 
		func_getStringSearch 
		func_getStringReplacement 
		func_testReplacement 
		# ask user if test was ok 
		printf '%s\n' "	\"${StringSearch}\"  →  \"${StringReplacement}\"" 
		read -rp "Shall we proceed with this change?  (y|N)  " -n1 proceed 
		printf "\n" 
	done 
} 

function func_performReplacement() { 
	# currently this is the original script version of the replacement 
	for filename in *"${fileExtension}" ; do 
		if mv "$filename" "${filename/${StringSearch}/${StringReplacement}}"  ; then 
			printf '%s\n' "	${filename} changed " "" 
		else 
			printf '%s\n' 
		fi 
	done 
} 

function main() { 
	func_intro 
	func_getContainingFolderLoop
	func_testReplacementLoop 
	func_performReplacement 
	exit $? 
} 

## 

########## 
#  Main  # 

main 

exit 255 

## 
