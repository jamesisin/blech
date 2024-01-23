#! /usr/bin/env bash 
# Title   :  specialFilmLinks.sh 
# Parent  :  n/a 
# Author  :  JamesIsIn 20240104  Do something nice today.  

# Purpose :  Find special objects (marked like 🎄) and create sym-links to the respecitve folders (x-mas 🎄).   
# 

## 

################## 
#  Declarations  # 

declare -A AA_targetCharacter 
	# AA_targetCharacter[]="/" # template 
	# 
	AA_targetCharacter[✭]="✭/" 
	AA_targetCharacter[✭✭]="✭✭/" 
	AA_targetCharacter[👁]="animated 👁/" 
	AA_targetCharacter[💩]="happy-crappy 💩/" 
	AA_targetCharacter[🧠]="hero_AI 🧠/" 
	# AA_targetCharacter[????]="hero_comics ????/" 
	AA_targetCharacter[℻]="hero_faux-min ℻/" 
	AA_targetCharacter[☢]="hero_genes ☢/" 
	AA_targetCharacter[🦸]="hero_super 🦸/" 
	AA_targetCharacter[🔎]="intrigue 🔎/" 
	AA_targetCharacter[␠]="lang_ES ␠/" 
	AA_targetCharacter[⚜]="lang_FR ⚜/" 
	AA_targetCharacter[🍕]="lang_IT 🍕/" 
	AA_targetCharacter[☠]="post-apocalyptic ☠/" 
	AA_targetCharacter[🚀]="SpaceGal 🚀/" 
	AA_targetCharacter[👽]="SpaceGal_firstContact 👽/" 
	AA_targetCharacter[⌚]="time ⌚/" 
	AA_targetCharacter[🧛]="vampires 🧛/" 
	AA_targetCharacter[🎄]="x-mas 🎄/" 
	AA_targetCharacter[🧟]="zombies 🧟/" 
# 
declare targetSymbol 
readonly -a const_A_mDLNAroot=( "/media/Works/mDLNA/2watch/" "/media/Works/mDLNA/watched/" "/media/Works/mDLNA/Super/" ) 
readonly const_specialsRoot="/media/Works/mDLNA/zz_etc/" 
declare targetSymbol 

# # debugging 
# 
# AA_targetCharacter[💩]="happy-crappy 💩/" # this is a small non-null folder and file result-set 
# 
# # 

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
	find "${const_specialsRoot}" -type l -delete 
} 

function func_createSoftLinks() { 
	# create soft links in the target directory based on the found objects array 
	for filePath in "${loc_A_foundFilePaths[@]}" ; do 
		linkName="$( basename "${filePath}" )" 
		linkPath="${const_specialsRoot}${AA_targetCharacter[${targetSymbol}]}" 
		# ln -s "${A_coverList[i]/\/media\/Tunas\/iTuna/'../../..'}" "${const_coverSymLinkFolder}""${loc_linkName}" # from coverLinnks.sh 
		if [[ -L "${linkPath}${linkName}" ]] ; then 
			linkNameAug="${linkName/#/'zzWatched'}" 
			ln -s "${filePath/\/media\/Works\/mDLNA/'../..'}" "${linkPath}${linkNameAug}" # must use relative links for Samba 
		else 
			ln -s "${filePath/\/media\/Works\/mDLNA/'../..'}" "${linkPath}${linkName}" # must use relative links for Samba 
		fi 
	done 
} 

function func_findMarkedObjects() { 
	# function to find files and load array of files or file paths 
	local -a loc_A_foundFilePaths 
	for path in "${const_A_mDLNAroot[@]}" ; do 
		mapfile -d '' -O"${#loc_A_foundFilePaths[@]}" loc_A_foundFilePaths < <( find "${path}" -name "*${targetSymbol}*" -print0 ) 
		# mapfile -d '' loc_A_foundFilePaths < <( find /media/Works/mDLNA/watched/ -name "*💩*" -print0 ) # debug example 
	done 
	# prints "quantity of symbol" 
	printf '%s' "${#loc_A_foundFilePaths[@]} of ${#loc_A_foundFilePaths[@]} " 
	# yes line prints a line of that number of those symbols 
	yes "${targetSymbol}" | head -"${#loc_A_foundFilePaths[@]}" | paste -s -d '' - 
	export loc_A_foundFilePaths 
	func_createSoftLinks 
} 

function func_loop_findMarkedObjects() { 
	# loop through AA_targetCharacter calling necessary functions per key-value pair 
	for targetSymbol in "${!AA_targetCharacter[@]}" ; do 
		printf '%s\n' "Starting ${targetSymbol}.  " 
		func_findMarkedObjects 
		printf '%s\n' "${targetSymbol} completed.  " 
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

exit $? 

## 
