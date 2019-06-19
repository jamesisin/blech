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
declare StringSearch 
	StringSearch=" - " 
declare StringReplacement 
	StringReplacement=" – " 
declare proceed 
	proceed="n" 

## 

############### 
#  Functions  # 

function func_getContainingFolder() { 
	# obtain directory in which to work 
	printf '%s\n' "Hello.  " "" 
	read -rep "Please provide the containing folder for the files to be renamed:  " -i "${containingFolderPath}" containingFolderPath 
	# expand the ~/ if it gets submitted 
	containingFolderPath="${containingFolderPath/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	containingFolderPath="${containingFolderPath//\\ / }" 
	if [ -d "${containingFolderPath}" ] ; then 
		printf '%s\n' "I have confirmed this is a directory.  " 
		printf '%s\n' "${containingFolderPath}" "" 
	else 
		printf '%s\n' "I cannot confirm this is a directory.  " 
		printf '%s\n' "${containingFolderPath}" "" 
		exit 1 
	fi 
} 

function func_getFileExtension() { 
	# ask the user for the file extension for the files for string swapping 
	read -rep "Please provide the file extension for the files to be changed:  " -i "${fileExtension}" fileExtension 
} 

function func_getStringSearch() { 
	# ask the user for the string to be replaced 
	read -rep "What is the string found in the file which will be replaced?  " -i "${StringSearch}" StringSearch 
} 

function func_getStringReplacement() { 
	# ask the user for the string to insert as replacement 
	read -rep "With what shall we replace that string?  " -i "${StringReplacement}" StringReplacement 
} 

function func_testReplacement() { 
	# emulate name change for user evaluation 
	for filename in "${containingFolderPath}"*."${fileExtension}" ; do 
		printf '%s\n' "$filename --> ${filename/${StringSearch}/${StringReplacement}}" 
	done 
} 

function func_testReplacementLoop() { 
	# loop through tests 
	while [ ! "${proceed}" == y ] ; do  # something 
		printf '%s\n' "Crtl-c at any time abandons any changes and exits the script.  " "" 
		func_getFileExtension 
		func_getStringSearch 
		func_getStringReplacement 
		func_testReplacement 
		# ask user if test was ok 
		read -rp "Shall we proceed with this change?  (y|N)  " -n1  proceed 
		printf "\n" 
	done 
} 

function func_performReplacement() { 
	# currently this is the original script version of the replacement 
	for filename in "${containingFolderPath}"*."${fileExtension}" ; do 
		mv "$filename" "${filename/${StringSearch}/${StringReplacement}}" 
		printf '%s\n' "${filename} changed " 
	done 
} 

function main() { 
	func_getContainingFolder 
	func_testReplacementLoop 
	func_performReplacement 
} 

## 

########## 
#  Main  # 

main 

exit 0 

## 
