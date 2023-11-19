#! /usr/bin/env bash 
# Title   :  coverLinks.sh 
# Parent  :  NONE 
# Author  :  JamesIsIn 20190918  Do something nice today.  

# Purpose :  Create soft links to every cover image in the collection into one folder.  
# 			 Exclude images demarked as poor quality.  
# 			 Links are to be used to generate backgrounds on rotation or slideshows of album art.  
# 

## 

############### 
#  Variables  # 

readonly const_rootDirectory="/music/root/path/" 
readonly const_coverSymLinkFolder="/music/root/path/zetc/CoverSlideshow/SymLinks/" # a unique folder to house only these cover links 
declare -a A_coverList 

# # debugging 
# 
# # 

## 

############### 
#  Functions  # 

function func_findCovers() { 
	local loc_bashVersion 
		loc_bashVersion="$( bash --version | head -n1 | cut -d " " -f4 | cut -d "(" -f1 )" 
	# readarray or mapfile -d fails before bash 4.4.0 
	if printf '%s\n' "4.4.0" "${loc_bashVersion}" | sort -V -C ; then 
		mapfile -d '' A_coverList < <( 
			find "${const_rootDirectory}" -type f ! -name "*🛇*" -iregex '^.*cover.*\.\(jpg\|png\|bmp\|tif\)$' ! \( -path "${const_rootDirectory}/zetc/*" -o -path "${const_rootDirectory}/xfer/*" -prune \) -print0 
		) 
	else 
		while IFS= read -r ; do 
			A_coverList+=( "$REPLY" ) 
		done < <( find "${const_rootDirectory}" -type f ! -name "*🛇*" -iregex '^.*cover.*\.\(jpg\|png\|bmp\|tif\)$' ! \( -path "${const_rootDirectory}/zetc/*" -o -path "${const_rootDirectory}/xfer/*" -prune \) ) 
	fi 
	printf '%s\n' "" "I have found ${#A_coverList[@]} cover.  " "" 
} 

function func_removeOldSymLinks() { 
	# find and remove any existing links, keeping the directory clear of stale links 
	find "${const_coverSymLinkFolder}" -type l -delete 
	# rm "${const_coverSymLinkFolder}"/* # revert to this version if hardlinks are required 
} 

function func_createSymLinks() { 
	local loc_foundFileName 
	local loc_foundFilePath 
	local loc_directoryAlbum 
	local loc_directoryArtist 
	local loc_linkName 
	for (( i=0 ; i < ${#A_coverList[@]} ; i++ )) ; do 
		loc_foundFileName="$( basename "${A_coverList[i]}" )" 
		loc_foundFilePath="$( dirname "${A_coverList[i]}" )" 
		loc_directoryAlbum="$( basename "${loc_foundFilePath}" )" 
			loc_directoryAlbum="${loc_directoryAlbum/\ \[*/}" 
		loc_directoryArtist="$( basename "$( dirname "${loc_foundFilePath}" )" )" 
			loc_directoryArtist="${loc_directoryArtist/\ \[*/}" 
		loc_linkName="${i}__${loc_directoryArtist}__${loc_directoryAlbum}__${loc_foundFileName}" 
		# use escapes to print to one line as in this test example 
		# while true ; do printf "\e[2K" ; sleep 0.1 ; printf "Yes" ; sleep 0.1 ; printf  "\e[1A\n" ; sleep 0.1 ; done 
		# this sometimes prints to new lines, perhaps mistaking other characters as escapes 
		# this repeat behavior differs depending on the machine from which I ssh to the server, so that's unexpected 
		printf "\e[2K" 
		printf '%s' "Linking:  ${loc_linkName}" 
		printf "\e[1A\n" 
		# multiline output version 
		# printf '%s\n' "Linking:  ${loc_linkName}" 
		# must use relative links (if using soft links) for Samba 
		ln -s "${A_coverList[i]/\/music\/root\/path/'../../..'}" "${const_coverSymLinkFolder}""${loc_linkName}" 
		# ln "${A_coverList[i]}" "${const_coverSymLinkFolder}"${loc_linkName}" # hardlink (absolute) version 
	done 
} 

function main() { 
	func_findCovers 
	func_removeOldSymLinks 
	func_createSymLinks 
	printf '%s\n' "" "All done!  " "" 
	unset 
} 

## 

########## 
#  Main  # 

main 

exit $? 

## 
