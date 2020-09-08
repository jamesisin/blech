#!/usr/bin/env python3 
# Title   :  RenameWithSubtraction.py 
# Parent  :  none 
# Author  :  JamesIsIn 20190407 Do something nice today. 

# Purpose :  Rename files by changing page numbers.  
# 

## 



## 

############## 
#  Includes  # 

import os 

## 

############### 
#  Variables  # 

global books 

## 

############### 
#  Functions  # 

def getAndSortFilenames():  
	global books 
	os.chdir("/path/to/folder") 
	books=os.listdir() 
	books.sort() 

def renameFiles():  
	i=2 
	for file in books:  
		ii=format(i, '02d') 
		filename=file 
		renamefile="book"+str(ii)+".jpg" 
		os.rename(filename,renamefile) 
		print(filename+" becomes "+renamefile) 
		i+=1 


def main(): 
	getAndSortFilenames() 
	renameFiles() 
	print() 

## 

########## 
#  Main  # 

if __name__ == "__main__":  
	main() 

raise SystemExit(0) 

## 
