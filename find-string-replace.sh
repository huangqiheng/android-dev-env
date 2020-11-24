#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	empty_exit "$1" 'string to find'
	empty_exit "$2" 'string to replace'
	find . -not -path '*/\.*' -type f -name "*.sh" -print0 | xargs -0 grep -l "$1" | xargs sed -i "s/$1/$2/g"
}

main "$@"; exit $?
