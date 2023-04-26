#! /usr/bin/env bash 
# Title   :  torrentDL_limitSet.sh 
# Parent  :  n/a 
# Author  :  JamesIsIn 20230422  Do something nice today.  

# Purpose :  Limit download speed on all incomplete torrents.   
# 			Only needs user:password if running this script remotely (not via 127.0.0.1) 
# 				Set in Transmission Preferences --> Remote --> Use authentication 
# 				Then add this variable to each transmission-remote call below and uncomment 
# 				So, each 'transmission-remote' becomes 'transmission-remote "${remoteAuth}"' 
## 


############### 
#  Variables  # 

# # debugging 
# 
# # 

declare torrentID 
declare -a A_torrentList 
# readonly remoteAuth="--auth=specialTransmissionUser:\"somethingComplex!@#&&fish\"" 

## 


############### 
#  Functions  # 

function func_setDownloadLimit() { 
	if ! transmission-remote --torrent "${torrentID}" --info | grep -q "Upload Limit: 1 kB/s" ; then 
		transmission-remote --torrent "${torrentID}" --uplimit 1 --bandwidth-low 
	fi 
} 

function func_processList() { 
	for torrentID in "${A_torrentList[@]}" ; do 
		if ! transmission-remote --torrent "${torrentID}" --info | grep -q "Percent Done: 100%" ; then 
			func_setDownloadLimit 
		fi 
	done 
} 

function func_getTorrentList() { 
	local loc_bashVersion 
		loc_bashVersion="$( bash --version | head -n1 | cut -d " " -f4 | cut -d "(" -f1 )" 
	# readarray or mapfile -d fails before bash 4.4.0 
	if printf '%s\n' "4.4.0" "${loc_bashVersion}" | sort -V -C ; then 
		mapfile -d $'\0' A_torrentList < <( transmission-remote --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1 ) 
	else 
		while IFS= read -r ; do 
			A_torrentList+=( "$REPLY" ) 
		done < <( transmission-remote --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1 ) 
	fi 
} 

function main() { 
	func_getTorrentList 
	func_processList 
} 

## 


########## 
#  Main  # 

main 

exit $? 

## 
