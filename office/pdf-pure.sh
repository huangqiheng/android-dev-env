#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_sudo

	if ! cmd_exists exiftool; then
		check_apt exiftool
	fi

	make_cmdline 'pdf-pure' <<-EOF
	#!/bin/dash
	realfile=\$(readlink -f \$1)
	realpath=\$(dirname \$realfile)
	realname=\$(basename \$realfile)
	exiftool -Author= -Creator= "\$realfile" -o "\${realpath}/\${realname%.*}.clean.pdf"
EOF
}

main "$@"; exit $?
