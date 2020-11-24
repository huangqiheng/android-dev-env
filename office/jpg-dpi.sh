#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	check_sudo

	if ! cmd_exists exiftool; then
		check_apt exiftool 
	fi

	make_cmdline 'jpg-dpi' <<-EOF
	#!/bin/dash

	if ! test \$1; then
		find . -not -path '*/\.*' -type f -iname "*.jpg" -print0 | xargs -0 exiftool "\$1" | grep -i "X Resolution"
		exit
	fi

	if [ -f \$1 ]; then
		realfile=\$(readlink -f \$1)
		exiftool "\$realfile" | grep -i "Resolution"
		exit
	fi

	resolution="\$1"

	for input_file in \$(find . -not -path  '*/\.*' -type f -iname "*.jpg"); do
		realfile=\$(readlink -f \$input_file)
		exiftool -ResolutionUnit=inches -XResolution=\$resolution -YResolution=\$resolution \$realfile
		# exiftool -Author= -Creator= "\$realfile" -o "\${realpath}/\${realname%.*}.clean.pdf"
	done

EOF
}

main "$@"; exit $?
