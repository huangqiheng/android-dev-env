#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	local file_path="$1"
	if [ "X$file_path" = 'X' ]; then
		file_path="$(pwd)"
	fi

	cd "$file_path"
	find . -type d -name ".svn" | xargs rm -rf

	self_cmdline <<-EOF
	#!/bin/dash
	filedir=\$(pwd)
	cd $EXEC_DIR
	sh $EXEC_SCRIPT \$filedir
EOF
}

main_entry $@
