#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	if ! cmd_exists dmg2img; then
		check_update universe
		check_apt dmg2img
	fi

	check_cmdline dmg2img <<-EOFF
	current=\$(pwd)
	cd $EXEC_DIR
	sh $EXEC_SCRIPT \"\$current/\$1\"
EOFF
}

main "$@"; exit $?
