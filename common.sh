## Styling stuff
STYLE_RESET="\e[0m"
STYLE_BOLD="\e[1m"
STYLE_UNDERLINED="\e[4m"

## Color stuff
COLOR_BLACK="\e[1m"
COLOR_RED="\e[1;31m"
COLOR_GREEN="\e[32m"
COLOR_DARK_YELLOW="\e[33m"
COLOR_MAGENTA="\e[1;35m"
COLOR_PURPLE="\e[35m"
COLOR_CYAN="\e[36m"
COLOR_BLUE="\e[1;34m"
COLOR_ORANGE="\e[31m"
COLOR_GREY="\e[37m"
COLOR_END="\e[0m"

#-------------------------------------------------------------------------------#
function _printError()
{
	# Initialize variables
	text="$1"

	# Print the error text and exit
	printf "${COLOR_RED}${STYLE_BOLD}ERROR: ${STYLE_RESET}$text\n"
	exit 128
}

function _printDebug()
{
	# Print debug text as bold
	printf "${STYLE_BOLD}$1: ${STYLE_RESET}$2\n"
}

# Returns the decoded location.
function _decodeLocationValue()
{
	locationValue=$1

	source data/Locations.cfg

	echo "$location"
}

# Returns the decoded year number.
function _decodeYearValue()
{
	yearValue=$1

	case $yearValue in
		C | D) let yearNumber=0;;
		F | G) let yearNumber=1;;
		H | J) let yearNumber=2;;
		K | L) let yearNumber=3;;
		M | N) let yearNumber=4;;
		P | Q) let yearNumber=5;;
		R | S) let yearNumber=6;;
		T | V) let yearNumber=7;;
		W | X) let yearNumber=8;;
		Y | Z) let yearNumber=9;;
	esac

	echo $yearNumber
}

# Returns the decoded week number.
function _decodeWeekValue()
{
	yearValue=$1
	weekValue=$2

	case $yearValue in # These manufacture year values are offset by 27 weeks
		D | G | J | L | N | Q | S | V | X | Z) let weekNumber=27;;
	esac

	case $weekValue in
		[1-9]) let weekNumber+=$2;;
		C) let weekNumber+=10;;
		D) let weekNumber+=11;;
		F) let weekNumber+=12;;
		G) let weekNumber+=13;;
		H) let weekNumber+=14;;
		K) let weekNumber+=15;;
		L) let weekNumber+=16;;
		M) let weekNumber+=17;;
		N) let weekNumber+=18;;
		P) let weekNumber+=19;;
		Q) let weekNumber+=20;;
		R) let weekNumber+=21;;
		S) let weekNumber+=22;;
		T) let weekNumber+=23;;
		U) let weekNumber+=24;;
		V) let weekNumber+=25;;
		W) let weekNumber+=26;;
		X) let weekNumber+=27;;
		Y) let weekNumber+=28;;
	esac

	echo $weekNumber
}
#-------------------------------------------------------------------------------#
