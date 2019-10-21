#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	empty_exit "$1" 'string to find'
	find . -not -path '*/\.*' -type f -name "*.sh" -print0 | xargs -0 grep -i "$1"
}

main "$@"; exit $?
