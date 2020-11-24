#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	local file_path="$1"
	if [ "X$file_path" = 'X' ]; then
		file_path="$(pwd)"
	fi

	cd "$file_path"
	IFS=
	find . -type d -name '$RECYCLE.BIN' -print0 | xargs -0 rm -rf
	find . -type d -name 'System Volume Information' -print0 | xargs -0 rm -rf

	self_cmdline <<-EOF
	#!/bin/dash
	filedir=\$(pwd)
	cd $EXEC_DIR
	sh $EXEC_SCRIPT \$filedir
EOF
}

main_entry $@
