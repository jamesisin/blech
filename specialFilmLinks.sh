#! /usr/bin/env bash 
# Title   :  specialFilmLinks.sh 
# Parent  :  n/a 
# Author  :  JamesIsIn 20250429  Do something kind today.  

# Purpose :  Find special objects (marked like 🎄) and create sym-links to the respecitve folders (x-mas 🎄).   
# 
## 

################## 
#  Declarations  # 

# # debugging 
# AA_targetCharacter[💩]="happy-crappy 💩/" # smallish non-null folder and file result-set 
# set -x 
# # 

declare -A AA_targetCharacter 
	# AA_targetCharacter[]="/" # template 
	# 🪞 # process this as 2watch only (thus exclude 2_ prepend) 
	AA_targetCharacter[🪞]="🪞/" 
	AA_targetCharacter[✭]="✭/" 
	AA_targetCharacter[✭✭]="✭✭/" 
	AA_targetCharacter[👁]="animated 👁/" 
	AA_targetCharacter[😊]="comedy 😊/" 
	AA_targetCharacter[Ⓑ]="doc→biopic Ⓑ/" 
	AA_targetCharacter[Ⓓ]="doc→documentary Ⓓ/" 
	AA_targetCharacter[⏻]="dystopian ⏻/" 
	AA_targetCharacter[💩]="happy-crappy 💩/" 
	AA_targetCharacter[🧠]="hero→AI 🧠/" 
	AA_targetCharacter[☣]="hero→bio ☣/" 
	AA_targetCharacter[🗝]="hero→comics 🗝/" 
	AA_targetCharacter[℻]="hero→faux-min ℻/" 
	AA_targetCharacter[☢]="hero→genes ☢/" 
	AA_targetCharacter[🦸]="hero→super 🦸/" 
	AA_targetCharacter[🤡]="horror 🤡/" 
	AA_targetCharacter[🧛]="horror→vampires 🧛/" 
	AA_targetCharacter[🧟]="horror→zombies 🧟/" 
	AA_targetCharacter[🔎]="intrigue 🔎/" 
	AA_targetCharacter[␠]="lang→ES ␠/" 
	AA_targetCharacter[⚜]="lang→FR ⚜/" 
	AA_targetCharacter[🍕]="lang→IT 🍕/" 
	AA_targetCharacter[🍣]="lang→JE 🍣/" 
	AA_targetCharacter[♬]="musica ♬/" 
	AA_targetCharacter[☠]="post-apocalyptic ☠/" 
	AA_targetCharacter[♡]="rom ♡/" 
	AA_targetCharacter[🔬]="sci-fi 🔬/" 
	AA_targetCharacter[🚀]="SpaceGal 🚀/" 
	AA_targetCharacter[👽]="SpaceGal→firstContact 👽/" 
	AA_targetCharacter[⌚]="time ⌚/" 
	AA_targetCharacter[🎄]="x-mas 🎄/" 
# 
declare targetSymbol 
declare prepend 
readonly -a const_A_mDLNAroot=( "/media/Works/mDLNA/2watch/" "/media/Works/mDLNA/aA-zZ/" "/media/Works/mDLNA/aA-zZ [episodic]/" ) 
readonly const_specialsRoot="/media/Works/mDLNA/zz_etc/" 

## 

############### 
#  Functions  # 

function func_testRoot() { 
	if [[ "${USER}" == root ]] ; then # check if some naughty monster is logged in as root 
		if [[ "${SUDO_USER}" == "" ]] ; then # sudo is ok 
			printf '%s\n' "" "It is a bad practice to log in as root.  " "Log in as yourself and use sudo.  " "" 
			exit 0 
		fi 
	fi 
} 

function func_removeOldSoftLinks() { 
	# find and remove any existing links from the specials hierarchy 
	# this helps keep the specials directory clear of stale links 
	# find "${const_specialsRoot}" -type l -delete 
	find "${const_specialsRoot}" -xtype l -delete # this only removes orphans 
} 

function func_createSoftLinks() { 
	# create soft links in the target directory based on the found objects array 
	for filePath in "${loc_A_foundFilePaths[@]}" ; do 
		linkName="$( basename "${filePath}" )" 
		linkPath="${const_specialsRoot}${AA_targetCharacter[${targetSymbol}]}" 
		linkNameAug="${linkName/#/${prepend}}" # prevent folder collisions from separate roots 
		if ! [[ -L "${linkPath}${linkNameAug}" ]] ; then 
			if [[ "${targetSymbol}" = "✭" ]] && [[ "${linkNameAug}" = *"✭✭"* ]] ; then 
				: # don't add two star items to single star folder 
			else 
				ln -s "${filePath/\/media\/Works\/mDLNA/'../..'}" "${linkPath}${linkNameAug}" # must use relative links for Samba 
			fi 
		fi 
	done 
} 

function func_findMarkedObjects() { 
	# function to find files and load array of files or file paths 
	local -a loc_A_foundFilePaths 
	if [[ "${path}" == "/media/Works/mDLNA/2watch/" ]] && [[ "${targetSymbol}" = "✭" ]] ; then 
		return 0 
	elif [[ "${path}" == "/media/Works/mDLNA/2watch/" ]] && [[ "${targetSymbol}" = "✭✭" ]] ; then 
		return 0 
	fi 
	unset prepend 
	if [[ "${path}" == "/media/Works/mDLNA/2watch/" ]] && [[ "${targetSymbol}" != "🪞" ]] ; then 
		prepend="2__" 
	fi 
	mapfile -d '' -O"${#loc_A_foundFilePaths[@]}" loc_A_foundFilePaths < <( find "${path}" -name "*${targetSymbol}*" -print0 ) 
	# mapfile -d '' loc_A_foundFilePaths < <( find /media/Works/mDLNA/watched/ -name "*💩*" -print0 ) # debug example 
	# prints "quantity of symbol" 
	printf '%s\n' "	${#loc_A_foundFilePaths[@]} of ${targetSymbol} from ${path}" 
	# yes line prints a line of that number of those symbols 
	yes "${targetSymbol}" | head -"${#loc_A_foundFilePaths[@]}" | paste -s -d '' - 
	export loc_A_foundFilePaths 
	func_createSoftLinks 
} 

function func_loop_findMarkedObjects() { 
	# loop through AA_targetCharacter calling necessary functions per key-value pair 
	for targetSymbol in "${!AA_targetCharacter[@]}" ; do 
		printf '%s\n' "Starting ${targetSymbol}.  " 
		for path in "${const_A_mDLNAroot[@]}" ; do 
			export path 
			func_findMarkedObjects 
		done 
		printf '%s\n' "${targetSymbol} completed.  " "" 
	done 
} 

function main() { 
	# 
	func_testRoot 
	func_removeOldSoftLinks 
	func_loop_findMarkedObjects 
	unset 
} 

## 

########## 
#  Main  # 

main 
exit ${?} 

## 
