#! /usr/bin/env bash 
# Title  :  PMPSync.sh 
# Parent :  NONE 
# Author :  JamesIsIn 20190920 Do something nice today.  

# Purpose:  Synchronize tracks from Library to PMP per playlists.  
# 

## 

############### 
#  Variables  # 

# declare scriptUser_linux 
declare playlistPath 
	playlistPath="${1}" 
declare directory_MusicLibraryRoot_source 
declare directory_PMPRoot_destination 
declare naughtyFilesystem="y" 
declare anotherPlaylist="y" 
declare -a A_Source_playlist 
declare -a A_Source_sortU 
declare -a A_Source_dubUnders 
declare -a A_Destination_dubUnders 
declare -a A_Destination_dubUnders_only 
declare -a A_Destination_orphans 
declare -a A_Destination_orphans_diff 
declare files_Remain 

# # debugging 
# playlistPath=".m3u" 
# directory_MusicLibraryRoot_source="" 
# directory_PMPRoot_destination="" 
# 
# useful for debugging:  
# for (( i = 0 ; i < ${#A_Source_dubUnders[@]} ; i++ )) ; do 
# 	printf '%s\n' "${A_Source_dubUnders[${i}]}" # path to each track 
# done 
# exit 
# # 

## 

############### 
#  Functions  # 

# ToDo:  
# 
# add test for playlist entries' paths are in music library path 
# 
# how to get anotherPlaylist working in the loop?  maybe I don't want to... 
# 
# make a function specifically for the folder confirmation if statement 
# function func_folderConfirmation or similar 

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
	printf '\n' 
	read -rp "	Press [Enter] to continue…  " 
	printf '\n' 
} 

function func_anotherPlaylist() { 
	# Does the user want to sync any additional playlist?  
	printf '\n' 
	read -rp "Would you like to sync another playlist?  (Choose no since this doesn't work yet.)  (Y/n)  " -N1 anotherPlaylist 
	# probably I won't bother to fix this since I'm using just a single playlist for each drive 
	printf '\n' 
}

function func_MultiplePlaylists() { 
	# 
	until [[ "${anotherPlaylist}" == "n" ]] ; do 
		func_getPlaylistLoop 
		# either sync the playlist or store the paths then ask for another 
		# should maybe add test for playlist entries paths are in music library path 
		func_parsePlaylist 
		func_anotherPlaylist 
	done 
} 

function func_getPlaylist() { 
	# obtain directory in which to work 
	printf '%s\n' "	→	Playlist:  " 
	read -rep "Please provide the path to the playlist you want to synchronize:  " -i "${playlistPath}" playlistPath 
	# expand the ~/ if it gets submitted 
	playlistPath="${playlistPath/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	playlistPath="${playlistPath//\\/}" 
	if [ -f "${playlistPath}" ] ; then 
		printf '%s\n' "	I have confirmed this is a directory:	${playlistPath}" "" 
	else 
		printf '%s\n' "	I cannot confirm this is a directory:	${playlistPath}" "" 
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
	printf '%s\n' "	→	Library Root:  " 
	read -rep "Please provide the root directory for your music library:  " -i "${directory_MusicLibraryRoot_source}" directory_MusicLibraryRoot_source 
	# expand the ~/ if it gets submitted 
	directory_MusicLibraryRoot_source="${directory_MusicLibraryRoot_source/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	directory_MusicLibraryRoot_source="${directory_MusicLibraryRoot_source//\\/}" 
	if [ -d "${directory_MusicLibraryRoot_source}" ] ; then 
		printf '%s\n' "	I have confirmed this is a directory:	${directory_MusicLibraryRoot_source}" "" 
	else 
		printf '%s\n' "	I cannot confirm this is a directory:	${directory_MusicLibraryRoot_source}" "" 
	fi 
} 

function func_getMusicLibraryRootLoop() { 
	while [ ! -d "${directory_MusicLibraryRoot_source}" ] ; do 
		func_getMusicLibraryRoot 
	done 
} 

function func_getPMPRoot() { 
	printf '%s\n' "	→	PMP Root:  " 
	read -rep "Please provide the root directory for your music player:  " -i "${directory_PMPRoot_destination}" directory_PMPRoot_destination 
	# expand the ~/ if it gets submitted 
	directory_PMPRoot_destination="${directory_PMPRoot_destination/#~/${HOME}}" 
	# fix spaces to be used in a quoted variable 
	directory_PMPRoot_destination="${directory_PMPRoot_destination//\\/}" 
	if [ -d "${directory_PMPRoot_destination}" ] ; then 
		printf '%s\n' "	I have confirmed this is a directory:	${directory_PMPRoot_destination}" "" 
	else 
		printf '%s\n' "	I cannot confirm this is a directory:	${directory_PMPRoot_destination}" "" 
	fi 
} 

function func_getPMPRootLoop() { 
	while [ ! -d "${directory_PMPRoot_destination}" ] ; do 
		func_getPMPRoot 
	done 
} 

function func_PMP_naughtyFilesystem() { 
	# if the PMP uses FAT or NTFS then sub certain characters with __ 
	printf '%s\n' "	→	Naughty file system swap:  " "" 
	printf '%s\n' "Some file systems are unable to handle certain characters.  " 
	printf '%s\n' "FAT and NTFS file systems in particular are bad about this.  " 
	printf '%s\n' "If you would like we can change : and ? into __ to avoid sync failures.  " 
	read -rep "Is your PMP formatted to use one of these lesser file systems?  (Y/n)  " -n1 naughtyFilesystem 
} 

function func_playlistParameters_calculate() { 
	syncSize=$( du -ch "${A_Source_sortU[@]}"  | tail -1 | cut -f 1 ) 
	printf '%s\n' "" "Playlist:		${playlistName}  " 
	printf '%s\n' "Track count:		${#A_Source_sortU[@]} " 
	printf '%s\n' "Approximate size:	${syncSize} " "" 
} 

function func_parsePlaylist() { 
	readarray -t A_Source_playlist <<< "$( grep -v '^#' "${playlistPath}" )" 
	readarray -t A_Source_sortU < <(printf '%s\0' "${A_Source_playlist[@]}" | sort -zu | xargs -0n1) 
	for (( i = 0 ; i < ${#A_Source_sortU[@]} ; i++ )) ; do 
		A_Source_dubUnders[${i}]="${A_Source_sortU[${i}]//\?/__}" 
		A_Source_dubUnders[${i}]="${A_Source_dubUnders[${i}]//\:/__}" 
		A_Destination_dubUnders[${i}]="${A_Source_dubUnders[${i}]}" 
		A_Destination_dubUnders[${i}]="${A_Destination_dubUnders[${i}]/${directory_MusicLibraryRoot_source}/${directory_PMPRoot_destination}}" 
		if [[ "${A_Source_sortU[${i}]}" =~ [\:|\?] ]] ; then 
			A_Source_colonquest_only+=( "${A_Source_sortU[${i}]}" ) 
			A_Destination_dubUnders_only+=( "${A_Destination_dubUnders[${i}]}" ) 
		fi 
		if [[ ! "${A_Source_sortU[${i}]}" =~ [\:|\?] ]] ; then 
			A_Source_dubless[${i}]="${A_Source_sortU[${i}]/${directory_MusicLibraryRoot_source}/}" 
		fi 
	done 
	func_playlistParameters_calculate 
	func_removeDestinationOrphans 
	if [ "${naughtyFilesystem}" != "n" ] ; then 
		func_rsync_naughtyPaths 
	fi 
	func_rsync_fullArrayAsFile 
} 

function func_rsync_naughtyPaths() { 
	printf '%s\n' "	→	Naughty file system sync:  " "" 
	printf '%b\n' "Next we will sync any :? → __ files.  " 
	func_EnterToContinue 
	if [[ ! "${A_Source_colonquest_only[*]}" = "" ]] ; then 
		for (( i = 0 ; i < ${#A_Source_colonquest_only[@]} ; i++ )) ; do 
			file_destinationPath="$( dirname -- "${A_Destination_dubUnders_only[${i}]}" )" 
			if [ ! -d "${file_destinationPath}" ] ; then 
				mkdir -p "${file_destinationPath}" 
			fi 
			files_Remain="$(( ${#A_Source_colonquest_only[@]} - ${i} ))" 
			printf '%b' "A sync of ${files_Remain} remains of ${#A_Source_colonquest_only[@]} files.  " 
			rsync -rltDvPmz "${A_Source_colonquest_only[${i}]}" "${A_Destination_dubUnders_only[${i}]}" 
		done 
	fi 
} 

function func_rsync_fullArrayAsFile() { 
	printf '%s\n' "" "	→	Regular file system sync:  " "" 
	printf '%b\n' "Now we can sync the remaining files as a group.  " 
	func_EnterToContinue 
	rsync -rltDvPmz --files-from=<( printf "%s\n" "${A_Source_dubless[@]}" ) "${directory_MusicLibraryRoot_source}" "${directory_PMPRoot_destination}" 
} 

function func_removeDestinationOrphans() { 
	printf '%s\n' "	→	Purge playlist orphans:  " "" 
	printf '%b\n' "First we will remove any files not present in your proposed playlist.  " 
	func_EnterToContinue 
	bash_version="$( bash --version | head -n1 | cut -d " " -f4 | cut -d "(" -f1 )" 
	if printf '%s\n' "4.4.0" "${bash_version}" | sort -V -C ; then 
		readarray -d '' A_Destination_orphans < <( find "${directory_PMPRoot_destination}" -type f -print0 ) # readarray or mapfile -d fails before bash 4.4.0 
		readarray -t -d '' A_Destination_orphans_diff < <( 
			printf "%s\0" "${A_Destination_dubUnders[@]}" "${A_Destination_orphans[@]}" | 
			sort -z | 
			uniq -zu 
		) 
	else 
		while IFS=  read -r -d $'\0'; do 
			A_Destination_orphans+=( "$REPLY" ) 
		done < <( find "${directory_PMPRoot_destination}" -type f -print0 ) 
		IFS=$'\37' read -r -d '' -a A_Destination_orphans_diff < <( 
		printf "%s\0" "${A_Destination_dubUnders[@]}" "${A_Destination_dubUnders[@]}" "${A_Destination_orphans[@]}" | 
			sort -z | 
			uniq -zu | 
			xargs -0 printf '%s\37' 
		) 
	fi 
	if [[ ! "${A_Destination_orphans_diff[*]}" = '' ]] ; then 
		for (( i = 0 ; i < ${#A_Destination_orphans_diff[@]} ; i++ )) ; do 
			rm "${A_Destination_orphans_diff[i]}" 
		done 
	fi 
} 

function func_purgeEmptyPMPFolders() { 
	printf '%s\n' "	→	Naughty file system swap:  " "" 
	printf '%s\n' "Finally we will purge any empty folders under the PMP root directory.  " 
	func_EnterToContinue 
	find "${directory_PMPRoot_destination}" -type d -empty -delete 
} 

function main() { 
	printf '%s\n' "" "Hello.  " "" 
	printf '%s\n' "This script is built to use m3u playlists.  " 
	printf '%s\n' "You can call this script with a playlist path as its argument.  " 
	printf '%s\n' "Crtl-z during a sync operation suspends the script job.  " 
	printf '%s\n' "Outside of a sync operation ctrl-c can be used to break out of the script" ""  
	func_GetCurrentUser 
	func_PMP_naughtyFilesystem 
	printf '%s\n' "" "This script swaps the first segment of the filepath for your Music Library with the same segment for your PMP Music location.  " 
	printf '%s\n' "So, the Library will be something like ~/YourUserName/Music and the PMP location might be like /media/PMP_drive/Music.  " "" 
	func_getMusicLibraryRootLoop 
	func_getPMPRootLoop 
	func_MultiplePlaylists 
	func_purgeEmptyPMPFolders 
	printf '%s\n' "" "Good-bye.  " "" 
} 

## 

########## 
#  Main  # 

main 

exit $? 

## 
