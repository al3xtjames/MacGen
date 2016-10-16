#!/bin/bash
#
# Simple Main Logic Board (MLB) Serial Generator Script by theracermaster
# Heavily based off MLBGen scripts by wolfmannightNotH1AX & AGuyWhoIsBored (thanks!)
# Thanks to holyfield, Pike, and everyone else in the InsanelyMac thread for info about the MLB format
#
# After getting a value, insert it in Clover's config.plist under RtVariables -> MLB, then reboot.
# Make sure you have a valid (doesn't have to be real) serial number and RtVariables -> ROM set to UseMacAddr0.
# Try logging into iMessage. If you get a customer code, call Apple and go through the process. iMessage should now work.
#
# Changelog:
# Version 1.1 - Add user input support; you can now input a serial number (as an argument: ./simpleMLB.sh XXXXXXXXXXXX) and the script will use that to generate a MLB
# Version 1.2 - Add more input checks for valid serial number and working internet connection; added support for generating 13 character MLB (does it if serial number is 11 characters)
# Version 1.3 - Fixed some bugs; removed internet connection requirement; now, the script gets week and year numbers from the serial number itself (more accurate than random generation)
# Version 1.4 - Added debug mode which prints info about the serial number and each step of the MLB generation process
# Version 2.0 - Near complete rewrite of source code; new error and debug formatting/printing added

# Initialize global variables

## The script version
gScriptVersion="2.0"
## Debug mode, setting to 1 will print out information about the input serial number & generated MLB values
gDebug=0

## The repo folder
gRepo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

## The input Mac model
gProductName="$1"
## The input system serial number (SN)
gSerialNumber="$2"
## The main logic board serial number (MLB), will be generated later
gMLB=""

## The location from the input serial number, will be properly initialized later
gLocation=""

source "$gRepo/common.sh"

#-------------------------------------------------------------------------------#
function _printSerialNumber()
{
	printf "\n     "

	serialNumberPPP=$(echo $gSerialNumber | cut -c 1-3)
	serialNumberY=$(echo $gSerialNumber | cut -c 4)
	serialNumberW=$(echo $gSerialNumber | cut -c 5)
	serialNumberSSS=$(echo $gSerialNumber | cut -c 6-8)
	serialNumberCCCC=$(echo $gSerialNumber | cut -c 9-12)
	printf "${STYLE_BOLD}${COLOR_GREEN}$serialNumberPPP ${COLOR_RED}$serialNumberY ${COLOR_BLUE}$serialNumberW ${COLOR_END}${STYLE_BOLD}$serialNumberSSS ${COLOR_PURPLE}$serialNumberCCCC${STYLE_RESET}\n"
}

function _checkSerialNumber()
{
	# Check for input of the product name; if it doesn't exist, get the serial number from the IORegistry
	if [ -z "$gProductName" ] && [ -z "$gSerialNumber" ]; then
		gProductName=$(ioreg -k product-name -d 2 | awk '/product-name/ {print $3}' | tr -d '"<>')
		gSerialNumber=$(ioreg -k IOPlatformSerialNumber -d 2 | awk '/IOPlatformSerialNumber/ {print $3}' | tr -d '"')
		if [ $gDebug -eq 1 ]; then
			_printDebug "NOTE" "No input product name found, using IORegistry value (${STYLE_BOLD}$gProductName${STYLE_RESET})"
			_printDebug "NOTE" "No input serial number found, using IORegistry value (${STYLE_BOLD}$gSerialNumber${STYLE_RESET})"
		fi
	elif [ -z "$gProductName" ] || [ -z "$gSerialNumber" ]; then
		echo "simpleMLBSerial.sh v$gScriptVersion - Simple MLB generator script by theracermaster"
		echo
		echo "Usage ./simpleMLBSerial.sh <product name> <serial number>"
		echo "     <product name>      Target Mac product name (model ID)"
		echo "     <serial number>     Target Mac serial number"
		echo "     -h                  Help (this screen)"
		echo
		echo "If no arguments are specified, system values from the IORegistry will be used."
		exit 0
	fi

	# Verify that serial number is 12 characters
	if [ ${#gSerialNumber} -ne 12 ]; then
		_printSerialNumber
		_printError "Invalid serial number (length mismatch)!"
	fi
}

function _generateMLB()
{
	# Source existing model data from config
	if [[ $gProductName =~ "iMac" ]]; then
		source "$gRepo/data/iMac.cfg"
	elif [[ $gProductName =~ "MacBookAir" ]]; then
		source "$gRepo/data/MacBook Air.cfg"
	elif [[ $gProductName =~ "MacBookPro" ]]; then
		source "$gRepo/data/MacBook Pro.cfg"
	elif [[ $gProductName =~ "MacBook" ]]; then
		source "$gRepo/data/MacBook.cfg"
	elif [[ $gProductName =~ "Macmini" ]]; then
		source "$gRepo/data/Mac mini.cfg"
	elif [[ $gProductName =~ "MacPro" ]]; then
		source "$gRepo/data/Mac Pro.cfg"
	else
		_printError "Invalid model identifier!"
	fi

	# Get the manufacturing location from the serial number
	PPP=$(echo $gSerialNumber | cut -c 1-3)
	if [ $gDebug -eq 1 ]; then
		location=$(_decodeLocationValue $PPP)
		_printDebug "Manufacturing location (from serial number)" "$location"
	fi

	# Get the Y value (manufacturing year) from the serial number
	serialNumberY=$(echo $gSerialNumber | cut -c 4)
	# Decode the serial number Y value to get the MLB Y value
	Y=$(_decodeYearValue $serialNumberY)
	if [ $gDebug -eq 1 ]; then
		_printDebug "Manufacturing year (from serial number)" $Y
	fi

	# Get the WW value (manufacturing week) from the serial number
	serialNumberW=$(echo $gSerialNumber | cut -c 5)
	# Decode the serial number W value to get the MLB WW value
	## MLB WW value is one week before the serial number W value
	WW=$(($(_decodeWeekValue $serialNumberY $serialNumberW) - 1))
	if [ $gDebug -eq 1 ]; then
		_printDebug "Manufacturing week (from serial number)" $WW
	fi

	# Get the TTT value (board type) from the model data
	TTT=$boardType
	if [ $gDebug -eq 1 ]; then
		_printDebug "Generated board type" $TTT
	fi

	# Generate the CC value (checksum?)
	# TODO: Research if this is a checksum, and see if it is possible to calculate it from the ROM
	declare -a CCCodes=('GU' '4N' 'J9' 'QX' 'OP' 'CD' '3F' 'U5' 'KP' 'D5' 'SJ' '7P' 'RG' 'W5' '92' 'MA' '2Y' '26' 'L0' 'NA' 'TL' '2D' '8U')
	CCIndex=$(jot -r 1  0 $((${#CCCodes[@]} - 1)))
	CC=${CCCodes[CCIndex]}
	if [ $gDebug -eq 1 ]; then
		_printDebug "Generated CC value" $CC
	fi

	# Generate the EEEE value from the model data
	EEEEIndex=$(jot -r 1  0 $((${#EEEECodes[@]} - 1)))
	EEEE=${EEEECodes[EEEEIndex]}
	if [ $gDebug -eq 1 ]; then
		_printDebug "Generated EEEE value" $EEEE
	fi

	# Generate the KK value
	# TODO: Research this
	declare -a KKCodes=('1H' '1M' 'AD' '1F' 'A8' 'UE' 'JA' 'JC' '8C' 'CB' 'FB' 'A6' 'AL' 'AN' '16' 'A5' 'AH' 'AA' 'AD' 'AK' 'AN' '1W' 'AY' '1A')
	KKIndex=$(jot -r 1  0 $((${#KKCodes[@]} - 1)))
	KK=${KKCodes[KKIndex]}
	if [ $gDebug -eq 1 ]; then
		_printDebug "Generated KK value" $KK
	fi

	gMLB=$PPP$Y$WW$TTT$CC$EEEE$KK
}
#-------------------------------------------------------------------------------#

_checkSerialNumber "$@"
_generateMLB
if [ $gDebug -eq 1 ]; then
	_printDebug "\nGenerated $gProductName MLB" $gMLB
else
	echo $gMLB
fi
