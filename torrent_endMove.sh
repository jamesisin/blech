#! /usr/bin/env bash 
# Title   :  torrentEndMove.sh 
# Parent  :  n/a 
# Author  :  JamesIsIn 20230420  Do something nice today.  

# Purpose :  When a torrent compeletes, move it.   
# 			To be run by Transmission automatically (though can be run manually).  
#				Add script at Transmission Preferences --> Seeding --> Call script when… 
# 			Only needs user:password if running this script remotely (not via 127.0.0.1) 
# 				Set in Transmission Preferences --> Remote --> Use authentication 
# 				Then add this variable to each transmission-remote call below and uncomment 
# 				So, each 'transmission-remote' becomes 'transmission-remote "${remoteAuth}"' 
# 			Transmission supplies three arguments when it calls either the downloaded or completed scripts.  
# 				TR_TORRENT_DIR=${TR_TORRENT_DIR:-$1}
# 				TR_TORRENT_NAME=${TR_TORRENT_NAME:-$2}
# 				TR_TORRENT_ID=${TR_TORRENT_ID:-$3}
# 			So you can use positional parameters to capture them and the script-call looks something like this:  
# 				/path/to/your/script.sh "${TR_TORRENT_DIR}" "${TR_TORRENT_NAME}" "${TR_TORRENT_ID}" 
# 				/path/to/your/script.sh /path/to/completed/folder "That thing you always wanted" 909 
## 


############### 
#  Variables  # 

# # debugging 
# 
# # 

readonly destinationPath="/media/jamesisi/3TB_ext4/" 
# declare torrentDirectory 
# 	torrentDirectory="${1}" 
declare torrentName 
	torrentName="${2}" 
declare torrentID 
	torrentID="${3}" 
declare -a A_torrentList 
# readonly remoteAuth="--auth=specialTransmissionUser:\"somethingComplex!@#&&fish\"" 

## 


############### 
#  Functions  # 

function func_verifyAndRemove() { 
	# verify contents 
	transmission-remote -t "${torrentID}" --verify 
	while transmission-remote --torrent "${torrentID}" --info | grep -q "State: Verifying\|State: Will Verify" ; do # add or awaiting verification or whatever 
		printf '%s\n' "" "Sleeping for one minute to await verify (${torrentID}:  ${torrentName}).  Will re-check.  " 
		date ; sleep 60 # find a better way to wait for verify?  
	done 
	# check again in case verify located bad packets 
	if transmission-remote --torrent "${torrentID}" --info | grep -q "Percent Done: 100%" && transmission-remote --torrent "${torrentID}" --info | grep -q "State: Finished" ; then 
		# move then remove the file(s) 
		transmission-remote --torrent "${torrentID}" --move "${destinationPath}" && transmission-remote --torrent "${torrentID}" --remove 
	else 
		printf '%s\n' "Ignoring torrent ${torrentID} (${torrentName}) as incomplete.  " 
	fi 
} 

function func_confirmRatio() { 
	# if ratio is unsusual or unexpected, don't process 
	# instead consider if this torrent can be made more healthy by extended sharing 
	local loc_ratio 
		loc_ratio="$( transmission-remote --torrent "${torrentID}" --info | grep Ratio: | sed 's/\ \ Ratio:\ //' )" 
	local loc_ratioLimit 
		loc_ratioLimit="$( transmission-remote --torrent "${torrentID}" --info | grep "Ratio Limit:" | sed 's/\ \ Ratio Limit:\ //' )" 
		if [ "${loc_ratioLimit}" == "Default" ] ; then 
			# if you change the default ratio value in the Transmission preferences, you must also change this set-value 
			loc_ratioLimit="2.22" 
		fi 
	if [[ ${loc_ratio} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then 
		# passing floating point numbers to bc allows bash to do non-integer math 
		if (( $( printf '%s\n' "${loc_ratio} <= ${loc_ratioLimit}" | bc -l ) )) ; then 
			func_verifyAndRemove 
		else 
			printf '%s\n' "Consider torrent ${torrentID} as high ratio seeding candidate (Ratio:  ${loc_ratio}).  " 
		fi 
	else 
		printf '%s\n' "Check torrent ${torrentID} ratio manually as it's non-numeric (Ratio:  ${loc_ratio}).  " 
		return 255 
	fi
} 

function func_processTorrentEnd() { 
	if transmission-remote --torrent "${torrentID}" --info | grep -q "Percent Done: 100%" && transmission-remote --torrent "${torrentID}" --info | grep -q "State: Finished" ; then 
		func_confirmRatio 
	fi 
} 

function func_processList() { 
	for torrentID in "${A_torrentList[@]}" ; do 
		func_processTorrentEnd 
	done 
} 

function func_getTorrentList() { 
	# local loc_bashVersion 
	# 	loc_bashVersion="$( bash --version | head -n1 | cut -d " " -f4 | cut -d "(" -f1 )" 
	printf '%s\n' "Running manual iteration version.  " "" 
	# readarray or mapfile -d fails before bash 4.4.0 
	# why the fuck is mapfile not working in bash 5.1.16?  Is this code bad?  
	# if printf '%s\n' "4.4.0" "${loc_bashVersion}" | sort -V -C ; then 
	# 	mapfile -d $'\0' A_torrentList < <( transmission-remote --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1 ) 
	# else 
		while IFS= read -r ; do 
			A_torrentList+=( "$REPLY" ) 
		done < <( transmission-remote --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1 ) 
	# fi 
} 

function main() { 
	if [ $# -lt 3 ] ; then 
		func_getTorrentList 
		func_processList 
	else 
		printf '%s\n' "Running positional parameter version.  " 
		func_processTorrentEnd 
	fi 
} 

## 


########## 
#  Main  # 

main "${@}" 

exit $? 

## 
