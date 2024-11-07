#!/usr/bin/env python3 
# Title   :  CalculateCoprimesPi.py 
# Parent  :  none 
# Author  :  JamesIsIn 20190407 Do something kind today. 

# Purpose :  Calculate coprimes of pi like https://www.youtube.com/watch?v=RZBhSi_PwHU 
# 
## 

##############
#  Includes  # 

from random import randint 
from math import pi 
from math import sqrt 

## 

################## 
#  Declarations  # 

countRolls = 0 
countCoprime = 0 
countCommonFactor = 0 
totalRolls = 500 
piEstimate = 0 
dieMin = 1 
dieMax = 100 
twoRolls = [ 0,0 ] 

## 

############### 
#  Functions  # 

def func_getUserInput(): 
	"""Ask user for die size and total rolls.  """ 
	global dieMin 
	global dieMax 
	global totalRolls 
	print( "" ) 
	while True: 
		try: 
			dieMax = int( input( "How many sides on each die (blank accepts {})?  ".format( dieMax ) ) or dieMax ) 
		except ValueError: 
			print( "You can only use integers for this value.  " ) 
		else: 
			break 
	while True: 
		try: 
			totalRolls = int( input( "How many rolls for each pair of dice (blank accepts {})?  ".format( totalRolls ) ) or totalRolls ) 
		except ValueError: 
			print( "You can only use integers for this value.  " ) 
		else: 
			break 
	if dieMax > 4999999999 or totalRolls > 4999999999: 
		print( "We have no idea how long that might take.  " ) 
	if dieMax > 499999 or totalRolls > 499999: 
		print( "Whoa!  Hold onto your butt!  " ) 
	print( "" ) 

def func_rollDie(): 
	"""Roll a die.  """ 
	global dieMin 
	global dieMax 
	return( randint( dieMin , dieMax ) ) 

def func_rollDice(): 
	"""Roll two dice for comparison.  """ 
	# call func_rollDie twice and get two values in a tuple 
	global twoRolls 
	global countRolls 
	twoRolls = [ func_rollDie() , func_rollDie() ] 
	twoRolls.sort() 
	# print( twoRolls ) 
	countRolls += 1 
	return 

def func_loopRollingDice(): 
	"""Loop for rolling all the pairs.  """ 
	while countRolls < totalRolls:  
		func_rollDice() 
		func_calculateCoprime() 

def func_calculateCoprime(): 
	"""Look for LCD greater than one.  """ 
	global countCommonFactor 
	global countCoprime 
	if twoRolls[0] == 1 or twoRolls[1] == 1: 
		countCoprime += 1 
		return 
	if twoRolls[0] == twoRolls[1]: 
		countCommonFactor += 1 
		return 
	if twoRolls[0] % 2 == 0 and twoRolls[1] % 2 == 0: 
		countCommonFactor += 1 
		return 
	for factor in range(3,twoRolls[0],2): 
		if twoRolls[0] % factor == 0 and twoRolls[1] % factor == 0: 
			countCommonFactor += 1 
			return 
	countCoprime += 1 
	return 

def func_calculatePi(): 
	"""Calculate pi based on ratio of coprimes.  """ 
	global piEstimate 
	piEstimate = sqrt( 6/( countCoprime/totalRolls ) ) 

def func_calculatePiAccuracy(): 
	"""Compare calulated pi with actual pi.  """ 
	print( "We've rolled  {0:,}  pairs of {1:,}-sided dice.  ".format( countRolls , dieMax ) ) 
	print( "This gives us {0:,}  coprimes and {1:,} with common factors.  ".format( countCoprime , countCommonFactor ) ) 
	print( "" ) 
	print( "Here we can compare our estimate of pi (above) with real pi (below).  " ) 
	print( "	{0}  ".format( piEstimate ) ) 
	print( "	{0}  ".format( pi ) ) 
	pis = [ piEstimate , pi ] 
	pis.sort() 
	piRatio = 100 - ( 100 * ( pis[0] / pis[1] ) ) 
	print( "That's only {0}% off!  ".format( piRatio ) ) 
	print( "" ) 

def main(): 
	"""Do all the business!  """ 
	func_getUserInput() 
	func_loopRollingDice() 
	func_calculatePi() 
	func_calculatePiAccuracy() 

## 

########## 
#  Main  # 

if __name__ == "__main__":  
	main() 

raise SystemExit(0) 

## 
