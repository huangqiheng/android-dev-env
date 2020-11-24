#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	empty_exit "$1" 'string to find'

	local filedir="$2"
	if [ "X$filedir" = 'X' ]; then
		filedir=$(pwd)
	fi

	cd "$filedir"
	find . -not -path '*/\.*' -type f -name "*.sh" -print0 | xargs -0 grep -i "$1"

	check_cmdline "findstr" <<-EOF
	#!/bin/dash
	filedir=\$(pwd)
	cd $EXEC_DIR
	sh $EXEC_SCRIPT \$1 \$filedir
EOF
}

main_entry $@
