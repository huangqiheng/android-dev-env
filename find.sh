#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	empty_exit "$1" 'string to find'
	find . -not -path '*/\.*' -type f -name "*.sh" -print0 | xargs -0 grep -i "$1"
}

main_entry $@
