#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	check_sudo
	make_cmdline nprefix <<-EOF
	matchRule="\${1:-*}"
	counter=0;

	ifsTab=\$(echo "\t")
	IFS=\$(echo "\n\r")
	for inputFile in \$(find . -maxdepth 1 -type f -name "\$matchRule" -printf "%T+\t%p\n" | sort); do
		counter=\$((\$counter + 1))
		IFS=\$ifsTab; set -- \$(echo "\$inputFile")
		baseFile=\$(basename "\$2")
		leader=\$(echo "\$baseFile" | grep -Eo '^[0-9]*-')

		if [ ! "X\$leader" = 'X' ]; then
			newFile=\$(echo "\$baseFile" | cut -c \$((\${#leader}+1))-)
			newFile="\$counter-\$newFile"
		else
			newFile="\$counter-\$baseFile"
		fi

		if [ ! "\$baseFile" = "\$newFile" ]; then
			mv "\$baseFile" "\$newFile"
			echo "\$newFile"
		fi
	done
EOF
}

main_entry $@
