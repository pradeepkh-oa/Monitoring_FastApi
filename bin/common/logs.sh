# -- < Log constants > --
PADDING_1=$(printf ".%.s" $(seq 1 97))
PADDING_2=$(printf ".%.s" $(seq 1 92))

BLUE='\033[0;34m'
DARKGRAY='\033[1;30m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
YELLOW='\033[1;33m'

INFO="info "
DEBUG="debug"
ERROR="error"
FATAL="fatal"
WARNING="warn "
OK="success"


# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function prints a log message at an DEBUG level
#
# Parameters:
#   in:
#     message   the message to be printed out
#
# ---------------------------------------------------------------------------------------
function log_debug()
{
    local message="$1"

    printf "${DARKGRAY}[debug]${NOCOLOR} %s %s\n" \
           "${PADDING_1:${#message}+${#DEBUG}+1}" "${message}"
}


# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function prints a log message at an INFO level
#
# Parameters:
#   in:
#     message   the message to be printed out
#
# ---------------------------------------------------------------------------------------
function log_info()
{
    local message="$1"

    printf "${BLUE}[info ]${NOCOLOR} %s %s\n" \
           "${PADDING_1:${#message}+${#INFO}+1}" "${message}"
}


# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function prints a log message at an ERROR level
#
# Parameters:
#   in:
#     message   the message to be printed out
#
# ---------------------------------------------------------------------------------------
function log_error()
{
    local message="$1"

    >&2 printf "${RED}[error]${NOCOLOR} %s %s\n" \
            "${PADDING_1:${#message}+${#ERROR}+1}" "${message}"
}


# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function prints a log message at an ERROR level
#
# Parameters:
#   in:
#     message   the message to be printed out
#
# ---------------------------------------------------------------------------------------
function log_warning()
{
    local message="$1"

    printf "${ORANGE}[warn ]${NOCOLOR} %s %s\n" \
           "${PADDING_1:${#message}+${#WARNING}+1}" "${message}"
}


# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function prints a log message at a FATAL level
#
# Parameters:
#   in:
#     message   the message to be printed out
#
# ---------------------------------------------------------------------------------------
function log_fatal()
{
    local message="$1"

    printf "${RED}[fatal]${NOCOLOR} %s %s\n" \
           "${PADDING_1:${#message}+${#FATAL}}" "${message}"
    exit 1
}


# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function print a log message with the status PASSED
#
# Parameters:
#   in:
#     message   the message to be printed out
#
# ---------------------------------------------------------------------------------------
function log_success()
{
    local message="$1"
    local status="[PASSED]"

    printf "${BLUE}[info ]${NOCOLOR} %s %s ${GREEN}%s${NOCOLOR}\n" \
           "${message}" "${PADDING_2:${#message}+${#status}+2}" "${status}"
}


# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function print a log message with the status FAILED.
#
# Parameters:
#   in:
#     message   the message to be printed out
#
# ---------------------------------------------------------------------------------------
function log_failure()
{
    local message="$1"
    local status="[FAILED]"

    printf "${RED}[error]${NOCOLOR} %s %s ${RED}%s${NOCOLOR}\n" \
           "${message}" "${PADDING_2:${#message}+${#status}+2}" "${status}"
}


# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function displays an error message and stops the script.
#
# Parameters:
#   in:
#     the message to be displayed
#
# ---------------------------------------------------------------------------------------
function die()
{
    local message="$1"
    >&2 log_error "${message}"

    exit ${FAILURE}
}
