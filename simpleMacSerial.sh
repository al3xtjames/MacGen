#!/bin/bash
#
# Simple Mac Serial Number Generator Script by theracermaster
# Thanks to MacRumors for deciphering the 12-digit serial number format (http://www.macrumors.com/2010/04/16/apple-tweaks-serial-number-format-with-new-macbook-pro/)
# Thanks to MagerValp for deciphering the CCCC codes (https://github.com/MagerValp/MacModelShelf/)
#
# After getting a value, put it in your config.plist. Make sure you have a valid MLB and SmUUID as well to get iMessage working properly.
#
# Changelog:
# Version 2.0 - Major cleanups, changes, and addtional data

# Initialize global variables

## The script version
gScriptVersion="2.0"
## Debug mode, setting to 1 will print out information about the generated serial number
gDebug=0

## The repo folder
gRepo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

## The input Mac model
gProductName="$1"
## The system serial number (SN), will be generated later
gSerialNumber=""

## The location from the serial number, will be generated later
gLocation=""

source "$gRepo/common.sh"

#-------------------------------------------------------------------------------#
function _generateSerialNumber()
{
	# Check for input of the serial number; if it doesn't exist, get the serial number from the IORegistry
	if [ -z "$gProductName" ]; then
		gProductName=$(ioreg -k product-name -d 2 | awk '/product-name/ {print $3}' | tr -d '"<>')
		if [ $gDebug -eq 1 ]; then
			_printDebug "NOTE" "No input product name found, using IORegistry value (${STYLE_BOLD}$gProductName${STYLE_RESET})"
		fi
	fi

	# Source existing model data from config
	if [[ "$gProductName" =~ "iMac" ]]; then
		source "$gRepo/data/iMac.cfg"
	elif [[ "$gProductName" =~ "MacBookAir" ]]; then
		source "$gRepo/data/MacBook Air.cfg"
	elif [[ "$gProductName" =~ "MacBookPro" ]]; then
		source "$gRepo/data/MacBook Pro.cfg"
	elif [[ "$gProductName" =~ "MacBook" ]]; then
		source "$gRepo/data/MacBook.cfg"
	elif [[ "$gProductName" =~ "Macmini" ]]; then
		source "$gRepo/data/Mac mini.cfg"
	elif [[ "$gProductName" =~ "MacPro" ]]; then
		source "$gRepo/data/Mac Pro.cfg"
	else
		_printError "Invalid model identifier!"
	fi

	# Generate the PPP value (manufacturing location)
	PPPIndex=$(jot -r 1 0 $((${#PPPCodes[@]} - 1)))
	PPP=${PPPCodes[PPPIndex]}
	if [ $gDebug -eq 1 ]; then
		location=$(_decodeLocationValue $PPP)
		_printDebug "Generated manufacturing location" "$location"
	fi

	# Generate the Y value (manufacturing year)
	YIndex=$(jot -r 1 0 $((${#YCodes[@]} - 1)))
	Y=${YCodes[YIndex]}
	if [ $gDebug -eq 1 ]; then
		year=$(_decodeYearValue $Y)
		_printDebug "Generated manufacturing year" 201$year
	fi

	# Generate the W value (manufacturing week)
	# Possible week values are 1 2 3 4 5 6 7 8 9 C D F G H K L M N P Q R T U V W X Y
	declare -a WCodes=('1' '2' '3' '4' '5' '6' '7' '8' '9' 'C' 'D' 'F' 'G' 'H' 'K' 'L' 'M' 'N' 'P' 'Q' 'R' 'T' 'U' 'V' 'W' 'X' 'Y')
	WIndex=$(jot -r 1 0 $((${#WCodes[@]} - 1)))
	W=${WCodes[WIndex]}
	if [ $gDebug -eq 1 ]; then
		week=$(_decodeWeekValue $Y $W)
		_printDebug "Generated manufacturing week" $week
	fi

	# Generate the SSS value (unique identifier)
	BASE62=($(echo {0..9} {a..z} {A..Z}))
	productionNumber=$(echo $((10000 + $RANDOM)) | cut -c 1-5)
	for i in $(bc <<< "obase=36; $productionNumber"); do
		echo ${BASE62[$(( 10#$i ))]} | tr '\n' ',' | tr -d ',' >> "/tmp/simpleMacSerial_SSS"
	done
	SSS=$(cat "/tmp/simpleMacSerial_SSS" | tr '[:lower:]' '[:upper:]')
	rm "/tmp/simpleMacSerial_SSS"
	if [ $gDebug -eq 1 ]; then
		_printDebug "Generated unique identifier" $SSS
	fi

	# Generate the CCCC value (model identifer) from the model data
	CCCCIndex=$(jot -r 1 0 $((${#CCCCCodes[@]} - 1)))
	CCCC=${CCCCCodes[CCCCIndex]}
	if [ $gDebug -eq 1 ]; then
		_printDebug "Generated model identifier" $CCCC
	fi

	gSerialNumber=$PPP$Y$W$SSS$CCCC
}
#-------------------------------------------------------------------------------#

if [ "$1" == "-h" ]; then
	echo "simpleMacSerial.sh v$gScriptVersion - Simple Mac serial number script by theracermaster"
	echo
	echo "Usage: ./simpleMacSerial.sh <product name>"
	echo "     <product name>      Target Mac product name (model ID)"
	echo "     -h                  Help (this screen)"
	echo
	echo "If no arguments are specified, system values from the IORegistry will be used."
	exit 0
fi

_generateSerialNumber "$@"
if [ $gDebug -eq 1 ]; then
	_printDebug "\nGenerated $gProductName serial number" $gSerialNumber
else
	echo $gSerialNumber
fi
