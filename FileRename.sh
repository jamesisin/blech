#! /usr/bin/env bash 
# Title   :  FileRename.sh 
# Author  :  JamesIsIn 20190603 Do something kind today. 

# Purpose :  Rename files by string substitution based on user input and supplied file extension.  
# 

## 

################## 
#  Declarations  # 

declare containingFolderPath="${1}" 
declare filename 
declare fileExtension 
declare stringSought 
declare stringReplacement 
declare proceed 
	proceed="n" 

## 

# ToDo:  create continue function 
# ToDo:  adjust spacings in output 

############### 
#  Functions  # 

function func_intro() { 
	printf '%s\n' "" "Hello.  " 
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
		printf '%s\n' "${containingFolderPath}" 
	else 
		printf '%s\n' "I cannot confirm this is a directory.  " 
		printf '%s\n' "${containingFolderPath}" 
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
	read -rep "For the files to change, please provide the file extension (like .flac or blank for all files):  " -i "${fileExtension}" fileExtension 
} 

function func_getstringSought() { 
	# ask the user for the string to be replaced 
	oldIFS="${IFS}" && IFS='' 
	read -rep "What is the string which will be replaced (must escape certain characters like \?)?  " -i "${stringSought}" stringSought 
	printf '%s\n' "	\"${stringSought}\"" 
	IFS="${oldIFS}" 
} 

function func_getstringReplacement() { 
	# ask the user for the string to insert as replacement 
	oldIFS="${IFS}" && IFS='' 
	read -rep "And what is the replacement string ( – )?  " -i "${stringReplacement}" stringReplacement 
	printf '%s\n' "	\"${stringReplacement}\"" 
	IFS="${oldIFS}" 
} 

function func_testReplacement() { 
	# emulate name change for user evaluation 
	cd "${containingFolderPath}" || printf '%s\n' "Unable to cd:  ${containingFolderPath} "  return 1 
	for filename in *"${fileExtension}" ; do 
		if [[ "${filename}" =~ ${fileExtension} ]] && [[ "${filename}" =~ ${stringSought} ]] && [[ "${filename}" != "${filename/${stringSought}/${stringReplacement}}" ]] ; then # do not quote regex or it is a string 
			printf '%b\n' "${filename} 	→ 	${filename/${stringSought}/${stringReplacement}}" 
		fi 
	done 
} 

function func_testReplacementLoop() { 
	# loop through tests 
	while [[ ! "${proceed}" =~ [y|Y] ]] ; do # something 
		func_getFileExtension 
		func_getstringSought 
		func_getstringReplacement 
		func_testReplacement 
		# ask user if test was ok 
		printf '%s\n' "	\"${stringSought}\"  →  \"${stringReplacement}\"" 
		read -rp "Shall we proceed with this change?  (y|N)  " -n1 proceed 
		printf '\n' 
	done 
} 

function func_performReplacement() { 
	# currently this is the original script version of the replacement 
	for filename in *"${fileExtension}" ; do #  ??  ToDo:  this can be made more robust; only mv if file extension matches  ??  
		if [[ "${filename}" =~ ${fileExtension} ]] && [[ "${filename}" =~ ${stringSought} ]] && [[ "${filename}" != "${filename/${stringSought}/${stringReplacement}}" ]] ; then # do not quote regex or it is a string 
			if mv "$filename" "${filename/${stringSought}/${stringReplacement}}"  ; then 
				printf '%s\n' "	${filename} changed " 
			else 
				printf '%s\n' "Error:  ${filename} " 
			fi 
		fi 
	done 
} 

function main() { 
	func_intro 
	func_getContainingFolderLoop 
	while true ; do 
		func_testReplacementLoop 
		func_performReplacement 
		read -rep "Perform another chnange in this directory [Y|n]?  " -n1 
		if [[ "${REPLY}" =~ [n|N] ]] ; then 
			return 0 
		else 
			proceed=""  
		fi 
	done 
	return ${?} 
} 

## 

########## 
#  Main  # 

main 
exit ${?} 

## 
