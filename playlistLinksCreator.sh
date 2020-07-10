#! /usr/bin/env bash 
# Title   :  playlistLinksCreator.sh 
# Parent  :  N/A 
# Author  :  JamesIsIn 20200705  Do something nice today.  

# Purpose :   
# Create hard links in a folder named after a playlist of each file called in the playlist.  

## 

############### 
#  Variables  # 

declare playlistPath 
	playlistPath="${1}" 
declare directory_MixedTapes_destination 
declare directory_MixedTape_new 
declare -a A_playlistPaths_full 
declare directory_MixedTape_fullPath 

# # debugging 
# playlistPath=".m3u" 
# directory_MixedTapes_destination="" 
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

function func_EnterToContinue() { 
	# just waits for the user before proceeding; a timer could be added later 
	read -rp "	Press [Enter] to continue…  " 
} 

function func_getDirectories() { 
	# Query user for directory locations.  
	func_getMixedTapesDestination_Loop 
} 

function func_getPlaylistFile() { 
	# obtain directory in which to work 
	printf '%s\n' "	→	Playlist:  " 
	read -rep "Please provide the path to the playlist to use to create a MixedTape folder:  " -i "${playlistPath}" playlistPath 
	# expand the ~/ if it gets submitted 
	playlistPath="${playlistPath/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	playlistPath="${playlistPath//\\/}" 
	if [ -f "${playlistPath}" ] ; then 
		printf '%s\n' "	I have confirmed this file exists:	${playlistPath}" "" 
	else 
		printf '%s\n' "	I cannot confirm this file exists:	${playlistPath}" "" 
	fi 
} 

function func_getPlaylistFile_Loop() { 
	while [ ! -f "${playlistPath}" ] ; do 
		func_getPlaylistFile 
	done 
	playlistName="$( basename -- "${playlistPath}" )" 
	directory_MixedTape_new="${playlistName/.m3u/}"  
} 

function func_getMixedTapesDestination() { 
	printf '%s\n' "	→	PMP Root:  " 
	read -rep "Please provide the directory where this MixedTape folder will live:  " -i "${directory_MixedTapes_destination}" directory_MixedTapes_destination 
	# expand the ~/ if it gets submitted 
	directory_MixedTapes_destination="${directory_MixedTapes_destination/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	directory_MixedTapes_destination="${directory_MixedTapes_destination//\\/}" 
	if [ -d "${directory_MixedTapes_destination}" ] ; then 
		printf '%s\n' "	I have confirmed this is a directory:	${directory_MixedTapes_destination}" "" 
	else 
		printf '%s\n' "	I cannot confirm this is a directory:	${directory_MixedTapes_destination}" "" 
	fi 
} 

function func_getMixedTapesDestination_Loop() { 
	while [ ! -d "${directory_MixedTapes_destination}" ] ; do 
		func_getMixedTapesDestination 
	done 
} 

function func_getPlaylistName() { 
	# ask user to name destination folder based on playlist name 
	printf '%s\n' "	→	MixedTape folder:  " 
	read -rep "Please name the directory where this MixedTape will live:  " -i "${directory_MixedTape_new}" directory_MixedTape_new 
	directory_MixedTape_fullPath="${directory_MixedTapes_destination}${directory_MixedTape_new}" 
	if [ -d "${directory_MixedTape_fullPath}" ] ; then 
		printf '%s\n' "	This directory already exists:	${directory_MixedTape_fullPath}" "" 
		return 1 
	else 
		return 0 
	fi 
} 

function func_getPlaylistName_Loop() { 
	# ask user to name destination folder based on playlist name 
	while ! func_getPlaylistName ; do 
		printf '%s\n' "	The directory name must be unique.  " 
	done 
} 

function func_MixedTapesDestination_create() { 
	# ask user to name destination folder based on playlist name 
	func_getPlaylistName_Loop 
	printf '%s\n' "	→	mkdir:  " 
	mkdir "${directory_MixedTape_fullPath}" 
	if [ -d "${directory_MixedTape_fullPath}" ] ; then 
		printf '%s\n' "	I have confirmed this is a directory:	${directory_MixedTape_fullPath}" "" 
	else 
		printf '%s\n' "	I cannot confirm this is a directory:	${directory_MixedTape_fullPath}" "" 
		printf '%s\n' "" "${LINENO}" "" 
		exit 255 
	fi 
} 

function func_parsePlaylist() { 
	readarray -t A_playlistPaths_full <<< "$( grep -v -e '^#' "${playlistPath}" )" 
	printf '%s\n' "Playlist:		${playlistName}  " 
	printf '%s\n' "Track count:		${#A_playlistPaths_full[@]} " "" 
	for (( i = 0 ; i < ${#A_playlistPaths_full[@]} ; i++ )) ; do 
		A_playlistPaths_fileNames[i]="$( basename "${A_playlistPaths_full[${i}]}" )" 
		# A_playlistPaths_source[i]="$( dirname "${A_playlistPaths_full[${i}]}" )" 
	done 
	func_EnterToContinue 
} 

function func_MixedTapesDestination_CreateLinks() { 
	i=0 
	track=1 
	while [ "${i}" -le "${#A_playlistPaths_full[@]}" ] ; do 
		if [[ -n "${A_playlistPaths_full[${i}]}" ]] ; then # ignore empty elements (blank lines) 
			if [[ ${track} -lt 10 ]] ; then # prepend zero to single-digit numbers 
				# for use across files systems add -s for soft links 
				ln -s "${A_playlistPaths_full[${i}]}" "${directory_MixedTape_fullPath}/0${track}__${A_playlistPaths_fileNames[i]}" 
			else 
				# for use across files systems add -s for soft links 
				ln -s "${A_playlistPaths_full[${i}]}" "${directory_MixedTape_fullPath}/${track}__${A_playlistPaths_fileNames[i]}" 
			fi 
		fi 
		(( i++ )) 
		(( track++ )) 
	done 
} 

function func_MixedTapesDestination_CreateLinks_Loop() { 
	# TODO:  add error deteciton for link creation 
	func_MixedTapesDestination_CreateLinks
} 

function main() { 
	printf '%s\n' "" "Hello.  " "" 
	printf '%s\n' "This script is built to use m3u playlists.  " 
	printf '%s\n' "You can call this script with a playlist path as its argument.  " 
	printf '%s\n' "Crtl-c at any time abandons any unsaved changes and exits the script.  " "" 
	func_GetCurrentUser 
	func_getPlaylistFile_Loop 
	func_getDirectories 
	func_parsePlaylist  
	func_MixedTapesDestination_create 
	printf '%s\n' "" "We are about to create ${#A_playlistPaths_full[@]} links in your MixedTape folder:  " 
	printf '%s\n' "	${directory_MixedTape_fullPath}" "" 
	func_EnterToContinue 
	func_MixedTapesDestination_CreateLinks_Loop 
	printf '%s\n' "" "Good-bye.  " "" 
} 

## 

########## 
#  Main  # 

main 

exit $? 

## 
