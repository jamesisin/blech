#! /usr/bin/env bash 
# Title   :  filePrepend.sh 
# Parent  :  NONE 
# Author  :  JamesIsIn 20200207  Do something kind today.  

# Purpose :  Prepend a string to selected files.  
# 

## 

################## 
#  Declarations  # 

declare containingFolderPath="${1}" 
declare filename 
declare fileExtension 
	fileExtension="." 
declare StringPrepend 
	StringPrepend='' 
declare proceed 
	proceed="n" 

## 

############### 
#  Functions  # 

function func_intro() { 
	printf '%s\n' "" "Hello.  " "" 
	printf '%s\n' "This script changes names based on a containing folder, a prepending string, and an extension which you supply.  " 
	printf '%s\n' "Example:  If you provide '01-' as your prepend.  " 
	printf '%s\n' "Example:  Then '01 - Track Name.flac' will become '01-01 - Track Name.flac'  " "" 
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

function func_getStringPrepend() { 
	# ask the user for the string to insert as replacement 
	oldIFS="${IFS}" && IFS='' 
	read -rep "With what shall we prepend these files?  " -i "${StringPrepend}" StringPrepend 
	printf '%s\n' "" "	\"${StringPrepend}\"" 
	IFS="${oldIFS}" 
} 

function func_testReplacement() { 
	# emulate name change for user evaluation 
	cd "${containingFolderPath}" 
	for filename in *"${fileExtension}" ; do 
		printf '%b\n' "${filename}  →  " "${StringPrepend}${filename}" "" 
	done 
} 

function func_testReplacementLoop() { 
	# loop through tests 
	while [ ! "${proceed}" == y ] ; do # something 
		func_getFileExtension  
		func_getStringPrepend 
		func_testReplacement 
		# ask user if test was ok 
		printf '%s\n' "" 
		read -rp "Shall we proceed with this change?  (y|N)  " -n1 proceed 
		printf "\n" 
	done 
} 

function func_performReplacement() { 
	# use $ instead of ^ for postpend 
	if rename "s/^/${StringPrepend}/" *"${fileExtension}" ; then 
		printf '%s\n' "	Files prepended.  " "" 
	else 
		printf '%s\n' "	There was a problem.  " "" 
	fi 
} 

function main() { 
	func_intro
	func_getContainingFolderLoop
	func_testReplacementLoop 
	func_performReplacement 
	return $? 
} 

## 

########## 
#  Main  # 

main 
exit ${?} 

## 
