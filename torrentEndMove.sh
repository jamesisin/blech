#! /usr/bin/env bash 
# Title   :  torrentEndMove.sh 
# Parent  :  n/a 
# Author  :  JamesIsIn 20230420  Do something nice today.  

# Purpose :  When a torrent compeletes, move it.   
# 			To be run by Transmission automatically (though can be run manually).  
#				Add script at Transmission Preferences --> Downloading --> Call script when… 
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

readonly destinationPath="/media/princeofparties/3TB_ext4/" 
declare bash_version 
declare torrentID 
declare -a A_torrentList 
# readonly remoteAuth="--auth=specialTransmissionUser:\"somethingComplex!@#&&fish\"" 

## 


############### 
#  Functions  # 

function func_confirmRatio() { 
	# if ratio is unsusual or unexpected, don't process 
	# instead consider if this torrent can be made more healthy by extended sharing 
	local ratio 
		ratio="$( transmission-remote --torrent ${torrentID} --info | grep Ratio: | sed 's/Ratio:\ //' )" 
	if ${ratio} > 0 && ${ratio} < 3 ; then 
		func_processTorrentEnd 
	else 
		printf '%s\n' "Consider torrent ${torrentID} as high ratio seeding candidate.  " 
	fi 
} 

function func_getTorrentList() { 	
	bash_version="$( bash --version | head -n1 | cut -d " " -f4 | cut -d "(" -f1 )" 
	# readarray or mapfile -d fails before bash 4.4.0 
	if printf '%s\n' "4.4.0" "${bash_version}" | sort -V -C ; then 
		mapfile -d $'\0' A_torrentList < <( transmission-remote --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1 ) 
	else 
		while IFS= read -r ; do 
			A_torrentList+=( "$REPLY" ) 
		done < <( transmission-remote --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1 ) 
	fi 
} 

function func_processTorrentEnd() { 
	for torrentID in "${A_torrentList[@]}" ; do 
		if transmission-remote --torrent "${torrentID}" --info | grep -q "Percent Done: 100%" && transmission-remote --torrent "${torrentID}" --info | grep -q "State: Finished" ; then 
			# verify contents 
			transmission-remote -t "${torrentID}" --verify 
			while transmission-remote --torrent "${torrentID}" --info | grep -q "State: Verifying" ; do 
				printf '%s\n' "Sleeping for one minute to await verify (${torrentID}).  Will re-check.  " 
				date 
				sleep 60 # find a better way to wait for verify?  
			done 
			# check again in case verify located bad packets 
			if transmission-remote --torrent "${torrentID}" --info | grep -q "Percent Done: 100%" && transmission-remote --torrent "${torrentID}" --info | grep -q "State: Finished" ; then 
				# move then remove the file(s) 
				transmission-remote --torrent "${torrentID}" --move "${destinationPath}" && transmission-remote --torrent "${torrentID}" --remove 
			else 
				printf '%s\n' "Ignoring torrent ${torrentID} as incomplete.  " 
			fi 
		fi 
	done
} 

function main() { 
	func_getTorrentList 
	func_confirmRatio 
} 

## 


########## 
#  Main  # 

main 

exit $? 

## 
