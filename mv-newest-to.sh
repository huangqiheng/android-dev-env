#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_sudo 

	local bin=/usr/local/bin/mvest

	cat > "$bin" <<-EOL
	#!/bin/sh

	line=\$1
	dir="\$2"

	if [ "X\$line" = 'X' ]; then
		echo 'The input line number is empty'
		exit 1
	fi

	if [ "X\$dir" = 'X' ]; then
		echo 'The input dir is empty'
		exit 1
	fi

	dir=\$(readlink -f \$dir)

	if [ ! -d \$dir ]; then
		echo "The input directory done\'t exists"
		exit 1
	fi

	ignoreSelf=false
	for file in \$(ls -1rt | tail -\$line); do
		if [ "\$PWD/\$file" = "\$dir" ]; then
			ignoreSelf=true
		else
			mv "\$PWD/\$file" \$dir
		fi
	done

	if [ "\$ignoreSelf" = 'true' ]; then
		for file in \$(ls -1rt | tail -2); do
			if [ "\$PWD/\$file" != "\$dir" ]; then
				mv "\$PWD/\$file" \$dir
			fi
		done
	fi
EOL

	chmod a+x "$bin"

	show_help_exit
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL
  mvest COUNT path_to_dir
  sample:
	mvest 3 ~/path	; move the newest 3 file to $HOME/path
EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
