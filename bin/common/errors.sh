# -- < global variables > --
declare -a g_errors=()


# ---------------------------------------------------------------------------------------
# -- Description --
#
# Use this function to append an error message to the list of erros which
# have occured during a process. This allows to get through all the errors
# and to return all of them up to a certain point.
#
# Parameters:
#   in:
#     message   the message error to be added to the list of errors
#
#   out:
#     g_errors    the list of encountered errors
#
# ---------------------------------------------------------------------------------------
function append_error()
{
    local message="$1"
    local index=$(( ${#g_errors[@]} ))

    g_errors[${index}]="${message}"
}
