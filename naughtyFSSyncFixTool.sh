#! /usr/bin/env bash 
# Title   :  naughtyFSSyncFixTool.sh 
# Parent  :  n/a 
# Author  :  JamesIsIn 20221125  Do something kind today.  

# Purpose : naughtyFSSyncFixTool.sh will substitute a set of obvious insertions into file names in a file hierarchy with the intention to then sync 
# 			or move those renamed files onto a file system hindered by the kernel limitations of Windows (especially FAT and NTFS).  
# 			It runs the insertions in place in preparation for any other tool to manage the sync or copy.  
# 			Since the substitutions are unique and obvious, future reversal of the substitution is also facilitated.  
# 			(This script could be modified to provide such reversal.)  
# 

## 

################## 
#  Declarations  # 

declare directory_filePathToEvaluate 
declare -a A_fileType 
	A_fileType=( d f ) 
declare -A AA_naughtyCharacters 
	AA_naughtyCharacters[__bs__]='\' 
	AA_naughtyCharacters[__c__]=':' 
	AA_naughtyCharacters[__a__]='*' 
	AA_naughtyCharacters[__qm__]='?' 
	AA_naughtyCharacters[__dq__]='"' 
	AA_naughtyCharacters[__lt__]='<' 
	AA_naughtyCharacters[__gt__]='>' 
	AA_naughtyCharacters[__p__]='|' 
# 
declare -a A_illegalCharacter_substitution 
declare -a A_illegalCharacter_substitution_postSub 


# # debugging 
# 
# # 

## 

############### 
#  Functions  # 

function func_GetCurrentUser() { 
	if [[ ! "${USER}" == root ]] ; then 
		return 0 
		# scriptUser_linux="${USER}" 
	elif [[ "${USER}" == root ]] ; then # check if some naughty monster is logged in as root 
		if [[ "${SUDO_USER}" == "" ]] ; then # sudo is ok 
			printf '%s\n' "" "It is a bad practice to log in as root.  " 
			printf '%s\n' "Log in as yourself and use sudo if necessary.  " "" 
			exit 0 
		fi 
		# scriptUser_linux="${SUDO_USER}" 
	fi 
} 

function func_getFilepathToEvaluate() { 
	# do I need this if the playlist has paths?  
	printf '%s\n' "	→	Library Root:  " 
	read -rep "Please provide the root directory path for the tree to evaluate recursively:  " -i "${directory_filePathToEvaluate}" directory_filePathToEvaluate 
	# expand the ~/ if it gets submitted 
	directory_filePathToEvaluate="${directory_filePathToEvaluate/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	directory_filePathToEvaluate="${directory_filePathToEvaluate//\\/}" 
	if [ -d "${directory_filePathToEvaluate}" ] ; then 
		printf '%s\n' "	I have confirmed this is a directory:	${directory_filePathToEvaluate}" "" 
	else 
		printf '%s\n' "	I cannot confirm this is a directory:	${directory_filePathToEvaluate}" "" 
	fi 
} 

function func_getFilepathToEvaluate_loop() { 
	while [ ! -d "${directory_filePathToEvaluate}" ] ; do 
		func_getFilepathToEvaluate 
	done 
} 

function func_substituteIllegalCharacters() { 
	for type in "${A_fileType[@]}" ; do 
		for key in "${!AA_naughtyCharacters[@]}" ; do 
			A_illegalCharacter_substitution=() 
			local loc_valueEscaped 
				loc_valueEscaped="\\${AA_naughtyCharacters[${key}]}" 
			# build file path array 
			mapfile -d $'\0' A_illegalCharacter_substitution < <( find "${directory_filePathToEvaluate}" -type "${type}" -iname "*${loc_valueEscaped}*" -print0 ) 
			for (( i = 0 ; i < ${#A_illegalCharacter_substitution[@]} ; i++ )) ; do 
				illegalCharacter_substitution_postSub="${A_illegalCharacter_substitution[${i}]//${loc_valueEscaped}/${key}}" 
				mv "${A_illegalCharacter_substitution[${i}]}" "${illegalCharacter_substitution_postSub}" 
			done 
		done 
	done 
} 

function main() { 
	func_GetCurrentUser 
	func_getFilepathToEvaluate_loop 
	func_substituteIllegalCharacters 
	return $? 
} 

## 

########## 
#  Main  # 

main 
exit ${?} 

## 
