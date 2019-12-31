#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	check_apt lsb-release wget apt-transport-https
	
	if ! cmd_exists riot-web; then
		check_sudo
		wget -O /usr/share/keyrings/riot-im-archive-keyring.gpg https://packages.riot.im/debian/riot-im-archive-keyring.gpg
		echo "deb [signed-by=/usr/share/keyrings/riot-im-archive-keyring.gpg] https://packages.riot.im/debian/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/riot-im.list
		apt update -y
		check_apt riot-web
	fi

	check_cmdline riot <<-EOF
	#!/bin/dash
	riot-web
EOF

	echo 'Just type cmd: riot'
}

main "$@"; exit $?
