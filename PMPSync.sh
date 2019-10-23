#! /usr/bin/env bash 
# Title   :  PMPSync.sh 
# Parent  :  NONE 
# Author  :  JamesIsIn 20190920 Do something nice today.  

# Purpose :  Synchronize tracks from Library to PMP per playlists.  
# 

## 

############### 
#  Variables  # 

declare playlistPath 
	playlistPath="${1}" 
declare directory_MusicLibraryRoot_source 
declare directory_PMPRoot_destination 
declare naughtyFilesystem="y" 
declare anotherPlaylist="y" 
declare -a files_syncSource 
declare -a files_syncDestination 

# # debugging 
# playlistPath=".m3u" 
# directory_MusicLibraryRoot_source="" 
# directory_PMPRoot_destination="" 
# # 

## 

############### 
#  Functions  # 

# ToDo:  
# how to get anotherPlaylist working in the loop?  
# 
# split paths into root part and path part so substitutions only happen to path part # done 
# "${rootPart}/${pathPart}" # done 

function func_GetCurrentUser() { 
	if [[ ! "${USER}" == root ]] ; then 
		scriptUser_linux="${USER}" 
	elif [[ "${USER}" == root ]] ; then # check if some naughty monster is logged in as root 
		if [[ "${SUDO_USER}" == "" ]] ; then # sudo is ok 
			printf '%s\n' "" "It is a bad practice to log in as root.  " 
			printf '%s\n' "Log in as yourself and use sudo if necessary.  " "" 
			exit 0 
		fi 
		scriptUser_linux="${SUDO_USER}" 
	fi 
} 

function func_EnterToContinue() { 
	# just waits for the user before proceeding; a timer could be added later 
	read -rp "Press [Enter] to continue…  " 
} 

function func_getDirectories() { 
	# Query user for three directory locations.  
	func_getMusicLibraryRootLoop 
	func_getPMPRootLoop 
	func_MultiplePlaylists 
} 

function func_anotherPlaylist() { 
	# Does the user want to sync any additional playlist?  
	printf '\n' 
	read -rp "Would you like to sync another playlist?  (Y/n)  " -N1 anotherPlaylist 
	printf '\n' 
}

function func_MultiplePlaylists() { 
	# 
	until [[ "${anotherPlaylist}" == "n" ]] ; do 
		func_getPlaylistLoop 
		# either sync the playlist or store the paths then ask for another 
		# must add test for playlist entries paths are in music library path 
		func_parsePlaylist 
		func_anotherPlaylist 
	done 
} 

function func_getPlaylist() { 
	# obtain directory in which to work 
	read -rep "Please provide the path to the playlist you want to synchronize:  " -i "${playlistPath}" playlistPath 
	# expand the ~/ if it gets submitted 
	playlistPath="${playlistPath/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	playlistPath="${playlistPath//\\/}" 
	if [ -f "${playlistPath}" ] ; then 
		printf '%s\n' "I have confirmed this is a file.  " 
		printf '%s\n' "${playlistPath}" "" 
	else 
		printf '%s\n' "I cannot confirm this is a file.  " 
		printf '%s\n' "${playlistPath}" "" 
	fi 
} 

function func_getPlaylistLoop() { 
	while [ ! -f "${playlistPath}" ] ; do 
		func_getPlaylist 
	done 
	playlistName="$( basename -- "${playlistPath}" )" 
} 

function func_getMusicLibraryRoot() { 
	# do I need this if the playlist has paths?  
	# obtain directory in which to work 
	read -rep "Please provide the root directory for your music library:  " -i "${directory_MusicLibraryRoot_source}" directory_MusicLibraryRoot_source 
	# expand the ~/ if it gets submitted 
	directory_MusicLibraryRoot_source="${directory_MusicLibraryRoot_source/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	directory_MusicLibraryRoot_source="${directory_MusicLibraryRoot_source//\\/}" 
	if [ -d "${directory_MusicLibraryRoot_source}" ] ; then 
		printf '%s\n' "I have confirmed this is a directory.  " 
		printf '%s\n' "${directory_MusicLibraryRoot_source}" "" 
	else 
		printf '%s\n' "I cannot confirm this is a directory.  " 
		printf '%s\n' "${directory_MusicLibraryRoot_source}" "" 
	fi 
} 

function func_getMusicLibraryRootLoop() { 
	while [ ! -d "${directory_MusicLibraryRoot_source}" ] ; do 
		func_getMusicLibraryRoot 
	done 
} 

function func_getPMPRoot() { 
	# obtain directory in which to work 
	read -rep "Please provide the root directory for your music player:  " -i "${directory_PMPRoot_destination}" directory_PMPRoot_destination 
	# expand the ~/ if it gets submitted 
	directory_PMPRoot_destination="${directory_PMPRoot_destination/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	directory_PMPRoot_destination="${directory_PMPRoot_destination//\\/}" 
	if [ -d "${directory_PMPRoot_destination}" ] ; then 
		printf '%s\n' "I have confirmed this is a directory.  " 
		printf '%s\n' "${directory_PMPRoot_destination}" "" 
	else 
		printf '%s\n' "I cannot confirm this is a directory.  " 
		printf '%s\n' "${directory_PMPRoot_destination}" "" 
	fi 
} 

function func_getPMPRootLoop() { 
	while [ ! -d "${directory_PMPRoot_destination}" ] ; do 
		func_getPMPRoot 
	done 
} 

function func_PMP_naughtyFilesystem() { 
	# if the PMP uses FAT or NTFS then sub certain characters with __ 
	printf '%s\n' "Some file systems are unable to handle certain characters.  " 
	printf '%s\n' "FAT and NTFS file systems in particular are bad about this.  " 
	printf '%s\n' "If you would like we can change : and ? into __ to avoid sync failures.  " 
	read -rep "Is your PMP formatted to use one of these lesser file systems?  (Y/n)  " -n1 naughtyFilesystem 
	printf '\n' 
} 

function func_parsePlaylist() { 
	# 
	readarray -t files_syncSource <<< "$( grep -v '^#' "${playlistPath}" )" 
	printf '%s\n' "" "Playlist:  ${playlistName}  " 
	printf '%s\n' "Track count:  ${#files_syncSource[@]} " "" # number of tracks 
	# useful for debugging:  
	# for (( i = 0 ; i < ${#files_syncSource[@]} ; i++ )) ; do 
	# 	printf '%s\n' "${files_syncSource[${i}]}" # path to each track 
	# done 
	func_EnterToContinue 
	func_CreateSourceAndDestination 
} 

# split path into root and remainder sections # done 
# substitution should only apply to remainder section # done 
function func_CreateSourceAndDestination() { 
	# 
	for (( i = 0 ; i < ${#files_syncSource[@]} ; i++ )) ; do 
		files_syncDestination[${i}]="${files_syncSource[${i}]#${directory_MusicLibraryRoot_source}}" 
		# printf '%s\n' "${files_syncDestination[${i}]}" # useful in debugging 
		# printf '%s\n' "files_syncDestination is ${files_syncDestination[${i}]}" 
		# printf '%s\n' "directory_MusicLibraryRoot_source is ${directory_MusicLibraryRoot_source}" 
		# printf '%s\n' "directory_PMPRoot_destination is ${directory_PMPRoot_destination}" 
		# exit 
		if [ "${naughtyFilesystem}" != "n" ] ; then 
			files_syncDestination[${i}]="${files_syncDestination[${i}]//\:/__}" 
			files_syncDestination[${i}]="${files_syncDestination[${i}]//\?/__}" 
		fi 
		file_destinationPath="$( dirname -- "${directory_PMPRoot_destination}${files_syncDestination[${i}]}" )" 
		if [ ! -d "${file_destinationPath}" ] ; then 
			mkdir -p "${file_destinationPath}" 
		fi 
		# try process substitution 
		# rsync --files-from=<( printf "%s\n" "${files[@]}" ) source destination 
		# rsync -rltDvPm --files-from=<( printf "%s\n" "${files_syncSource[${i}]}" ) "${files_syncDestination[${i}]}" 
		# the above needs to lose the interation and destination should just be PMProot I guess 
		rsync -rltDvPmz "${files_syncSource[${i}]}" "${directory_PMPRoot_destination}${files_syncDestination[${i}]}" 
	done 
} 

function func_purgeEmptyPMPFolders() { 
	printf '%s\n' "" "We will now purge any empty folders under the PMP root directory.  " "" 
	func_EnterToContinue 
	find "${directory_PMPRoot_destination:?Not set correctly}" -type d -empty -delete 
} 

function main() { 
	printf '%s\n' "" "Hello.  " "" 
	printf '%s\n' "This script is built to use m3u playlists.  " 
	printf '%s\n' "You can call this script with a playlist path as its argument.  " 
	printf '%s\n' "Crtl-c at any time abandons any unsaved changes and exits the script.  " "" 
	func_GetCurrentUser 
	func_PMP_naughtyFilesystem 
	func_getDirectories 
	func_purgeEmptyPMPFolders 
	printf '%s\n' "" "Good-bye.  " "" 
} 

## 

########## 
#  Main  # 

main 

exit $? 

## 
