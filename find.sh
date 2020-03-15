#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	empty_exit "$1" 'string to find'

	if [ "X$2" = 'X' ]; then
		2=$(pwd)
	fi

	cd "$2"
	find . -not -path '*/\.*' -type f -name "*.sh" -print0 | xargs -0 grep -i "$1"

	check_cmdline "findstr" <<-EOF
	#!/bin/dash
	filedir=\$(pwd)
	cd $EXEC_DIR
	sh $EXEC_SCRIPT \$1 \$filedir
EOF
}

main_entry $@
