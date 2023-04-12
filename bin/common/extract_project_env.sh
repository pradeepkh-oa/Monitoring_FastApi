# ---------------------------------------------------------------------------------------
# -- Description --
#
# This function extracts the project suffix from the passed in project name.
#
# It returns a value as a side effect in a variable.
#
# out:
#   env_suffix  the value of the environment suffix
#
# ---------------------------------------------------------------------------------------
function extract_env()
{
    local project="${1:-}"
    env_suffix="${project##*-}"
}
